package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

var logoutKeepExact = map[string]bool{
	"niri":                 true,
	"systemd":              true,
	"dbus-daemon":          true,
	"dbus-broker":          true,
	"dbus-broker-launcher": true,
	"pipewire":             true,
	"pipewire-pulse":       true,
	"wireplumber":          true,
	"niri-helper":          true,
	"noctalia":             true,
	"gnome-keyring-daemon": true,
	"dconf-service":        true,
}

func logoutKeepPattern(comm, cmdline string) bool {
	if strings.Contains(comm, "xdg-desktop-portal") || strings.Contains(cmdline, "xdg-desktop-portal") {
		return true
	}
	if strings.Contains(cmdline, "niri-session") {
		return true
	}
	return false
}

type procInfo struct {
	PID  int
	Comm string
}

func listKillCandidates() []procInfo {
	uid := os.Getuid()
	self := os.Getpid()
	entries, err := os.ReadDir("/proc")
	if err != nil {
		return nil
	}
	var out []procInfo
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		pid, err := strconv.Atoi(e.Name())
		if err != nil {
			continue
		}
		if pid == self || pid == 1 {
			continue
		}
		status, err := readFileTrim(filepath.Join("/proc", e.Name(), "status"))
		if err != nil {
			continue
		}
		procUID := -1
		comm := ""
		for _, line := range strings.Split(status, "\n") {
			if strings.HasPrefix(line, "Uid:") {
				fields := strings.Fields(line)
				if len(fields) >= 2 {
					procUID = mustAtoi(fields[1])
				}
			}
			if strings.HasPrefix(line, "Name:") {
				comm = strings.TrimSpace(strings.TrimPrefix(line, "Name:"))
			}
		}
		if procUID != uid {
			continue
		}
		cmdlineB, _ := os.ReadFile(filepath.Join("/proc", e.Name(), "cmdline"))
		cmdline := strings.ReplaceAll(string(cmdlineB), "\x00", " ")
		if logoutKeepExact[comm] || logoutKeepPattern(comm, cmdline) {
			continue
		}
		out = append(out, procInfo{PID: pid, Comm: comm})
	}
	return out
}

func signalAll(procs []procInfo, sig syscall.Signal) {
	for _, p := range procs {
		_ = syscall.Kill(p.PID, sig)
	}
}

func stillAlive(procs []procInfo) []procInfo {
	var live []procInfo
	for _, p := range procs {
		if err := syscall.Kill(p.PID, 0); err == nil {
			live = append(live, p)
		}
	}
	return live
}

func waitGone(procs []procInfo, timeout time.Duration) []procInfo {
	deadline := time.Now().Add(timeout)
	live := procs
	for time.Now().Before(deadline) {
		live = stillAlive(live)
		if len(live) == 0 {
			return nil
		}
		time.Sleep(200 * time.Millisecond)
	}
	return stillAlive(live)
}

func notifyActions(summary, body string, actions []string) string {
	args := []string{"--wait", "-a", "niri-helper", "-u", "critical", summary}
	if body != "" {
		args = append(args, body)
	}
	for i := 0; i+1 < len(actions); i += 2 {
		args = append(args, "--action="+actions[i]+"="+actions[i+1])
	}
	out, _ := exec.Command("notify-send", args...).Output()
	return strings.TrimSpace(string(out))
}

func closeAllWindows() {
	wins, err := listWindows()
	if err != nil {
		return
	}
	for _, w := range wins {
		_ = closeWindowByID(w.ID)
	}
}

func runLogout(args []string) error {
	then := ""
	for i := 0; i < len(args); i++ {
		if args[i] == "--then" && i+1 < len(args) {
			then = args[i+1]
			i++
		}
	}

	// 1. First, request all Wayland client windows to close cleanly.
	// This triggers applications' native quit handlers (prompting to save, flushing state).
	closeAllWindows()

	// Wait up to 2 seconds for windows to close gracefully before checking processes
	time.Sleep(2 * time.Second)

	procs := listKillCandidates()
	if len(procs) > 0 {
		signalAll(procs, syscall.SIGTERM)
		leftover := waitGone(procs, 10*time.Second)

		if len(leftover) > 0 {
			names := make([]string, 0, len(leftover))
			for _, p := range leftover {
				names = append(names, p.Comm)
			}
			// A failed/empty prompt counts as "don't kill".
			if action := notifyActions(
				"Apps still running",
				joinNames(names, 8),
				[]string{"kill", "Kill remaining", "cancel", "Cancel"},
			); action != "kill" {
				notify("low", "Logout cancelled", "")
				return nil
			}
			signalAll(leftover, syscall.SIGKILL)
			_ = waitGone(leftover, 2*time.Second)
		}
	}

	switch then {
	case "poweroff":
		return runCmd("systemctl", "poweroff")
	case "reboot":
		return runCmd("systemctl", "reboot")
	case "hibernate":
		return runCmd("systemctl", "hibernate")
	case "":
		return quitNiri()
	default:
		return fmt.Errorf("unknown --then %q", then)
	}
}
