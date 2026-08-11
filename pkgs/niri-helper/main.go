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
  kill-focused    SIGKILL focused window pid
  logout [--then poweroff|reboot|hibernate]
`)
}
