{ config, pkgs, lib, ... }:

{
  services.nginx.user = "samm";
  systemd.services.nginx.serviceConfig.ProtectHome = "read-only";
  systemd.services.nginx.serviceConfig.ReadOnlyPaths = [ "/home/samm" ];
  users.users."samm".homeMode = "744";

  # Don't let nginx gate multi-user/graphical.target; nothing needs it early.
  # It still starts during boot, just off the critical chain.
  systemd.services.nginx.wantedBy = lib.mkForce [ "graphical.target" ];

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."localhost" = {
      root = "/home/samm";
      locations = {
        # Directory listings get the themed header/CSS. `index` points at a
        # name that will never exist, so autoindex always wins and a folder's
        # index.html is not served automatically.
        "/" = {
          extraConfig = "
            index .nginx-no-index;
            autoindex on;
            autoindex_exact_size off;
            add_before_body /.config/nginx/header.html;";
        };
        # Direct requests for real HTML files are served untouched.
        "~* \\.html?$" = { };
      };
    };
  };
}
