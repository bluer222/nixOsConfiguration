{ config, pkgs, ... }:

{
  xdg.configFile."wleave/layout.json".text = ''
    {
      "buttons": [
        {
          "label": "lock",
          "action": "hyprlock",
          "text": "Lock",
          "keybind": "l",
          "icon": "${pkgs.wleave}/share/wleave/icons/lock.svg"
        },
        {
          "label": "hibernate",
          "action": "hyprshutdown --post-cmd 'systemctl hibernate'",
          "text": "Hibernate",
          "keybind": "h",
          "icon": "${pkgs.wleave}/share/wleave/icons/hibernate.svg"
        },
        {
          "label": "logout",
          "action": "hyprshutdown --post-cmd '${pkgs.uwsm}/bin/uwsm stop'",
          "text": "Logout",
          "keybind": "e",
          "icon": "${pkgs.wleave}/share/wleave/icons/logout.svg"
        },
        {
          "label": "shutdown",
          "action": "hyprshutdown --post-cmd 'systemctl poweroff'",
          "text": "Shutdown",
          "keybind": "s",
          "icon": "${pkgs.wleave}/share/wleave/icons/shutdown.svg"
        },
        {
          "label": "suspend",
          "action": "hyprshutdown --post-cmd 'systemctl suspend'",
          "text": "Suspend",
          "keybind": "u",
          "icon": "${pkgs.wleave}/share/wleave/icons/suspend.svg"
        },
        {
          "label": "reboot",
          "action": "hyprshutdown --post-cmd 'systemctl reboot'",
          "text": "Reboot",
          "keybind": "r",
          "icon": "${pkgs.wleave}/share/wleave/icons/reboot.svg"
        }
      ]
    }
  '';

  xdg.configFile."wleave/style.css".text = ''
    window {
        background-color: rgba(30, 30, 46, 0.8);
    }

    button {
        color: #cdd6f4;
        background-color: #313244;
        border: none;
        padding: 10px;
        border-radius: 12px;
    }

    button label.action-name {
        font-size: 24px;
        font-weight: 400;
    }

    button label.keybind {
        font-size: 20px;
        font-family: monospace;
    }

    button:hover label.keybind, button:focus label.keybind {
        opacity: 1;
    }

    button:focus,
    button:hover {
        background-color: #45475a;
    }

    button:active {
        color: #1e1e2e;
        background-color: #94e2d5;
    }

    button#shutdown {
        --view-fg-color: #f38ba8;
    }

    button#hibernate {
        --view-fg-color: #89b4fa;
    }

    button#reboot {
        --view-fg-color: #a6e3a1;
    }

    button#lock {
        --view-fg-color: #f9e2af;
    }

    button#logout {
        --view-fg-color: #fab387;
    }

    button#suspend {
        --view-fg-color: #cba6f7;
    }
  '';
}
