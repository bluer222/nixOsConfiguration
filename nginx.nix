{ config, pkgs, ... }:

{
#localhost or somthing
services.nginx.user = "samm";
systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/home/samm" ];
users.users."samm".homeMode="744";
#to find this config comment it off then after rebuilding run systemctl cat nginx | grep conf
#this is the default nginx config but with autoindex on the end
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
