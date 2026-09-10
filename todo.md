done:
 - graceful shutdown (niri-helper closes Wayland windows via IPC, Noctalia session menu & shell aliases call niri-helper logout)
 - attach msi ec values to set power profile rather than plugged in status (niri-helper power-profile hooks into Noctalia power profile changes, boot, and wake)
 - add a keyring (enabled gnome-keyring with PAM greetd/login integration and seahorse; unlocks automatically with blank password under LUKS)

todo:
- mailspring doesnt see the gnome wallet
 
not currently possible without custom implementation:
 - chromakey based window transparency
 - niri shake-to-enlarge cursor(added to niri but not yet in nixpkgs)
 - add three finger zoom (waiting for niri zoom IPC)
