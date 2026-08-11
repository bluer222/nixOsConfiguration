package main

import (
	"encoding/binary"
	"os"
	"path/filepath"
	"sync"
	"time"
)

const (
	evKey = 0x01

	keyLeftMeta  = 125
	keyRightMeta = 126

	inputEventSize = 24 // struct input_event on amd64
)

type superTapState struct {
	mu    sync.Mutex
	held  int
	dirty bool
}

var superTap superTapState

func runSuperTap() {
	var mu sync.Mutex
	opened := map[string]struct{}{}

	openOne := func(path string) {
		mu.Lock()
		if _, ok := opened[path]; ok {
			mu.Unlock()
			return
		}
		f, err := os.Open(path)
		if err != nil {
			mu.Unlock()
			return
		}
		opened[path] = struct{}{}
		mu.Unlock()

		go func() {
			defer func() {
				_ = f.Close()
				mu.Lock()
				delete(opened, path)
				mu.Unlock()
			}()
			readInputEvents(f)
		}()
	}

	for {
		paths, _ := filepath.Glob("/dev/input/event*")
		for _, p := range paths {
			openOne(p)
		}
		time.Sleep(2 * time.Second)
	}
}

func readInputEvents(f *os.File) {
	buf := make([]byte, inputEventSize*32)
	for {
		n, err := f.Read(buf)
		if err != nil {
			return
		}
		for off := 0; off+inputEventSize <= n; off += inputEventSize {
			typ := binary.LittleEndian.Uint16(buf[off+16:])
			if typ != evKey {
				continue
			}
			code := binary.LittleEndian.Uint16(buf[off+18:])
			value := int32(binary.LittleEndian.Uint32(buf[off+20:]))
			handleSuperTapKey(code, value)
		}
	}
}

func handleSuperTapKey(code uint16, value int32) {
	// 0=release, 1=press, 2=repeat
	if value == 2 {
		return
	}

	isMeta := code == keyLeftMeta || code == keyRightMeta

	superTap.mu.Lock()
	defer superTap.mu.Unlock()

	if isMeta {
		if value == 1 {
			if superTap.held == 0 {
				superTap.dirty = false
			}
			superTap.held++
			return
		}
		if value == 0 && superTap.held > 0 {
			superTap.held--
			if superTap.held == 0 && !superTap.dirty {
				runDetached("albert", "toggle")
			}
		}
		return
	}

	if superTap.held > 0 {
		superTap.dirty = true
	}
}
