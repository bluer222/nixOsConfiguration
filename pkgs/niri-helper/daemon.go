package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"
)

func runDaemon() error {
	ln, err := listenSocket()
	if err != nil {
		return err
	}
	defer func() {
		_ = ln.Close()
		_ = os.Remove(socketPath())
	}()

	go serveCommands(ln)

	applyMSIBootDefaults()
	startWallpaper(defaultWallpaper())
	go startupHooks()
	go runBatteryMonitor()
	go runAudioMonitor()
	go runSuperTap()

	return runEventLoop()
}

func runEventLoop() error {
	byID := map[uint64]workspaceInfo{}

	for {
		conn, dec, err := openEventStream()
		if err != nil {
			fmt.Fprintf(os.Stderr, "event-stream: %v; retrying\n", err)
			time.Sleep(2 * time.Second)
			continue
		}

		for {
			var raw json.RawMessage
			if err := dec.Decode(&raw); err != nil {
				fmt.Fprintf(os.Stderr, "event-stream read: %v\n", err)
				_ = conn.Close()
				break
			}

			var ev map[string]json.RawMessage
			if err := json.Unmarshal(raw, &ev); err != nil {
				continue
			}
			if _, ok := ev["Ok"]; ok {
				continue
			}
			if _, ok := ev["Err"]; ok {
				fmt.Fprintf(os.Stderr, "event-stream error reply: %s\n", string(raw))
				_ = conn.Close()
				break
			}

			if payload, ok := ev["WorkspacesChanged"]; ok {
				var body struct {
					Workspaces []struct {
						ID   uint64  `json:"id"`
						Idx  uint8   `json:"idx"`
						Name *string `json:"name"`
					} `json:"workspaces"`
				}
				if err := json.Unmarshal(payload, &body); err != nil {
					continue
				}
				byID = map[uint64]workspaceInfo{}
				for _, ws := range body.Workspaces {
					name := ""
					if ws.Name != nil {
						name = *ws.Name
					}
					byID[ws.ID] = workspaceInfo{ID: ws.ID, Idx: ws.Idx, Name: name}
				}
			}

			if payload, ok := ev["WorkspaceActivated"]; ok {
				var body struct {
					ID      uint64 `json:"id"`
					Focused bool   `json:"focused"`
				}
				if err := json.Unmarshal(payload, &body); err != nil {
					continue
				}
				onWorkspaceActivated(body.ID, body.Focused, byID)
			}
		}
		time.Sleep(time.Second)
	}
}
