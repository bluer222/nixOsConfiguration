"""Run with python3 tests/nvidia-reset.py; GPU and service commands are mocked."""

import json
import os
from pathlib import Path
import subprocess
import tempfile


service = json.loads(subprocess.check_output([
    "nix", "eval", "--no-write-lock-file", "--json",
    ".#nixosConfigurations.samm-desktop.config.systemd.services.nvidia-gpu-reset",
    "--apply", "service: { inherit (service) script postStop wantedBy; }",
], cwd=Path(__file__).resolve().parents[1]))
assert service["wantedBy"] == [], "Reset must never run automatically at boot"

mocks = r'''
clients=$CLIENTS
systemctl() {
  printf 'systemctl %s\n' "$*" >> "$LOG"
  [[ "$*" != "$FAIL_COMMAND" ]]
}
fuser() {
  printf '%s\n' "$*" >> "$DEVICE_LOG"
  if [[ "$1" == -s ]]; then
    [[ "$clients" == stubborn ]]
  else
    printf 'fuser %s\n' "$2" >> "$LOG"
    if [[ "$2" == -KILL || "$clients" != stubborn ]]; then
      clients=none
    fi
  fi
}
sleep() { :; }
nvidia-smi() {
  printf 'nvidia-smi %s\n' "$*" >> "$LOG"
  return "$RESET_STATUS"
}
'''

cases = [
    ("no clients", "none", 0, "", True),
    ("graceful exit", "graceful", 0, "", True),
    ("force kill", "stubborn", 0, "", True),
    ("reset failure", "none", 1, "", True),
    ("stop failure", "none", 0, "stop nvidia-powerd.service", True),
    ("restart failure", "none", 0, "restart nvidia-powerd.service", True),
    ("no NVIDIA devices", "none", 0, "", False),
]
for name, clients, reset_status, fail_command, has_gpu in cases:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        if has_gpu:
            for node in ["nvidia0", "nvidiactl", "nvidia-caps/nvidia-cap1",
                         "dri/card0", "dri/renderD129", "dri/card1"]:
                device = root / "dev" / node
                device.parent.mkdir(parents=True, exist_ok=True)
                device.symlink_to("/dev/null")
            for node, vendor in [("card0", "0x10de"), ("renderD129", "0x10de"),
                                 ("card1", "0x8086")]:
                vendor_file = root / "sys/class/drm" / node / "device/vendor"
                vendor_file.parent.mkdir(parents=True)
                vendor_file.write_text(vendor + "\n")
        script = service["script"].replace("/dev/", f"{root}/dev/")
        script = script.replace("/sys/", f"{root}/sys/")
        env = dict(os.environ, CLIENTS=clients, RESET_STATUS=str(reset_status),
                   FAIL_COMMAND=fail_command, LOG=str(root / "log"),
                   DEVICE_LOG=str(root / "devices"))
        start = subprocess.run(["bash", "-euc", mocks + script], env=env,
                               capture_output=True, text=True)
        cleanup = subprocess.run(["bash", "-euc", mocks + service["postStop"]],
                                 env=env, capture_output=True, text=True)
        calls = (root / "log").read_text().splitlines()
        assert calls[-2:] == ["systemctl restart nvidia-powerd.service",
                              "systemctl restart lactd.service"], (name, calls)
        assert (start.returncode == 0) == (
            has_gpu and reset_status == 0 and not fail_command.startswith("stop ")
        ), (name, start.stderr)
        assert (cleanup.returncode == 0) == (not fail_command.startswith("restart ")), name
        if has_gpu and not fail_command.startswith("stop "):
            assert calls[:3] == ["systemctl stop lactd.service",
                                 "systemctl stop nvidia-powerd.service",
                                 "fuser -TERM"], (name, calls)
            assert ("fuser -KILL" in calls) == (clients == "stubborn"), (name, calls)
            assert calls[-3] == "nvidia-smi --gpu-reset", (name, calls)
            devices = (root / "devices").read_text()
            for node in ["nvidia0", "nvidia-cap1", "card0", "renderD129"]:
                assert node in devices, (name, devices)
            assert "card1" not in devices, "Intel GPU must be left alone"
        else:
            assert not any(call.startswith(("fuser", "nvidia-smi")) for call in calls), name
        print(f"PASS: {name}")
