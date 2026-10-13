package main

import (
	"fmt"
	"strconv"
)

// Workspace addressing.
//
// Niri resolves numeric workspace references ("1", "2", ...) by POSITION,
// not by name: the pinned empty workspace above the first desk shifts every
// index by one (above=1, "1"=2, ...), and any dynamic workspace renumbers the
// rest. A live probe confirmed it: moving a window to "2" landed it on the
// desk NAMED "1" (position 2). So bare numeric strings must never be used as
// references. Instead, numbered desks are addressed by NAME through
// resolveDeskIndex, which reads the current index out of a fresh query,
// keeping every reference valid by construction.
//
// Non-numeric names ("desktop", "trash") are unambiguous and used directly.

// isRealDesk reports whether name is one of the three everyday desks.
// Anything else (desktop, trash, unnamed dynamic edges) is a utility
// workspace and never a navigation destination.
func isRealDesk(name string) bool {
	return name == "1" || name == "2" || name == "3"
}

// topWorkspaceRef is the persistent top wraparound slot ("0" in the
// user's desk scheme). It replaces empty-workspace-above-first, whose
// dynamic unnamed desk collided with real desk "1" in Noctalia's matching.
// Like "0", it is only compared/resolved by exact name, never passed to
// Niri as a positional reference.
const topWorkspaceRef = "0"

// resolveDeskIndex maps a desk NAME to a positional index reference that is
// valid right now.
func resolveDeskIndex(name string) (string, error) {
	workspaces, err := listWorkspaces()
	if err != nil {
		return "", err
	}
	for _, ws := range workspaces {
		if ws.Name == name {
			return strconv.Itoa(int(ws.Idx)), nil
		}
	}
	return "", fmt.Errorf("desk %q not found", name)
}

// resolveDeskIndexOrFalse is resolveDeskIndex adapted for wrap decisions,
// where a lookup failure just means "don't bounce".
func resolveDeskIndexOrFalse(name string) (string, bool) {
	ref, err := resolveDeskIndex(name)
	if err != nil {
		return "", false
	}
	return ref, true
}

// focusDeskByName focuses a numbered desk by NAME (Mod+E/R/F).
func focusDeskByName(name string) error {
	ref, err := resolveDeskIndex(name)
	if err != nil {
		return err
	}
	return focusWorkspaceName(ref)
}

// moveToDesk implements `helper move-to-desk <name>` (Mod+Shift+E/R/F):
// moves the focused window to the named desk and follows it.
func moveToDesk(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("move-to-desk needs a desk name")
	}
	win, err := focusedWindow()
	if err != nil {
		return err
	}
	ref, err := resolveDeskIndex(args[0])
	if err != nil {
		return err
	}
	return moveWindowToWorkspaceRef(ref, win.ID, true)
}

// gotoDesk implements `helper goto-desk <name>` (Mod+E/R/F).
func gotoDesk(args []string) error {
	if len(args) < 1 {
		return fmt.Errorf("goto-desk needs a desk name")
	}
	return focusDeskByName(args[0])
}

// wrapTarget decides where a fresh landing on (id, name) should bounce, if
// anywhere. Rule: any non-real-desk workspace that is EMPTY bounces home —
// the top slot ("0" or a dynamic above-first edge) to desk 3, everything
// else (bottom edge, desktop, trash) to desk 1. Occupied utility workspaces
// are treated as real desks and left alone, so peeking at a trash with
// pending windows is possible.
func wrapTarget(id uint64, name string) (string, bool) {
	if isRealDesk(name) {
		return "", false
	}
	workspaces, err := listWorkspaces()
	if err != nil || len(workspaces) < 2 {
		return "", false
	}
	var focused *workspace
	minIdx, maxIdx := workspaces[0].Idx, workspaces[0].Idx
	for i := range workspaces {
		ws := &workspaces[i]
		if ws.Idx < minIdx {
			minIdx = ws.Idx
		}
		if ws.Idx > maxIdx {
			maxIdx = ws.Idx
		}
		if ws.ID == id {
			focused = ws
		}
	}
	if minIdx == maxIdx || focused == nil || !focused.empty() {
		return "", false
	}
	if name == trashWorkspaceRef || name == desktopWorkspace {
		return resolveDeskIndexOrFalse("1")
	}
	if name == topWorkspaceRef {
		return resolveDeskIndexOrFalse("3")
	}
	if name != "" {
		return "", false
	}
	switch focused.Idx {
	case maxIdx:
		return resolveDeskIndexOrFalse("1")
	case minIdx:
		return resolveDeskIndexOrFalse("3")
	default:
		return "", false
	}
}
