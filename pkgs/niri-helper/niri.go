package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"time"
)

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

func niriRequest(req any) (json.RawMessage, error) {
	path, err := niriSocketPath()
	if err != nil {
		return nil, err
	}
	conn, err := net.Dial("unix", path)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	enc := json.NewEncoder(conn)
	if err := enc.Encode(req); err != nil {
		return nil, err
	}
	_ = conn.(*net.UnixConn).CloseWrite()

	dec := json.NewDecoder(bufio.NewReader(conn))
	var reply struct {
		Ok  json.RawMessage `json:"Ok"`
		Err *string         `json:"Err"`
	}
	if err := dec.Decode(&reply); err != nil {
		return nil, err
	}
	if reply.Err != nil {
		return nil, fmt.Errorf("niri: %s", *reply.Err)
	}
	return reply.Ok, nil
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
