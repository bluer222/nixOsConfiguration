"""Apply mixed native and timed effects, with predictable stop and restore."""

import time
import fcntl
import os
from pathlib import Path
import tempfile

import effects
import keyboard
import profiles


class Controller:
    def __init__(self, lock_path=None):
        self.profile = None
        self.codes = set()
        self.started = 0
        self.lock_path = lock_path or Path(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir())) / f"stealth-keyboard-{os.getuid()}.lock"
        self.lock = None

    def acquire(self):
        if self.lock is not None:
            return
        file = Path(self.lock_path).open("ab")
        try:
            fcntl.flock(file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            file.close()
            raise OSError("Another Stealth Keyboard effect process is active. Stop its effects first.") from exc
        self.lock = file

    def release(self):
        if self.lock is not None:
            self.lock.close()
            self.lock = None

    def native(self, profile, restoring=False, active=()):
        reactive = effects.reactive_configs(profile, restoring)
        for code in active:
            reactive.pop(code, None)
        return keyboard.apply(effects.base_frame(profile), profile["brightness"], profile["enabled"],
                              key_reactive=reactive)

    def apply(self, profile):
        profile = profiles.validate(profile)
        self.acquire()
        try:
            self.native(profile)
            self.profile = profile
            self.started = time.monotonic()
            self.codes = effects.timed_codes(profile) if profile["enabled"] and profile["brightness"] else set()
            if self.codes:
                self.tick(0)
        except OSError:
            try:
                self.stop()
            except OSError:
                self.stop(restore=False)
            raise
        if not self.codes:
            self.release()

    def tick(self, elapsed=None):
        if not self.codes:
            return False
        elapsed = time.monotonic() - self.started if elapsed is None else elapsed
        active = effects.active_codes(self.profile, elapsed)
        if active != self.codes:
            # Restore each completed key even while other keys keep animating.
            self.native(self.profile, restoring=True, active=active)
            self.codes = active
            if not active:
                self.release()
                return False
        colors = effects.render(self.profile, elapsed)
        # Only timed keys are streamed, so other keys retain native reactivity.
        keyboard.stream({code: colors[code] for code in self.codes}, self.profile["brightness"])
        return True

    def stop(self, restore=True):
        was_running = bool(self.codes)
        self.codes.clear()
        try:
            if was_running and restore and self.profile:
                self.native(self.profile, restoring=True)
        finally:
            self.release()


def run(profile):
    """Headless operation stops cleanly on Ctrl+C or SIGTERM."""
    import signal
    ctl = Controller()
    ctl.apply(profile)
    if not ctl.codes:
        return
    stop = False
    def request_stop(*_):
        nonlocal stop
        stop = True
    signal.signal(signal.SIGTERM, request_stop)
    signal.signal(signal.SIGINT, request_stop)
    try:
        while not stop:
            began = time.monotonic()
            if not ctl.tick():
                break
            time.sleep(max(0, 0.05 - (time.monotonic() - began)))
    finally:
        ctl.stop()
