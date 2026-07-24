{ config, pkgs, ... }:

{
  services.nginx.user = "samm";
  systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
  systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/home/samm" ];
  users.users."samm".homeMode = "744";

  #file browser and styling
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
