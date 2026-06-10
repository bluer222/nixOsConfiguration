{ ... }:

{
  wayland.windowManager.hyprland.extraLuaFiles = {
    "plugins/darkwindow" = {
      autoLoad = true;
      content = ''
        -- Chromakey + subpixel antialiasing do not mix (RGB fringe pixels survive the key).
        -- Subpixel is disabled in ~/.config/fontconfig/fonts.conf.
        if hl.plugin.darkwindow ~= nil then
          hl.plugin.darkwindow.load_shader("mochaChromakey", {
            from = "chromakey",
            args = "bkg=[0.118 0.118 0.180] similarity=0.14 amount=1.0 targetOpacity=0.80",
            introduces_transparency = true,
          })
          hl.window_rule({
            name = "darkwindow-mocha",
            match = { class = ".*" },
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
