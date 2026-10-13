package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
)

// Desks 1-3 are the everyday desks. "desktop" is a persistent empty workspace
// (declared in the Niri config so it always exists) used as the show-desktop
// target. Its non-numeric name keeps references unambiguous: Niri resolves
// numeric references by position, which shifts as dynamic workspaces come
// and go. See wrap.go. ("0" is the persistent top wraparound slot; "trash"
// stages delayed closes.)
const desktopWorkspace = "desktop"

type showDesktopState struct {
	mu       sync.Mutex
	active   bool
	previous string
}

var showDesk = &showDesktopState{}

// focusedWorkspaceState returns the focused workspace's stable ref and
// whether it holds no windows.
func focusedWorkspaceState() (ref string, empty bool, err error) {
	workspaces, err := listWorkspaces()
	if err != nil {
		return "", false, err
	}
	for _, ws := range workspaces {
		if ws.Focused {
			return ws.label(), ws.empty(), nil
		}
	}
	return "", false, fmt.Errorf("no focused workspace")
}

func showDesktop() error {
	showDesk.mu.Lock()
	defer showDesk.mu.Unlock()

	if showDesk.active {
		target := showDesk.previous
		if !isRealDesk(target) {
			target = "1"
		}
		if err := focusDeskByName(target); err != nil {
			return err
		}
		showDesk.active = false
		showDesk.previous = ""
		return nil
	}

	ref, empty, err := focusedWorkspaceState()
	if err != nil {
		return err
	}
	if ref == desktopWorkspace || ref == trashWorkspaceRef || ref == topWorkspaceRef || empty {
		// Nothing to hide: already on a utility desk, or the desk is empty.
		// (The empty check also keeps ambiguous positional refs from
		// unnamed edge workspaces out of previous.)
		showDesk.active = false
		showDesk.previous = ""
		return nil
	}
	showDesk.previous = ref
	showDesk.active = true
	if err := focusWorkspaceName(desktopWorkspace); err != nil {
		showDesk.active = false
		showDesk.previous = ""
		return err
	}
	return nil
}

func onWorkspaceActivated(id uint64, focused bool, byID map[uint64]workspace) {
	if !focused {
		return
	}
	info, ok := byID[id]
	if !ok {
		return
	}

	desktop := info.Name == desktopWorkspace
	showDesk.mu.Lock()
	showActive := showDesk.active
	if !desktop {
		showDesk.active = false
		showDesk.previous = ""
	}
	showDesk.mu.Unlock()

	if desktop && showActive {
		return // our own show-desktop; stay put
	}

	// Anything that isn't a real desk consults the wrap rules: an
	// unexpected desktop arrival, a trash landing, or a dynamic edge
	// workspace from swiping past either end.
	if !isRealDesk(info.Name) {
		if target, ok := wrapTarget(id, info.Name); ok {
			if err := focusWorkspaceName(target); err != nil {
				fmt.Fprintf(os.Stderr, "wrap: %v\n", err)
			}
			return
		}
		// Occupied utility workspace: a real desk for now, leave it alone
		// (and don't switch wallpapers for utility desks).
		return
	}

	changeWallpaperForWorkspace(info)
}

func changeWallpaperForWorkspace(info workspace) {
	base := filepath.Join(homeDir(), "Pictures", "Wallpapers")
	candidates := []string{
		filepath.Join(base, "workspace-"+info.label()+".png"),
		filepath.Join(base, fmt.Sprintf("workspace-%d.png", info.Idx)),
	}
	for _, c := range candidates {
		if fileExists(c) {
			if err := setWallpaper(c); err != nil {
				fmt.Fprintf(os.Stderr, "wallpaper: %v\n", err)
			}
			return
		}
	}
}
