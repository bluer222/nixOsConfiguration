{ config, ... }:

let
  scripts = "${config.home.homeDirectory}/.config/hypr/scripts";
in
{
  wayland.windowManager.hyprland.extraLuaFiles = {
    "globals" = {
      autoLoad = true;
      content = ''
        -- Startup logic
        hl.on("hyprland.start", function()
          hl.exec_cmd("${scripts}/apply-desktop-theme.sh")
          hl.exec_cmd("${scripts}/kwallet-unlock.sh")
          hl.exec_cmd("albert")
        end)
      '';
    };

    "plugins/darkwindow" = {
      autoLoad = true;
      content = ''
        -- Chromakey + subpixel antialiasing do not mix (RGB fringe pixels survive the key).
        -- Subpixel is disabled in ~/.config/fontconfig/fonts.conf.
        if hl.plugin.darkwindow ~= nil then
          hl.plugin.darkwindow.load_shader("mochaChromakey", {
            from = "chromakey",
            args = "bkg=[0.118 0.118 0.180] similarity=0.14 amount=1.0 targetOpacity=0.65",
            introduces_transparency = true,
          })
          hl.window_rule({
            name = "darkwindow-mocha",
            --  Don't apply to Steam or Steam game windows (steam, steam_app_<id>)
             -- match = { class = ".*" },
             --temp disable
             match = { class = "none" },
            ["darkwindow:shade"] = "mochaChromakey",
          })
        end
      '';
    };

    "plugins/dynamic-cursors" = {
      autoLoad = false;
      content = ''
        -- Reference config for hypr-dynamic-cursors (plugin loaded via HM plugins list).
        -- hl.plugin {
        --   ["dynamic-cursors"] = {
        --     mode = "tilt",
        --     shake = { enabled = true },
        --   }
        -- }
      '';
    };
  };
}
