{ config, inputs, pkgs, ... }:

let
  t3code = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code;
in
{
  systemd.user.services.t3code = {
    Unit.Description = "T3 Code server";
    Service = {
      ExecStart = "${t3code}/bin/t3 serve --host 127.0.0.1 --port 3773";
      WorkingDirectory = config.home.homeDirectory;
      Environment = [
        "PATH=${config.home.homeDirectory}/.local/bin:${config.home.profileDirectory}/bin:/run/wrappers/bin:/run/current-system/sw/bin"
      ];
      Restart = "on-failure";
      RestartSec = 5;
      KillMode = "mixed";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
