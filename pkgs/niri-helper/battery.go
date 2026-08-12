package main

import (
	"os"
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
}

// applyPluggedState flips MSI EC power profile for AC vs battery.
// Sound is left to the caller (noctalia hooks) so we don't double-notify.
func applyPluggedState(plugged bool) {
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

func powerPlugged() error {
	applyPluggedState(true)
	playSound(oxygen("power-plug.ogg"))
	return nil
}

func powerUnplugged() error {
	applyPluggedState(false)
	playSound(oxygen("power-unplug.ogg"))
	return nil
}
