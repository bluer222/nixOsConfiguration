{ config, pkgs, ... }:

{
  # Zsh shell configuration
  users.users.samm.shell = pkgs.zsh;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions = {
      enable = true;
      async = true;
    };
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
    };
    syntaxHighlighting.enable = true;

    shellAliases = {
      srun = "run0";
      rebs = "srun nixos-rebuild switch --flake '/etc/nixos#samm-desktop' --log-format internal-json -v  |& nom --json";
      rebb = "srun nixos-rebuild boot --flake '/etc/nixos#samm-desktop' --log-format internal-json -v  |& nom --json";
      vr = ''
        if systemctl --user is-active --quiet wivrn; then
          echo "🔴 Stopping WiVRn..."
          systemctl --user stop wivrn
          echo "✅ WiVRn stopped"
        else
          echo "🟢 Starting WiVRn..."
          systemctl --user start wivrn
          echo "✅ WiVRn started - Ready for VR streaming!"
        fi
      '';
    };

    histSize = 10000;
  };
}
