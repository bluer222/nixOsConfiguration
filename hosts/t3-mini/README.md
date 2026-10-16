# T3 mini PC

A persistent NixOS disk image for an Intel/AMD mini PC with UEFI. It boots
straight into a headless T3 Code host. Projects, credentials, and conversation
history stay on its disk when your laptop sleeps or disconnects.

The image includes T3 Code, Codex, Claude Code, Git, Node.js, Python, and basic
build tools. T3 starts at boot and restarts after a crash. Automatic sleep is
disabled, and compressed RAM swap helps on smaller machines. Use Ethernet for
the first boot. No desktop, model weights, or account credentials are included.

This is a separate flake so the mini PC can rebuild without the laptop's desktop
modules or its private `nixos-secrets` input. Its initial pins match the parent
repo. Updating the parent lock does not update this flake.

## Build on the laptop

From `/etc/nixos`:

```sh
nix build path:./hosts/t3-mini#image --out-link result-t3-mini
ls -lh result-t3-mini/t3-mini.img
```

The build needs free disk space and KVM access for Nix's image builder. The
result is an uncompressed whole-disk image, not an installer ISO. Its root
partition and filesystem grow to fill the destination disk at boot.

`ssh-keys.nix` contains this laptop's dedicated public key. Its private key is
`~/.ssh/t3-mini_ed25519`, outside the repo and image. Back up that private key.
If building from another laptop, add its SSH public key before building. With
Git flake URLs, stage new config/key files so Nix includes them; the `path:`
build above also includes untracked files.

## Flash and boot

Flashing erases the entire destination disk. Check its model, serial, and size.
Do not choose the laptop's system disk. The destination must be larger than the
image; 32 GB or more is a reasonable starting point for projects and builds.

The easiest first try is a spare USB SSD or USB stick: flash it on this laptop,
plug it into the mini PC, and select it from the UEFI boot menu. This runs the
full persistent system from that drive. An SSD is better for regular use.

```sh
lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

Unmount any mounted partitions on the destination. Set `TARGET` to its actual
whole-disk path, not a `-part1` partition. Replace the placeholder:

```sh
TARGET=/dev/disk/by-id/REPLACE_WITH_THE_DESTINATION_DISK
sudo dd if=result-t3-mini/t3-mini.img of="$TARGET" bs=16M status=progress conv=fsync
sync
```

To use the internal SSD instead, connect it to the laptop with a USB adapter and
flash it the same way. Alternatively, boot a separate NixOS installer USB on the
mini PC, make the image available there on another drive, and use the same
`lsblk`/`dd` procedure to write its internal SSD. Shut down the installer before
booting that SSD. Never overwrite the drive running your current system.

In firmware, enable UEFI boot and disable Secure Boot for this unsigned image.
If available, enable "power on after AC loss" for unattended recovery. Connect
Ethernet, then boot. SSH host keys are generated separately on each first boot.
Do not leave two cloned images attached: their filesystem labels/UUIDs match.

## Connect from the laptop

```sh
ssh -i ~/.ssh/t3-mini_ed25519 -o IdentitiesOnly=yes samm@t3-mini.local
```

If `.local` resolution fails, find `t3-mini` in your router's DHCP client list
and use its IP. A DHCP reservation makes the address stable.

SSH accepts keys only; root SSH and password login are disabled. The `samm`
account has passwordless sudo for administration, so anyone with its private
SSH key or an unrestricted agent session can administer the machine. Keep this
host dedicated to trusted tasks. T3 listens only on `127.0.0.1:3773`; the firewall
allows SSH and local mDNS discovery, not public access to T3.

Check the automatically started service:

```sh
sudo systemctl status t3code
curl -I http://127.0.0.1:3773/
```

## One-time account setup

Run these **as `samm` on the mini PC**, without sudo:

```sh
t3 connect link --headless
```

Open the printed URL on the laptop and approve the code with your T3 account.
The image already manages the service through NixOS; do not run `t3 service
install`. After linking, restart the server to activate the connection:

```sh
sudo systemctl restart t3code
```

Sign in to at least one provider, also as `samm`:

```sh
codex login --device-auth
# Or, if using Claude:
claude auth login
```

Follow the printed browser instructions on the laptop. Codex device login may
need enabling in your ChatGPT account settings. Then enable your provider for
this environment in T3's Settings → Providers. Account access is a one-time
interactive step; it cannot be baked into a reusable image safely.

Sign into the same T3 Connect account on the laptop or phone and select the mini
PC environment. Connection changes do not move existing laptop threads. Start
a new thread on the mini PC.

For SSH-only access without T3 Connect, forward the already-running server:

```sh
ssh -i ~/.ssh/t3-mini_ed25519 -o IdentitiesOnly=yes \
  -L 3774:127.0.0.1:3773 samm@t3-mini.local
```

In that SSH session run `t3 pair`, and use its pairing URL on the laptop with
the server address changed to `http://127.0.0.1:3774`, preserving the pairing
token. The SSH tunnel must remain open while controlling the host this way.
The host's tasks continue after the tunnel closes.

## Put projects on the host

Clone repositories on the mini PC, then select their paths in T3:

```sh
mkdir -p ~/projects
cd ~/projects
git clone YOUR_REPOSITORY_URL
```

Set up repository authentication separately if it is private. Each checkout is
independent: commit/push on one machine and pull on the other to move changes.
Project-specific tools can go in that project's Nix development shell. Keeping
T3 running does not automatically resume an interrupted task after a power loss.

To verify the setup, start a task on this environment, close the laptop, and
check its progress later from your phone or by reopening the laptop.

## Maintain the host

The editable flake is already installed at `/etc/nixos` on the mini PC. To change
the configuration or update pinned software, SSH in and run:

```sh
cd /etc/nixos
sudo nano configuration.nix
sudo nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#t3-mini
```

Wait for tasks to finish before updating: changing the service can restart it.
Use Nix to update T3, not `t3 update`. To roll back the previous system generation:

```sh
sudo nixos-rebuild switch --rollback
```

Useful diagnostics:

```sh
sudo journalctl -u t3code -n 100 --no-pager
t3 connect status
codex login status
df -h
free -h
```

Back up `/home/samm`, including hidden directories. It contains projects,
provider credentials, and T3's `~/.t3` state. Stop T3 before making a plain file
copy of its databases. Reflashing erases this state; ordinary NixOS rebuilds
preserve it. There is no disk encryption in this image.

Upstream references: [remote access](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md),
[provider setup](https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md#providers),
and [background services](https://github.com/pingdotgg/t3code/blob/main/docs/user/background-service.md).
