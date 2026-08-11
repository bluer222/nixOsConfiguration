package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"syscall"
)

var (
	wallpaperMu   sync.Mutex
	wallpaperPath string
	swaybgCmd     *exec.Cmd
)

func defaultWallpaper() string {
	return filepath.Join(homeDir(), "Pictures", "Wallpapers", "workspace-1.png")
}

func startWallpaper(path string) {
	if path == "" || !fileExists(path) {
		path = defaultWallpaper()
	}
	if path == "" || !fileExists(path) {
		return
	}
	_ = setWallpaper(path)
}

func setWallpaper(path string) error {
	wallpaperMu.Lock()
	defer wallpaperMu.Unlock()

	if path == wallpaperPath && swaybgAlive() {
		return nil
	}

	stopSwaybgLocked()

	cmd := exec.Command("swaybg", "-m", "fill", "-i", path)
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Start(); err != nil {
		return err
	}
	swaybgCmd = cmd
	wallpaperPath = path

	go func(c *exec.Cmd) {
		_ = c.Wait()
	}(cmd)
	return nil
}

func swaybgAlive() bool {
	if swaybgCmd == nil || swaybgCmd.Process == nil {
		return false
	}
	return swaybgCmd.Process.Signal(syscall.Signal(0)) == nil
}

func stopSwaybgLocked() {
	if swaybgCmd == nil || swaybgCmd.Process == nil {
		swaybgCmd = nil
		return
	}
	_ = swaybgCmd.Process.Signal(os.Interrupt)
	_ = swaybgCmd.Process.Kill()
	swaybgCmd = nil
}
