# nvidia_uvm boot workaround

Added 2026-08-23. **Remove this when upstream fixes it** — see "How to undo".

## Symptom

`systemd-modules-load.service` blocked `sysinit.target` for ~2.4s on every boot,
which was ~45% of total boot time (`systemd-analyze critical-chain graphical.target`).

## Root cause chain

1. We use the open NVIDIA kernel module (`hardware.nvidia.open = true`).
2. Upstream `nvidia.nix` eagerly adds `nvidia_uvm` to `boot.kernelModules`
   for open-module users, because `softdep nvidia post: nvidia-uvm`
   lazy-loading is broken with the open module:
   https://github.com/NixOS/nixpkgs/issues/334180
   (see the comment above `kernelModules = lib.optionals useOpenModules [ "nvidia_uvm" ]`)
3. `modprobe nvidia_uvm` during sysinit transitively loads the whole `nvidia`
   driver synchronously.
4. On this laptop (MSI, i7-13620H + dGPU), driver RM init stalls ~2s in failing
   SBIOS ACPI calls — dmesg shows `_acpiDsmCapsInit` / NBCI
   "PlatformRequestHandler failed to get target temp / platform power mode from
   SBIOS". Firmware retry loops; not fixable from Linux.

## What we did (in `modules/nixos/hardware/gpu.nix`)

1. `environment.etc."modules-load.d/nixos.conf"` mkForce override that filters
   `nvidia_uvm` out of the generated module list (so nothing modprobes it during
   sysinit).
2. `load-nvidia-uvm.service`: oneshot that runs
   `modprobe nvidia_uvm` after `graphical.target`, off the critical path.
   The udev mknod rules fire whenever the module appears, so CUDA and
   `/dev/nvidia-uvm*` nodes behave identically.

## Verify it's still working

```sh
grep nvidia_uvm /etc/modules-load.d/nixos.conf   # should print nothing
systemctl status load-nvidia-uvm                  # inactive (dead), exit ok
```

## How to undo (when fixed upstream)

Fixed means either nixpkgs stops eager-loading `nvidia_uvm` for open modules
(334180 closed / the `kernelModules = lib.optionals useOpenModules ...` line is
gone), or the softdep path works again so inserting uvm costs <~300ms after
udev has already loaded `nvidia`.

1. Delete both blocks in `modules/nixos/hardware/gpu.nix` (the
   `environment.etc."modules-load.d/nixos.conf"` override and the
   `load-nvidia-uvm` service).
2. Rebuild and reboot once.
3. Confirm the problem is actually gone upstream:
   ```sh
   grep nvidia_uvm /etc/modules-load.d/nixos.conf   # present again now
   journalctl -b -u systemd-modules-load.service    # insert should be fast (<0.5s)
   ```
   If the stall comes back (~2s before "Inserted module 'nvidia_uvm'"),
   the firmware latency is still biting — reapply the workaround.

Related: nginx decoupling (`networking/nginx.nix`) is independent of this and
safe to keep forever.
