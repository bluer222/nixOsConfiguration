package main

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"sync"
)

const desktopWorkspace = "desktop"

type showDesktopState struct {
	mu       sync.Mutex
	active   bool
	previous string
}

var showDesk = &showDesktopState{}

func showDesktop() error {
	showDesk.mu.Lock()
	defer showDesk.mu.Unlock()

	if showDesk.active {
		target := showDesk.previous
		if target == "" {
			target = "1"
		}
		showDesk.active = false
		showDesk.previous = ""
		if err := focusWorkspaceName(target); err != nil {
			return err
		}
		//notify("low", "Windows restored", "")
		return nil
	}

	prev, err := focusedWorkspaceRef()
	if err != nil {
		return err
	}
	showDesk.previous = prev
	showDesk.active = true
	if err := focusWorkspaceName(desktopWorkspace); err != nil {
		showDesk.active = false
		showDesk.previous = ""
		return err
	}
	//notify("low", "Showing desktop", "")
	return nil
}

func focusedWorkspaceRef() (string, error) {
	raw, err := niriMsgJSON("workspaces")
	if err != nil {
		return "", err
	}
	var workspaces []struct {
		ID      uint64  `json:"id"`
		Idx     uint8   `json:"idx"`
		Name    *string `json:"name"`
		Focused bool    `json:"is_focused"`
	}
	if err := json.Unmarshal(raw, &workspaces); err != nil {
		return "", err
	}
	for _, ws := range workspaces {
		if ws.Focused {
			if ws.Name != nil && *ws.Name != "" {
				return *ws.Name, nil
			}
			return fmt.Sprintf("%d", ws.Idx), nil
		}
	}
	return "", fmt.Errorf("no focused workspace")
}

func onWorkspaceActivated(id uint64, focused bool, byID map[uint64]workspaceInfo) {
	if !focused {
		return
	}
	info, ok := byID[id]
	if !ok {
		return
	}

	showDesk.mu.Lock()
	if info.Name != desktopWorkspace {
		showDesk.active = false
		showDesk.previous = ""
	}
	showDesk.mu.Unlock()

	if info.Name == desktopWorkspace {
		return
	}

	changeWallpaperForWorkspace(info)
}

type workspaceInfo struct {
	ID   uint64
	Idx  uint8
	Name string
}

func changeWallpaperForWorkspace(info workspaceInfo) {
	label := info.Name
	if label == "" {
		label = fmt.Sprintf("%d", info.Idx)
	}
	base := filepath.Join(homeDir(), "Pictures", "Wallpapers")
	candidates := []string{
		filepath.Join(base, "workspace-"+label+".png"),
		filepath.Join(base, fmt.Sprintf("workspace-%d.png", info.Idx)),
	}
	for _, c := range candidates {
		if fileExists(c) {
			_ = setWallpaper(c)
			return
		}
	}
}
