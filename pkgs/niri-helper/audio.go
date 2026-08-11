package main

import (
	"bufio"
	"os"
	"os/exec"
	"strings"
	"time"
)

func writeLED(path string, on bool) {
	v := "0"
	if on {
		v = "1"
	}
	_ = os.WriteFile(path, []byte(v), 0o644)
}

func syncMuteLEDs() {
	out, err := runCmdOutput("pactl", "get-sink-mute", "@DEFAULT_SINK@")
	if err == nil {
		writeLED("/sys/class/leds/platform::mute/brightness", strings.Contains(out, "yes"))
	}
	out, err = runCmdOutput("pactl", "get-source-mute", "@DEFAULT_SOURCE@")
	if err == nil {
		writeLED("/sys/class/leds/platform::micmute/brightness", strings.Contains(out, "yes"))
	}
}

func listAudioDevices() map[string]struct{} {
	set := map[string]struct{}{}
	for _, kind := range []string{"sinks", "sources"} {
		out, err := runCmdOutput("pactl", "list", "short", kind)
		if err != nil {
			continue
		}
		for _, line := range strings.Split(out, "\n") {
			fields := strings.Fields(line)
			if len(fields) < 2 {
				continue
			}
			name := fields[1]
			if kind == "sources" && strings.HasSuffix(name, ".monitor") {
				continue
			}
			set[name] = struct{}{}
		}
	}
	return set
}

func runAudioMonitor() {
	for {
		known := listAudioDevices()
		syncMuteLEDs()

		cmd := exec.Command("pactl", "subscribe")
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			time.Sleep(time.Second)
			continue
		}
		if err := cmd.Start(); err != nil {
			time.Sleep(time.Second)
			continue
		}

		sc := bufio.NewScanner(stdout)
		for sc.Scan() {
			line := sc.Text()
			if strings.Contains(line, "sink") || strings.Contains(line, "source") || strings.Contains(line, "server") {
				current := listAudioDevices()
				added, removed := false, false
				for k := range current {
					if _, ok := known[k]; !ok {
						added = true
					}
				}
				for k := range known {
					if _, ok := current[k]; !ok {
						removed = true
					}
				}
				if added {
					playSound(oxygen("device-added.ogg"))
				}
				if removed {
					playSound(oxygen("device-removed.ogg"))
				}
				known = current
				syncMuteLEDs()
			}
		}
		_ = cmd.Wait()
		time.Sleep(time.Second)
	}
}
