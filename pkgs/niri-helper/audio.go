package main

import (
	"bufio"
	"os/exec"
	"regexp"
	"strings"
	"time"
)

var (
	wpctlNodeRE = regexp.MustCompile(`^\s*\*?\s*(\d+)\.\s+(.+?)\s*(?:\[|$)`)
	// Match sink/source/server only — not sink-input / source-output.
	pactlAudioRE = regexp.MustCompile(`\bon (sink|source|server)(?:\s|#|$)`)
)

func wpctlVolumeLine(node string) (string, bool) {
	out, err := runCmdOutput("wpctl", "get-volume", node)
	if err != nil {
		return "", false
	}
	return out, true
}

func wpctlMuted(node string) bool {
	out, ok := wpctlVolumeLine(node)
	return ok && mutedOut(out)
}

func mutedOut(out string) bool {
	return strings.Contains(strings.ToLower(out), "[muted]")
}

func syncMuteLEDs() {
	mute, mic := "0", "0"
	if wpctlMuted("@DEFAULT_AUDIO_SINK@") {
		mute = "1"
	}
	if wpctlMuted("@DEFAULT_AUDIO_SOURCE@") {
		mic = "1"
	}
	writeFile("/sys/class/leds/platform::mute/brightness", mute)
	writeFile("/sys/class/leds/platform::micmute/brightness", mic)
}

func listAudioDevices() map[string]struct{} {
	set := map[string]struct{}{}
	out, err := runCmdOutput("wpctl", "status")
	if err != nil {
		return set
	}

	inAudio := false
	section := ""
	for _, line := range strings.Split(out, "\n") {
		// Drop wpctl's box-drawing indent ("│", "├─", …).
		trimmed := strings.Trim(line, " \t│├└─┌┐┘┬┴┼─")
		switch {
		case trimmed == "Audio":
			inAudio = true
			section = ""
			continue
		case trimmed == "Video", trimmed == "Settings":
			inAudio = false
			section = ""
			continue
		}
		if !inAudio {
			continue
		}

		switch {
		case strings.HasPrefix(trimmed, "Sinks:"):
			section = "sink"
			continue
		case strings.HasPrefix(trimmed, "Sources:"):
			section = "source"
			continue
		case strings.HasPrefix(trimmed, "Devices:"),
			strings.HasPrefix(trimmed, "Filters:"),
			strings.HasPrefix(trimmed, "Streams:"):
			section = ""
			continue
		}
		if section == "" {
			continue
		}

		m := wpctlNodeRE.FindStringSubmatch(trimmed)
		if m == nil {
			continue
		}
		set[section+":"+m[1]+":"+strings.TrimSpace(m[2])] = struct{}{}
	}
	return set
}

func runAudioMonitor() {
	for {
		// known/lastSink/lastSource are only touched by the consumer
		// goroutine below, so no lock needed around them.
		known := listAudioDevices()
		lastSink, sinkOK := wpctlVolumeLine("@DEFAULT_AUDIO_SINK@")
		lastSource, sourceOK := wpctlVolumeLine("@DEFAULT_AUDIO_SOURCE@")
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

		dirty := make(chan struct{}, 1)
		done := make(chan struct{})

		go func() {
			for {
				select {
				case <-done:
					return
				case <-dirty:
					// Coalesce bursts of sink/source events from one keypress.
					time.Sleep(120 * time.Millisecond)
				drain:
					for {
						select {
						case <-dirty:
						default:
							break drain
						}
					}

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

					if sink, ok := wpctlVolumeLine("@DEFAULT_AUDIO_SINK@"); ok {
						if sinkOK && sink != lastSink {
							playSound(oxygen("dialog-information.ogg"))
						}
						lastSink, sinkOK = sink, true
					}
					if source, ok := wpctlVolumeLine("@DEFAULT_AUDIO_SOURCE@"); ok {
						if sourceOK && source != lastSource &&
							mutedOut(source) != mutedOut(lastSource) {
							playSound(oxygen("dialog-information.ogg"))
						}
						lastSource, sourceOK = source, true
					}
					syncMuteLEDs()
				}
			}
		}()

		sc := bufio.NewScanner(stdout)
		for sc.Scan() {
			if !pactlAudioRE.MatchString(sc.Text()) {
				continue
			}
			select {
			case dirty <- struct{}{}:
			default:
			}
		}
		close(done)
		_ = cmd.Wait()
		time.Sleep(time.Second)
	}
}
