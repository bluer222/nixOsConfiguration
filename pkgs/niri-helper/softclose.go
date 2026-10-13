package main

import (
	"fmt"
	"os"
	"sync"
	"time"
)

// Soft-close: Mod+Escape hides the focused window on a "trash" workspace and
// queues a real close 30s later. Mod+Z (undo-close) cancels the timer and
// brings the most recently hidden window back. If the app vetoes the close
// (e.g. a save-confirmation dialog), the window is put back where the dialog
// can be answered instead of rotting on trash.

const (
	trashWorkspaceRef = "trash"
	softCloseDelay    = 30 * time.Second
	closeConfirmWait  = 3 * time.Second
)

type pendingClose struct {
	windowID         uint64
	title            string
	appID            string
	origWorkspaceRef string
	timer            *time.Timer
}

var softCloses = struct {
	mu    sync.Mutex
	items []*pendingClose
}{}

func workspaceRefByID(workspaceID uint64) (string, error) {
	workspaces, err := listWorkspaces()
	if err != nil {
		return "", err
	}
	for _, ws := range workspaces {
		if ws.ID == workspaceID {
			return ws.label(), nil
		}
	}
	return "", fmt.Errorf("workspace id %d not found", workspaceID)
}

func softClose() error {
	win, err := focusedWindow()
	if err != nil {
		return err
	}

	origRef, err := workspaceRefByID(win.WorkspaceID)
	if err != nil {
		return err
	}

	// Closing a window that's already staged on trash: the user means it.
	if origRef == trashWorkspaceRef {
		return closeWindowByID(win.ID)
	}

	// Hide without following focus so the user stays on their workspace.
	// trash is a persistent named workspace so this reference always
	// resolves (moving to a nonexistent name silently does nothing).
	if err := moveWindowToWorkspaceRef(trashWorkspaceRef, win.ID, false); err != nil {
		return err
	}

	label := win.Title
	if label == "" {
		label = win.AppID
	}
	if label == "" {
		label = fmt.Sprintf("window %d", win.ID)
	}

	softCloses.mu.Lock()
	// De-dupe: drop any stale entry for the same window.
	kept := softCloses.items[:0]
	for _, p := range softCloses.items {
		if p.windowID == win.ID {
			if p.timer != nil {
				p.timer.Stop()
			}
			continue
		}
		kept = append(kept, p)
	}
	softCloses.items = kept

	entry := &pendingClose{
		windowID:         win.ID,
		title:            label,
		appID:            win.AppID,
		origWorkspaceRef: origRef,
	}
	id := win.ID
	entry.timer = time.AfterFunc(softCloseDelay, func() { expireSoftClose(id) })
	softCloses.items = append(softCloses.items, entry)
	n := len(softCloses.items)
	softCloses.mu.Unlock()

	// No "hidden" notification by request; only the restore one below.
	if n > 1 {
		fmt.Fprintf(os.Stderr, "soft-close: %d windows pending\n", n)
	}
	return nil
}

func expireSoftClose(windowID uint64) {
	softCloses.mu.Lock()
	idx := -1
	for i, p := range softCloses.items {
		if p.windowID == windowID {
			idx = i
			break
		}
	}
	if idx == -1 {
		softCloses.mu.Unlock()
		return // already restored
	}
	entry := softCloses.items[idx]
	softCloses.items = append(softCloses.items[:idx], softCloses.items[idx+1:]...)
	softCloses.mu.Unlock()

	if err := closeWindowByID(windowID); err != nil {
		fmt.Fprintf(os.Stderr, "soft-close expire %d: %v\n", windowID, err)
		return
	}
	time.Sleep(closeConfirmWait)
	if !windowAlive(windowID) {
		return // closed cleanly
	}
	// The app vetoed the close (e.g. save confirmation): put it back where
	// the dialog can be answered instead of rotting on trash.
	if err := restoreWindow(entry); err != nil {
		fmt.Fprintf(os.Stderr, "soft-close restore %d: %v\n", windowID, err)
		return
	}
	notify("normal", "Needs attention before closing", entry.title)
}

func windowAlive(id uint64) bool {
	wins, err := listWindows()
	if err != nil {
		return false
	}
	for _, w := range wins {
		if w.ID == id {
			return true
		}
	}
	return false
}

// restoreWindow moves a staged window back to its original desk and focuses
// it. Shared by undo-close and the close-veto path above.
func restoreWindow(entry *pendingClose) error {
	// Numbered desks are addressed by position, so resolve the stored NAME
	// to its current index first (see wrap.go). trash/desktop refs are
	// non-numeric and resolve directly.
	ref := entry.origWorkspaceRef
	if isRealDesk(ref) {
		var err error
		if ref, err = resolveDeskIndex(ref); err != nil {
			return err
		}
	}
	if err := moveWindowToWorkspaceRef(ref, entry.windowID, true); err != nil {
		return err
	}
	_ = focusWindowByID(entry.windowID)
	return nil
}

func undoClose() error {
	softCloses.mu.Lock()
	n := len(softCloses.items)
	if n == 0 {
		softCloses.mu.Unlock()
		notify("low", "Nothing to restore", "")
		return fmt.Errorf("nothing to restore")
	}
	entry := softCloses.items[n-1]
	softCloses.items = softCloses.items[:n-1]
	if entry.timer != nil {
		entry.timer.Stop()
	}
	softCloses.mu.Unlock()

	if err := restoreWindow(entry); err != nil {
		return err
	}
	notify("low", "Window restored", entry.title)
	return nil
}
