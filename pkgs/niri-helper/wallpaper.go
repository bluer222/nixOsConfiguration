package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"time"
)

// Switch by starting the new swaybg first (stacks on top), waiting for it to
// paint, then killing the previous one — no grey flash, no leftover layers.

const wallpaperHandoff = 100 * time.Millisecond

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

	//already set
	if path == wallpaperPath {
		return nil
	}

	cmd := exec.Command("swaybg", "-m", "fill", "-i", path)
	cmd.Stdout = nil
	cmd.Stderr = nil
	if err := cmd.Start(); err != nil {
		return err
	}
	go func(c *exec.Cmd) { _ = c.Wait() }(cmd)

	old := swaybgCmd
	swaybgCmd = cmd
	wallpaperPath = path

	if old != nil && old.Process != nil {
		//close the previous wallpaper after waiting for the new one to start
		go func(c *exec.Cmd) {
			time.Sleep(wallpaperHandoff)
			_ = c.Process.Signal(os.Interrupt)
			_ = c.Process.Kill()
		}(old)
	}
	return nil
}
