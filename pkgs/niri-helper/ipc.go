package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
)

func socketPath() string {
	return filepath.Join(runtimeDir(), "niri-helper.sock")
}

func sendToDaemon(args []string) error {
	conn, err := net.Dial("unix", socketPath())
	if err != nil {
		return fmt.Errorf("daemon not running (%v)", err)
	}
	defer conn.Close()

	if _, err := fmt.Fprintln(conn, strings.Join(args, " ")); err != nil {
		return err
	}

	sc := bufio.NewScanner(conn)
	if !sc.Scan() {
		if err := sc.Err(); err != nil {
			return err
		}
		return fmt.Errorf("no response from daemon")
	}
	line := sc.Text()
	if line == "ok" {
		return nil
	}
	if strings.HasPrefix(line, "err ") {
		return fmt.Errorf("%s", strings.TrimPrefix(line, "err "))
	}
	return fmt.Errorf("bad daemon response: %s", line)
}

func serveCommands(ln net.Listener) {
	for {
		conn, err := ln.Accept()
		if err != nil {
			fmt.Fprintf(os.Stderr, "ipc accept: %v\n", err)
			return
		}
		go handleClient(conn)
	}
}

func handleClient(conn net.Conn) {
	defer conn.Close()
	sc := bufio.NewScanner(conn)
	if !sc.Scan() {
		return
	}
	fields := strings.Fields(sc.Text())
	if len(fields) == 0 {
		fmt.Fprintln(conn, "err empty command")
		return
	}
	if err := dispatch(fields[0], fields[1:]); err != nil {
		fmt.Fprintf(conn, "err %v\n", err)
		return
	}
	fmt.Fprintln(conn, "ok")
}

func listenSocket() (net.Listener, error) {
	path := socketPath()
	_ = os.Remove(path)
	ln, err := net.Listen("unix", path)
	if err != nil {
		return nil, err
	}
	if err := os.Chmod(path, 0o600); err != nil {
		_ = ln.Close()
		_ = os.Remove(path)
		return nil, err
	}
	return ln, nil
}
