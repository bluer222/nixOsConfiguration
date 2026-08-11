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
	dir := filepath.Join(homeDir(), "Pictures", "Screenshots")
	_ = os.MkdirAll(dir, 0o755)
	tmp := filepath.Join(runtimeDir(), "niri-helper-ocr.png")
	_ = os.Remove(tmp)

	geom, err := runCmdOutput("slurp")
	if err != nil {
		return err
	}
	if err := runCmd("grim", "-g", geom, tmp); err != nil {
		return err
	}

	text, err := runCmdOutput("tesseract", tmp, "stdout")
	_ = os.Remove(tmp)
	if err != nil {
		return err
	}
	text = strings.TrimSpace(text)
	if text == "" {
		notify("normal", "OCR", "No text found")
		return nil
	}
	cmd := exec.Command("wl-copy")
	cmd.Stdin = strings.NewReader(text)
	if err := cmd.Run(); err != nil {
		return err
	}
	preview := text
	if len(preview) > 120 {
		preview = preview[:120] + "…"
	}
	notify("low", "OCR", preview)
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
		return runCmd("volumectl", "-d", "up")
	case "down":
		return runCmd("volumectl", "-d", "down")
	case "mute":
		return runCmd("volumectl", "-d", "toggle-mute")
	case "mic-mute":
		return runCmd("volumectl", "-d", "-m", "toggle-mute")
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
