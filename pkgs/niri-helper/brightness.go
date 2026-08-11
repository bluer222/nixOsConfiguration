package main

import (
	"fmt"
	"path/filepath"
	"strconv"
	"sync"
)

var (
	brightMu        sync.Mutex
	savedBrightness *int // nil = not dimmed
)

func backlightDir() string {
	return "/sys/class/backlight/intel_backlight"
}

func currentBrightnessPercent() (int, error) {
	curS, err := readFileTrim(filepath.Join(backlightDir(), "brightness"))
	if err != nil {
		return 0, err
	}
	maxS, err := readFileTrim(filepath.Join(backlightDir(), "max_brightness"))
	if err != nil {
		return 0, err
	}
	cur := mustAtoi(curS)
	max := mustAtoi(maxS)
	if max == 0 {
		return 0, fmt.Errorf("max brightness is 0")
	}
	return cur * 100 / max, nil
}

func dimBrightness() error {
	brightMu.Lock()
	defer brightMu.Unlock()

	if savedBrightness != nil {
		return nil
	}
	pct, err := currentBrightnessPercent()
	if err != nil {
		return err
	}
	savedBrightness = &pct
	return runCmd("lightctl", "-d", "set", "10")
}

func restoreBrightness() error {
	brightMu.Lock()
	defer brightMu.Unlock()

	if savedBrightness != nil {
		pct := *savedBrightness
		savedBrightness = nil
		return runCmd("lightctl", "-d", "set", strconv.Itoa(pct))
	}
	return runCmd("lightctl", "-d", "set", "80")
}
