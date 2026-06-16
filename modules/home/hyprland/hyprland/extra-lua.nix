{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland.extraLuaFiles = {
    "utils" = {
      autoLoad = true;
      content = ''
        -- Utility functions for Hyprland Lua scripts
        
        local utils = {}
        
        function utils.run(cmd)
          os.execute(cmd .. " >/dev/null 2>&1 &")
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

        function utils.get_mute_status(target)
          local handle = io.popen("wpctl get-volume " .. target)
          if not handle then return false end
          local result = handle:read("*a")
          handle:close()
          return result and result:find("%[MUTED%]")
        end

        function utils.set_led_status(target)
          local led_val 
          if utils.get_mute_status(target) then
            led_val = 1
          else
            led_val = 0
          end

          local led_path
          if target == "@DEFAULT_AUDIO_SINK@" then
            led_path = "/sys/class/leds/platform::micmute/brightness"
          else
            led_path = "/sys/class/leds/platform::mute/brightness"
          end

          local led_file = io.open(led_path, "w")
          if led_file then
              led_file:write(led_val)
              led_file:close()
          end
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

    "window_mgmt" = {
      autoLoad = true;
      content = ''
        -- Window management: Close duplicate Plasma popups on window focus
        
        local window_mgmt = {}
        
        function window_mgmt.manage_plasma_popups()
          local active = hl.get_active_window()

          -- If there's an active window, and it is NOT the plasma popup, close all plasma popups
          if active and active.class ~= "org.kde.plasmawindowed" then
              hl.dispatch(hl.dsp.window.close({ window = "class:org.kde.plasmawindowed" }))
          end
        end
        
        return window_mgmt
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

    "power" = {
      autoLoad = false;
      content = ''
        local utils = require("utils")
        local sounds = require("sounds")

        local state = {
          plugged = nil,
          percentage = nil
        }
        
        local function handle_power_event(event)
          if event == "plugged" then
            utils.play_sound(sounds.powerPlug)
          elseif event == "unplugged" then
            utils.play_sound(sounds.powerUnplug)
          elseif event == "percentage" then
            if state.percentage < 20 then
              utils.play_sound(sounds.batteryLow)
            elseif state.percentage == 100 then
              utils.play_sound(sounds.batteryFull)
            end
          end
        end

        local function monitor_battery()
          -- Use upower to stream power device changes cleanly
          local cmd = "upower --monitor-detail | grep --line-buffered -E 'state:|percentage:'"
          local handle = io.popen(cmd, "r")
          if not handle then return end

          while true do
              local line = handle:read("*l")
              if not line then break end
              
              -- Parse the raw upower stream lines
              if string.find(line, "state:%s+charging") or string.find(line, "state:%s+pending-charge") or string.find(line, "state:%s+fully-charged")then
                if not state.plugged then
                    state.plugged = true
                    handle_power_event("plugged")
                end
              elseif string.find(line, "state:%s+discharging") then
                if state.plugged then
                    state.plugged = false
                    handle_power_event("unplugged")
                end
              elseif string.find(line, "percentage:%s+(%d+)%%") then
                new_percent = tonumber(string.match(line, "percentage:%s+(%d+)%%"))
                if state.percentage ~= new_percent then
                    state.percentage = new_percent
                    handle_power_event("percentage")
                end
              end
          end

          handle:close()
        end

        monitor_battery()
      '';
    };

    "globals" = {
      autoLoad = true;
      content = ''
        -- Startup logic and event handling
        
        local utils = require("utils")
        local wallpaper = require("wallpaper")
        local window_mgmt = require("window_mgmt")
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
          local target
          if mic then
           target = "@DEFAULT_AUDIO_SINK@"
          else
           target = "@DEFAULT_AUDIO_SOURCE@"
          end

          utils.run("volumectl -d -m toggle-mute " .. target)

          utils.set_led_status(target)

          utils.play_sound(sounds.dialogInformation)
        end
        
        function power_plug()
          utils.play_sound(sounds.powerPlug)
        end
        
        function power_unplug()
          utils.play_sound(sounds.powerUnplug)
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
          -- Finalize UWSM session (syncs env and starts graphical-session.target)
          -- This is the correct way to trigger autostart when using programs.hyprland.withUWSM
          utils.run("uwsm finalize")
          
          utils.run("albert")
          
          -- Set initial wallpaper
          local active_ws = hl.get_active_workspace()
          if active_ws then
            on_workspace_change(active_ws.id)
          end

          -- set audio leds
          utils.set_led_status("@DEFAULT_AUDIO_SINK@")
          utils.set_led_status("@DEFAULT_AUDIO_SOURCE@")

          -- run battery monitor
          utils.run("${pkgs.lua}/bin/lua ${config.home.homeDirectory}/.config/hypr/power.lua")
        end)
        
        -- ========================================================================
        -- Event listeners
        -- ========================================================================
        
        hl.on("workspace.active", function(workspace)
          on_workspace_change(workspace.id)
        end)
        
        hl.on("window.active", function()
          window_mgmt.manage_plasma_popups()
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
