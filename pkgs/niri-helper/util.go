package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	h, _ := os.UserHomeDir()
	return h
}

func runtimeDir() string {
	if d := os.Getenv("XDG_RUNTIME_DIR"); d != "" {
		return d
	}
	return filepath.Join("/run/user", strconv.Itoa(os.Getuid()))
}

func readFileTrim(path string) (string, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(b)), nil
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func runCmd(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func runCmdOutput(name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	out, err := cmd.Output()
	return strings.TrimSpace(string(out)), err
}

func runDetached(name string, args ...string) {
	cmd := exec.Command(name, args...)
	_ = cmd.Start()
}

func playSound(path string) {
	if path == "" || !fileExists(path) {
		return
	}
	runDetached("pw-play", path)
}

func notify(urgency, summary, body string) {
	args := []string{"-a", "niri-helper", "-u", urgency, summary}
	if body != "" {
		args = append(args, body)
	}
	runDetached("notify-send", args...)
}

func oxygen(name string) string {
	// Prefer common Nix store layout via PATH-resolved oxygen-sounds if set.
	if base := os.Getenv("NIRI_HELPER_OXYGEN"); base != "" {
		return filepath.Join(base, name)
	}
	candidates := []string{
		"/run/current-system/sw/share/sounds/oxygen/stereo/" + name,
		filepath.Join(homeDir(), ".nix-profile/share/sounds/oxygen/stereo/"+name),
	}
	for _, c := range candidates {
		if fileExists(c) {
			return c
		}
	}
	return ""
}

func mustAtoi(s string) int {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return n
}

func joinNames(names []string, limit int) string {
	if len(names) == 0 {
		return ""
	}
	if len(names) > limit {
		return fmt.Sprintf("%s … (+%d more)", strings.Join(names[:limit], ", "), len(names)-limit)
	}
	return strings.Join(names, ", ")
}
