package main

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"sync"
	"time"
)

var (
	wallpaperMu   sync.Mutex
	wallpaperPath string
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

	if path == wallpaperPath {
		return nil
	}

	var lastErr error
	for i := 0; i < 40; i++ {
		cmd := exec.Command("noctalia", "msg", "wallpaper-set", path)
		if out, err := cmd.CombinedOutput(); err != nil {
			lastErr = fmt.Errorf("noctalia wallpaper-set: %w (%s)", err, string(out))
			time.Sleep(250 * time.Millisecond)
			continue
		}
		wallpaperPath = path
		return nil
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("noctalia wallpaper-set failed for %s", path)
	}
	return lastErr
}
