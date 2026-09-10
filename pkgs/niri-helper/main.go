package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	cmd := os.Args[1]
	args := os.Args[2:]

	// Noctalia hooks set NOCTALIA_POWER_PROFILE in the CLI process, not the daemon.
	if cmd == "power-profile" && len(args) == 0 {
		if env := os.Getenv("NOCTALIA_POWER_PROFILE"); env != "" {
			args = []string{env}
		}
	}

	switch cmd {
	case "daemon":
		if err := runDaemon(); err != nil {
			fmt.Fprintf(os.Stderr, "niri-helper: %v\n", err)
			os.Exit(1)
		}
	case "help", "-h", "--help":
		usage()
	default:
		if err := sendToDaemon(append([]string{cmd}, args...)); err != nil {
			fmt.Fprintf(os.Stderr, "niri-helper: %v\n", err)
			os.Exit(1)
		}
	}
}

func dispatch(cmd string, args []string) error {
	switch cmd {
	case "show-desktop":
		return showDesktop()
	case "dim":
		return dimBrightness()
	case "restore":
		return restoreBrightness()
	case "wake":
		return wakeFromSleep()
	case "ocr":
		return runOCR()
	case "volume":
		return runVolume(args)
	case "power-plugged":
		return powerPlugged()
	case "power-unplugged":
		return powerUnplugged()
	case "power-profile":
		return runPowerProfile(args)
	case "kill-focused":
		return killFocused()
	case "logout":
		return runLogout(args)
	default:
		return fmt.Errorf("unknown command: %s", cmd)
	}
}

func usage() {
	fmt.Fprintf(os.Stderr, `usage: niri-helper <command> [args]

daemon:
  daemon          long-lived session service (owns all state)

commands (forwarded to the running daemon):
  show-desktop    toggle empty "desktop" workspace
  dim | restore   idle brightness helpers
  wake            post-sleep hooks
  ocr             region OCR to clipboard
  volume ...      up|down|mute|mic-mute
  power-plugged   play power-plug sound (noctalia hook)
  power-unplugged play power-unplug sound (noctalia hook)
  power-profile   apply MSI EC values for power profile (power-saver|balanced|performance)
  kill-focused    SIGKILL focused window pid
  logout [--then poweroff|reboot|hibernate]
`)
}
