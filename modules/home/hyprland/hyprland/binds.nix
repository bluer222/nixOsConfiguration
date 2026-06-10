{ config, lib, ... }:

let
  scripts = "${config.home.homeDirectory}/.config/hypr/scripts";
  inline = lib.generators.mkLuaInline;
  bindOpts = {
    locked = true;
    repeating = true;
  };
in {
  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        (inline ''mainMod .. " + SUPER_L"'')
        (inline "hl.dsp.exec_cmd(\"albert toggle\")")
        {
          release = true;
        }
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + Escape"'')
        (inline "hl.dsp.window.close()")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + SHIFT + Escape"'')
        (inline "hl.dsp.exec_cmd(\"hyprctl activewindow -j | jq -r '.pid' | xargs kill -9\")")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + W"'')
        (inline "hl.dsp.window.move({ direction = \"up\" })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + A"'')
        (inline "hl.dsp.window.move({ direction = \"left\" })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + S"'')
        (inline "hl.dsp.window.move({ direction = \"down\" })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + D"'')
        (inline "hl.dsp.window.move({ direction = \"right\" })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + E"'')
        (inline "hl.dsp.exec_cmd(\"${scripts}/focus_workspace.sh 1\")")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + R"'')
        (inline "hl.dsp.exec_cmd(\"${scripts}/focus_workspace.sh 2\")")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + F"'')
        (inline "hl.dsp.exec_cmd(\"${scripts}/focus_workspace.sh 3\")")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + SHIFT + E"'')
        (inline "hl.dsp.window.move({ workspace = 1 })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + SHIFT + R"'')
        (inline "hl.dsp.window.move({ workspace = 2 })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + SHIFT + F"'')
        (inline "hl.dsp.window.move({ workspace = 3 })")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + GRAVE"'')
        (inline "hl.dsp.exec_cmd(\"${scripts}/show_desktop.sh\")")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + V"'')
        (inline "hl.dsp.exec_cmd(\"cliphist list | rofi -dmenu -unfocus-exit -theme ~/.config/rofi/spotlight.rasi | cliphist decode | wl-copy\")")
      ];
    }
    {
      _args = [
        "code:161"
        (inline "hl.dsp.exec_cmd(\"hyprctl reload\")")
      ];
    }
    {
      _args = [
        "Print"
        (inline "hl.dsp.exec_cmd(\"${scripts}/screenshot-region.sh\")")
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + mouse:272"'')
        (inline "hl.dsp.window.resize()")
        {
          mouse = true;
        }
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + mouse:273"'')
        (inline "hl.dsp.window.drag()")
        {
          mouse = true;
        }
      ];
    }
    {
      _args = [
        "XF86AudioMute"
        (inline "hl.dsp.exec_cmd(\"${scripts}/volume-key.sh mute\")")
        bindOpts
      ];
    }
    {
      _args = [
        "XF86AudioLowerVolume"
        (inline "hl.dsp.exec_cmd(\"${scripts}/volume-key.sh down\")")
        bindOpts
      ];
    }
    {
      _args = [
        "XF86AudioRaiseVolume"
        (inline "hl.dsp.exec_cmd(\"${scripts}/volume-key.sh up\")")
        bindOpts
      ];
    }
    {
      _args = [
        "XF86AudioMicMute"
        (inline "hl.dsp.exec_cmd(\"volumectl -d -m toggle-mute\")")
        bindOpts
      ];
    }
    {
      _args = [
        "XF86MonBrightnessUp"
        (inline "hl.dsp.exec_cmd(\"${scripts}/brightness-key.sh up\")")
        bindOpts
      ];
    }
    {
      _args = [
        "XF86MonBrightnessDown"
        (inline "hl.dsp.exec_cmd(\"${scripts}/brightness-key.sh down\")")
        bindOpts
      ];
    }
    {
      _args = [
        "code:224"
        (inline "hl.dsp.exec_cmd(\"${scripts}/brightness-key.sh down\")")
        bindOpts
      ];
    }
    {
      _args = [
        "code:225"
        (inline "hl.dsp.exec_cmd(\"${scripts}/brightness-key.sh up\")")
        bindOpts
      ];
    }
    {
      _args = [
        "XF86PowerOff"
        (inline "hl.dsp.exec_cmd(\"/etc/power_menu.sh\")")
        {
          locked = true;
        }
      ];
    }
    {
      _args = [
        (inline ''mainMod .. " + P"'')
        (inline "hl.dsp.exec_cmd(\"${scripts}/open-monitors.sh\")")
        {
          locked = true;
        }
      ];
    }
    {
      _args = [
        "XF86Display"
        (inline "hl.dsp.exec_cmd(\"${scripts}/open-monitors.sh\")")
        {
          locked = true;
        }
      ];
    }
    {
      _args = [
        "XF86Launch1"
        (inline "hl.dsp.exec_cmd(\"${scripts}/open-monitors.sh\")")
        {
          locked = true;
        }
      ];
    }
  ];
}
