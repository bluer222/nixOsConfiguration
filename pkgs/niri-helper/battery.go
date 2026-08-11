package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
)

var (
	stateRE = regexp.MustCompile(`state:\s+(\S+)`)
	pctRE   = regexp.MustCompile(`percentage:\s+(\d+)%`)
)

var pluggedStates = map[string]bool{
	"charging":       true,
	"pending-charge": true,
	"fully-charged":  true,
}

func writeSys(path, value string) {
	_ = os.WriteFile(path, []byte(value), 0o644)
}

func applyMSIBootDefaults() {
	writeSys("/sys/devices/platform/msi-ec/win_key", "right")
	writeSys("/sys/devices/platform/msi-ec/fn_key", "left")
	writeSys("/sys/devices/platform/msi-ec/webcam_block", "off")
	writeSys("/sys/devices/platform/msi-ec/webcam", "on")
	writeSys("/sys/devices/platform/msi-ec/cooler_boost", "off")
	writeSys("/sys/class/leds/platform::stealth/brightness", "0")
}

func applyPluggedState(plugged, doSound bool) {
	if doSound {
		if plugged {
			playSound(oxygen("power-plug.ogg"))
		} else {
			playSound(oxygen("power-unplug.ogg"))
		}
	}
	if plugged {
		writeSys("/sys/devices/platform/msi-ec/shift_mode", "comfort")
		writeSys("/sys/devices/platform/msi-ec/fan_mode", "auto")
		writeSys("/sys/devices/platform/msi-ec/super_battery", "off")
	} else {
		writeSys("/sys/devices/platform/msi-ec/shift_mode", "eco")
		writeSys("/sys/devices/platform/msi-ec/fan_mode", "silent")
		writeSys("/sys/devices/platform/msi-ec/super_battery", "on")
	}
}

func runBatteryMonitor() {
	applyMSIBootDefaults()

	var plugged *bool
	percentage := -1
	lowNotified := false

	cmd := exec.Command("upower", "--monitor-detail")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Fprintf(os.Stderr, "battery: %v\n", err)
		return
	}
	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "battery: %v\n", err)
		return
	}

	sc := bufio.NewScanner(stdout)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" {
			continue
		}
		if m := stateRE.FindStringSubmatch(line); m != nil {
			state := m[1]
			var isPlugged bool
			if pluggedStates[state] {
				isPlugged = true
			} else if state == "discharging" {
				isPlugged = false
			} else {
				continue
			}
			if plugged == nil || *plugged != isPlugged {
				// First reading after start: apply silently. Later changes: sound.
				changed := plugged != nil
				plugged = &isPlugged
				applyPluggedState(isPlugged, changed)
			}
			continue
		}
		if m := pctRE.FindStringSubmatch(line); m != nil {
			newPct, _ := strconv.Atoi(m[1])
			if percentage < 0 {
				percentage = newPct
				lowNotified = newPct < 20
				continue
			}
			if newPct == percentage {
				continue
			}
			percentage = newPct
			if percentage < 20 {
				if !lowNotified {
					lowNotified = true
					playSound(oxygen("battery-low.ogg"))
					notify("critical", "Battery low", fmt.Sprintf("%d%% remaining", percentage))
				}
			} else {
				lowNotified = false
			}
			if percentage == 100 {
				playSound(oxygen("battery-full.ogg"))
			}
		}
	}
	_ = cmd.Wait()
}
