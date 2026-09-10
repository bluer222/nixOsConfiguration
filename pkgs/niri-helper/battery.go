package main

import (
	"os"
	"strings"
)

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
	applyActivePowerProfile()
}

// applyPowerProfile sets MSI EC values based on the power profile.
func applyPowerProfile(profile string) {
	profile = strings.TrimSpace(strings.ToLower(profile))
	switch profile {
	case "performance":
		writeSys("/sys/devices/platform/msi-ec/shift_mode", "turbo")
		writeSys("/sys/devices/platform/msi-ec/fan_mode", "auto")
		writeSys("/sys/devices/platform/msi-ec/super_battery", "off")
	case "balanced":
		writeSys("/sys/devices/platform/msi-ec/shift_mode", "comfort")
		writeSys("/sys/devices/platform/msi-ec/fan_mode", "auto")
		writeSys("/sys/devices/platform/msi-ec/super_battery", "off")
	case "power-saver", "powersave", "power_saver":
		writeSys("/sys/devices/platform/msi-ec/shift_mode", "eco")
		writeSys("/sys/devices/platform/msi-ec/fan_mode", "silent")
		writeSys("/sys/devices/platform/msi-ec/super_battery", "on")
	default:
		// Default to balanced if unrecognized
		writeSys("/sys/devices/platform/msi-ec/shift_mode", "comfort")
		writeSys("/sys/devices/platform/msi-ec/fan_mode", "auto")
		writeSys("/sys/devices/platform/msi-ec/super_battery", "off")
	}
}

// queryActivePowerProfile queries the current active profile from D-Bus via busctl.
func queryActivePowerProfile() string {
	out, err := runCmdOutput(
		"busctl", "get-property",
		"org.freedesktop.UPower.PowerProfiles",
		"/org/freedesktop/UPower/PowerProfiles",
		"org.freedesktop.UPower.PowerProfiles",
		"ActiveProfile",
	)
	if err != nil {
		return "balanced"
	}
	parts := strings.Fields(out)
	if len(parts) >= 2 {
		return strings.Trim(parts[1], "\"")
	}
	return strings.Trim(strings.TrimSpace(out), "\"")
}

func applyActivePowerProfile() {
	applyPowerProfile(queryActivePowerProfile())
}

func runPowerProfile(args []string) error {
	profile := ""
	if len(args) > 0 && args[0] != "" {
		profile = args[0]
	} else if env := os.Getenv("NOCTALIA_POWER_PROFILE"); env != "" {
		profile = env
	} else {
		profile = queryActivePowerProfile()
	}
	applyPowerProfile(profile)
	return nil
}

func powerPlugged() error {
	playSound(oxygen("power-plug.ogg"))
	return nil
}

func powerUnplugged() error {
	playSound(oxygen("power-unplug.ogg"))
	return nil
}
