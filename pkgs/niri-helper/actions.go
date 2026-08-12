package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

func wakeFromSleep() error {
	time.Sleep(3000 * time.Millisecond)
	reconnectBluetooth()
	//add brightness restore
	return nil
}

func reconnectBluetooth() {
	out, err := runCmdOutput("bluetoothctl", "devices", "Paired")
	if err != nil {
		return
	}
	for _, line := range strings.Split(out, "\n") {
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}
		mac := fields[1]
		cmd := exec.Command("timeout", "3s", "bluetoothctl", "connect", mac)
		_ = cmd.Run()
	}
}

func runOCR() error {
	flag := filepath.Join(runtimeDir(), "noctalia-ocr-request")
	if err := os.WriteFile(flag, []byte("1"), 0o600); err != nil {
		return err
	}
	if err := runCmd("noctalia", "msg", "screenshot-region"); err != nil {
		_ = os.Remove(flag)
		return err
	}
	return nil
}

func killFocused() error {
	raw, err := niriMsgJSON("focused-window")
	if err != nil {
		return err
	}
	var win struct {
		PID *int `json:"pid"`
	}
	if err := json.Unmarshal(raw, &win); err != nil {
		return err
	}
	if win.PID == nil || *win.PID <= 1 {
		return fmt.Errorf("no focused window pid")
	}
	return syscall.Kill(*win.PID, syscall.SIGKILL)
}

func runVolume(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("volume needs up|down|mute|mic-mute")
	}
	playSound(oxygen("dialog-information.ogg"))
	switch args[0] {
	case "up":
		return runCmd("noctalia", "msg", "volume-up")
	case "down":
		return runCmd("noctalia", "msg", "volume-down")
	case "mute":
		return runCmd("noctalia", "msg", "volume-mute")
	case "mic-mute":
		return runCmd("noctalia", "msg", "mic-mute")
	default:
		return fmt.Errorf("unknown volume action %q", args[0])
	}
}

func startupHooks() {
	if p := os.Getenv("NIRI_HELPER_KWALLET_INIT"); p != "" && fileExists(p) {
		runDetached(p)
	}
	_ = wakeFromSleep()
}
