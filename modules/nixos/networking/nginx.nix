{ config, pkgs, lib, ... }:

{
  services.nginx.user = "samm";
  systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
  systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/home/samm" ];
  users.users."samm".homeMode = "744";

  # Don't let nginx gate multi-user/graphical.target; nothing needs it early.
  # It still starts during boot, just off the critical chain.
  systemd.services.nginx.wantedBy = lib.mkForce [ "graphical.target" ];

  #file browser and styling
  #can we make it only style the autoindex file browser and not html files?
  services.nginx.appendHttpConfig = "
  autoindex on;
  add_before_body /.config/nginx/header.html;
  autoindex_exact_size off;";
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."localhost" = {
      root = "/home/samm";
    };
  };
}
