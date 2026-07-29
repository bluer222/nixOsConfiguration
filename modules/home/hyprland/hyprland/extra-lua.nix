{ pkgs, ... }:

{
  wayland.windowManager.hyprland.extraLuaFiles = {
    "utils" = {
      autoLoad = true;
      content = ''
        -- Utility functions for Hyprland Lua scripts
        
        local utils = {}
        
        function utils.run(cmd)
          hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- " .. cmd)
        end

        function utils.run_capture(cmd)
          local handle = io.popen(cmd .. " 2>&1", "r")
          if not handle then
            return nil, false
          end

          local output = handle:read("*a")
          local ok, _, _ = handle:close()
          return output, ok == true
        end

        function utils.shell_quote(str)
          return "'" .. str:gsub("'", "'\"'\"'") .. "'"
        end

        function utils.copy_to_clipboard(text)
          local handle = io.popen("wl-copy", "w")
          if not handle then
            return false
          end

          handle:write(text)
          handle:close()
          return true
        end

        function utils.ocr_selection()
          local image_path = "/tmp/hyprshot-ocr.png"
          os.remove(image_path)

          local _, ok = utils.run_capture("{pkgs.hyprshot}/bin/hyprshot -m region --output-folder /tmp --filename hyprshot-ocr.png >/dev/null 2>&1")
          if not ok then
            hl.notification.create({
              text = "OCR cancelled or failed",
              timeout = 3000
            })
            return
          end

          if not utils.file_exists(image_path) then
            hl.notification.create({
              text = "No screenshot captured",
              timeout = 3000
            })
            return
          end

          local text, text_ok = utils.run_capture("{pkgs.tesseract}/bin/tesseract " .. utils.shell_quote(image_path) .. " stdout 2>/dev/null")
          if not text_ok or not text or text:gsub("%s+", "") == "" then
            hl.notification.create({
              text = "No text detected",
              timeout = 3000
            })
            return
          end

          utils.copy_to_clipboard(text)

          hl.notification.create({
            text = text,
            timeout = 5000
          })
        end

        function utils.log_uwsm(msg)
          local log = io.open("/tmp/hyprland-uwsm.log", "a")
          if log then
            log:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. msg .. "\n")
            log:close()
          end
        end
        function utils.play_sound(sound_path)
          utils.run("pw-play '" .. sound_path .. "'")
        end
        
        function utils.file_exists(path)
          local f = io.open(path, "r")
          if f then
            f:close()
            return true
          end
          return false
        end

        function utils.read_file(path)
          local f = io.open(path, "r")
          if not f then return nil end
          local content = f:read("*all")
          f:close()
          return content
        end

        function utils.write_file(path, content)
          local f = io.open(path, "w")
          if not f then return false end
          f:write(content)
          f:close()
          return true
        end

        return utils
      '';
    };

    "wallpaper" = {
      autoLoad = true;
      content = ''
        -- Workspace-based wallpaper management
        
        local utils = require("utils")
        local wallpaper = {}
        
        local wp_base = os.getenv("HOME") .. "/Pictures/Wallpapers"
        
        function wallpaper.change_for_workspace(ws_id)
          local wp_file = wp_base .. "/workspace-" .. ws_id .. ".png"
          
          if not utils.file_exists(wp_file) then
            return
          end
          
          -- put this here so it doesnt trigger on show desktop
          hl.notification.create({
            text = "Switched to workspace " .. ws_id,
            timeout = 3000
          })
          
          hl.dispatch(hl.dsp.exec_cmd("hyprctl hyprpaper wallpaper ', " .. wp_file .. "'"))
        end
        
        return wallpaper
      '';
    };

    "brightness" = {
      autoLoad = true;
      content = ''
        -- Brightness management with state persistence
        
        local utils = require("utils")
        local brightness = {}
        
        local state_file = (os.getenv("XDG_RUNTIME_DIR") or "/run/user/1000") .. "/hypr-brightness-saved"
        local backlight_dir = "/sys/class/backlight/intel_backlight"
        
        local function get_current_percent()
          local cur = tonumber(utils.read_file(backlight_dir .. "/brightness"))
          local max = tonumber(utils.read_file(backlight_dir .. "/max_brightness"))
          if cur and max then
            return math.floor((cur / max) * 100)
          end
          return nil
        end
        
        function brightness.save_and_dim()
          if utils.file_exists(state_file) then return end -- Already dimmed
          
          local current = get_current_percent()
          if current then
            utils.write_file(state_file, tostring(current))
          end
          
          utils.run("lightctl -d set 10")
        end
        
        function brightness.restore()
          local saved = utils.read_file(state_file)
          if saved then
            utils.run("lightctl -d set " .. saved)
            os.remove(state_file)
          else
            -- Fallback if no state found
            utils.run("lightctl -d set 80")
          end
        end
        
        return brightness
      '';
    };

    "globals" = {
      autoLoad = true;
      content = ''
        -- Startup logic and event handling
        
        local utils = require("utils")
        local wallpaper = require("wallpaper")
        local brightness = require("brightness")
        local sounds = require("sounds")
        
        -- Initialize state
        local show_desktop_active = false
        local active_workspace = nil
        
        -- ========================================================================
        -- Workspace and Wallpaper Management
        -- ========================================================================
        
        function on_workspace_change(workspace_id)
          workspace_id = tonumber(workspace_id)
          if not workspace_id then return end

          -- if we switched off of desk 4, deactivate show desktop
          show_desktop_active = workspace_id == 4
          
          wallpaper.change_for_workspace(workspace_id)
        end
        
        function toggle_show_desktop()
          local desktop_ws = 4
          
          if show_desktop_active then
            hl.dispatch(hl.dsp.focus({ workspace = active_workspace }))
            show_desktop_active = false
            hl.notification.create({
              text = "Windows restored",
              timeout = 3000
            })
          else
            active_workspace = hl.get_active_workspace()
            show_desktop_active = true
            hl.dispatch(hl.dsp.focus({ workspace = desktop_ws }))
            hl.notification.create({
              text = "Showing desktop",
              timeout = 3000
            })
          end
        end
        
        function focus_workspace(ws_id)
          hl.dispatch(hl.dsp.focus({ workspace = tonumber(ws_id) }))
        end
        
        -- ========================================================================
        -- Volume feedback
        -- ========================================================================
        
        function volume_up()
          utils.play_sound(sounds.dialogInformation)
          utils.run("volumectl -d up")
        end
        
        function volume_down()
          utils.play_sound(sounds.dialogInformation)
          utils.run("volumectl -d down")
        end
        
        function volume_toggle_mute(mic)
          if mic then
            utils.run("volumectl -d -m toggle-mute")
          else
            utils.run("volumectl -d toggle-mute")
          end

          utils.play_sound(sounds.dialogInformation)
        end

        function ocr_selection()
          utils.ocr_selection()
        end
        
        -- ========================================================================
        -- Brightness management
        -- ========================================================================
        
        function dim_brightness()
          brightness.save_and_dim()
        end
        
        function restore_brightness()
          brightness.restore()
        end
        
        -- ========================================================================
        -- Startup event handling
        -- ========================================================================
        
        hl.on("hyprland.start", function()          
          utils.run("${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init")
          utils.run("hyprlock")
        end)
        
        -- ========================================================================
        -- Event listeners
        -- ========================================================================
        
        hl.on("workspace.active", function(workspace)
          on_workspace_change(workspace.id)
        end)
      '';
    };

    "plugins/darkwindow" = {
      autoLoad = false;
      content = ''
        -- Chromakey + subpixel antialiasing do not mix (RGB fringe pixels survive the key).
        -- Subpixel is disabled in ~/.config/fontconfig/fonts.conf.
        if hl.plugin.darkwindow ~= nil then
          hl.plugin.darkwindow.load_shader("mochaChromakey", {
            from = "chromakey",
            args = "bkg=[0.141 0.153 0.227] similarity=0.2 amount=1.0 targetOpacity=0.70",
            introduces_transparency = true,
          })
          hl.window_rule({
            name = "darkwindow-mocha",
            -- Disabled until session is stable (no match ⇒ too broad / risky on login).
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
