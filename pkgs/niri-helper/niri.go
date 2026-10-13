package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

// Shared niri model: every workspace/window lookup parses through here, so
// there is exactly one struct and one query per endpoint.

type workspace struct {
	ID             uint64  `json:"id"`
	Idx            uint8   `json:"idx"`
	Name           string  `json:"name"`
	Focused        bool    `json:"is_focused"`
	ActiveWindowID *uint64 `json:"active_window_id"`
}

// label is the stable display name, falling back to the position.
// (A JSON null name unmarshals to "", so no pointer dance needed.)
func (w workspace) label() string {
	if w.Name != "" {
		return w.Name
	}
	return strconv.Itoa(int(w.Idx))
}

func (w workspace) empty() bool { return w.ActiveWindowID == nil }

func listWorkspaces() ([]workspace, error) {
	raw, err := niriMsgJSON("workspaces")
	if err != nil {
		return nil, err
	}
	var out []workspace
	if err := json.Unmarshal(raw, &out); err != nil {
		return nil, err
	}
	return out, nil
}

type window struct {
	ID          uint64 `json:"id"`
	Title       string `json:"title"`
	AppID       string `json:"app_id"`
	PID         *int   `json:"pid"`
	WorkspaceID uint64 `json:"workspace_id"`
	Focused     bool   `json:"is_focused"`
}

func listWindows() ([]window, error) {
	raw, err := niriMsgJSON("windows")
	if err != nil {
		return nil, err
	}
	var out []window
	if err := json.Unmarshal(raw, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func focusedWindow() (window, error) {
	raw, err := niriMsgJSON("focused-window")
	if err != nil {
		return window{}, err
	}
	var w window
	if err := json.Unmarshal(raw, &w); err != nil {
		return window{}, err
	}
	if w.ID == 0 {
		return window{}, fmt.Errorf("no focused window")
	}
	return w, nil
}

func niriSocketPath() (string, error) {
	if p := os.Getenv("NIRI_SOCKET"); p != "" {
		if _, err := os.Stat(p); err == nil {
			return p, nil
		}
	}
	matches, err := filepath.Glob(filepath.Join(runtimeDir(), "niri.wayland-*.sock"))
	if err != nil {
		return "", err
	}
	best := ""
	var bestMod time.Time
	for _, p := range matches {
		st, err := os.Stat(p)
		if err != nil {
			continue
		}
		if best == "" || st.ModTime().After(bestMod) {
			best = p
			bestMod = st.ModTime()
		}
	}
	if best == "" {
		return "", fmt.Errorf("niri IPC socket not found")
	}
	return best, nil
}

func niriMsg(args ...string) error {
	full := append([]string{"msg"}, args...)
	return runCmd("niri", full...)
}

func niriMsgJSON(args ...string) (json.RawMessage, error) {
	full := append([]string{"msg", "--json"}, args...)
	out, err := runCmdOutput("niri", full...)
	if err != nil {
		return nil, err
	}
	return json.RawMessage(out), nil
}

func focusWorkspaceName(name string) error {
	return niriMsg("action", "focus-workspace", name)
}

func focusWindowByID(id uint64) error {
	return niriMsg("action", "focus-window", "--id", strconv.FormatUint(id, 10))
}

func closeWindowByID(id uint64) error {
	return niriMsg("action", "close-window", "--id", strconv.FormatUint(id, 10))
}

func moveWindowToWorkspaceRef(ref string, windowID uint64, followFocus bool) error {
	focus := "false"
	if followFocus {
		focus = "true"
	}
	return niriMsg("action", "move-window-to-workspace",
		"--window-id", strconv.FormatUint(windowID, 10),
		"--focus", focus, ref)
}

func quitNiri() error {
	return niriMsg("action", "quit", "--skip-confirmation")
}

// EventStreamConn opens a dedicated connection for continuous events.
func openEventStream() (net.Conn, *json.Decoder, error) {
	path, err := niriSocketPath()
	if err != nil {
		return nil, nil, err
	}
	conn, err := net.Dial("unix", path)
	if err != nil {
		return nil, nil, err
	}
	if err := json.NewEncoder(conn).Encode("EventStream"); err != nil {
		conn.Close()
		return nil, nil, err
	}
	return conn, json.NewDecoder(bufio.NewReader(conn)), nil
}
