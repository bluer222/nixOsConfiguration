{ config, ... }:

{
  wayland.windowManager.hyprland.extraLuaFiles = {
    "debug" = {
      autoLoad = true;
      content = ''
      hl.notification.create({ text = "LUA CONFIG IS RUNNING!", timeout = 3000 })
        hl.config({
            debug = {
                disable_logs = false,    -- Enbles standard debug logging
                watchdog_timeout = 0,    -- Optional: Prevents crashes during active debugging
            }
        })
      '';
    };

    "utils" = {
      autoLoad = true;
      content = ''
        -- Utility functions for Hyprland Lua scripts
        
        local utils = {}
        
        function utils.run(cmd)
          os.execute(cmd .. " &")
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
          
          hl.dispatch(hl.dsp.exec_cmd("hyprpaper wallpaper ', " .. wp_file .. "'"))
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
          if not active then return end
          
          local windows = hl.get_windows()
          if not windows then return end
          
          local is_plasma = (active.class or ""):match("^org%.kde%.plasmawindowed")
          
          for _, win in ipairs(windows) do
            local is_win_plasma = (win.class or ""):match("^org%.kde%.plasmawindowed")
            
            -- Close other plasma popups if this one is plasma, or close all if this isn't
            if is_win_plasma and (not is_plasma or win.address ~= active.address) then
              hl.dispatch(hl.dsp.window.close("address:" .. win.address))
            end
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

    "kwallet" = {
      autoLoad = true;
      content = ''
        -- KWallet initialization
        
        local utils = require("utils")
        local kwallet = { initialized = false }
        
        function kwallet.init()
          if kwallet.initialized then return end
          
          -- Start services
          utils.run("systemctl --user start kwalletd6.service ksecretsd.service")
          
          -- Initialize PAM kwallet if available
          if os.getenv("PAM_KWALLET5_LOGIN") then
            utils.run("pam_kwallet_init")
          end
          
          kwallet.initialized = true
        end
        
        return kwallet
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
        local kwallet = require("kwallet")
        
        -- Initialize state
        local show_desktop_active = false
        
        -- ========================================================================
        -- Workspace and Wallpaper Management
        -- ========================================================================
        
        function on_workspace_change(workspace_id)
          print("Raw workspace ID:", workspace_id)
          workspace_id = tonumber(workspace_id)
          print("Workspace changed to:", workspace_id)
          if not workspace_id then return end

          -- if we switched off of desk 4, deactivate show desktop
          if show_desktop_active and workspace_id ~= 4 then
            show_desktop_active = false
          end
          
          wallpaper.change_for_workspace(workspace_id)
        end
        
        function toggle_show_desktop()
          local active_ws = hl.get_active_workspace()
          if not active_ws then return end
          local current_ws = tonumber(active_ws.id)
          local desktop_ws = 4
          
          if show_desktop_active or current_ws == desktop_ws then
            local target = tonumber(show_desktop_active) or 1
            hl.dispatch(hl.dsp.focus({ workspace = target }))
            show_desktop_active = false
          else
            show_desktop_active = current_ws
            hl.dispatch(hl.dsp.focus({ workspace = desktop_ws }))
          end
        end
        
        function focus_workspace(ws_id)
          ws_id = tonumber(ws_id)
          show_desktop_active = false
          hl.dispatch(hl.dsp.focus({ workspace = ws_id }))
        end
        
        function spawn_plasma_popup(name)
          local cmd = ""
          if name == "volume" then
            cmd = "plasmawindowed org.kde.plasma.volume"
          elseif name == "network" then
            cmd = "plasmawindowed org.kde.plasma.networkmanagement"
          elseif name == "bluetooth" then
            cmd = "plasmawindowed org.kde.plasma.bluetooth"
          elseif name == "battery" then
            cmd = "plasmawindowed org.kde.plasma.battery"
          elseif name == "clock" then
            cmd = "plasmawindowed org.kde.plasma.calendar"
          end
          
          if cmd ~= "" then
            utils.run(cmd)
          end
        end
        
        -- ========================================================================
        -- Window Management: Close duplicate plasma popups
        -- ========================================================================
        
        function on_window_focus()
          window_mgmt.manage_plasma_popups()
        end
        
        -- ========================================================================
        -- Volume feedback
        -- ========================================================================
        
        function volume_up()
          utils.run("volumectl -d up")
          utils.play_sound(sounds.dialogue-information)
        end
        
        function volume_down()
          utils.run("volumectl -d down")
          utils.play_sound(sounds.dialogue-information)
        end
        
        function volume_toggle_mute()
          utils.run("volumectl -d toggle-mute")
          utils.play_sound(sounds.dialogue-information)
        end
        
        function power_plug()
          utils.play_sound(sounds.power-plug)
        end
        
        function power_unplug()
          utils.play_sound(sounds.power-unplug)
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
          -- Use utils.run for non-blocking theme application
          utils.run("${config.home.homeDirectory}/.config/hypr/scripts/apply-desktop-theme.sh")
          
          -- Finalize UWSM session (syncs env and starts graphical-session.target)
          -- This is the correct way to trigger autostart when using programs.hyprland.withUWSM
          utils.run("uwsm finalize")
          
          kwallet.init()
          utils.run("albert")
          
          -- Set initial wallpaper
          local active_ws = hl.get_active_workspace()
          if active_ws then
            on_workspace_change(active_ws.id)
          end
        end)
        
        -- ========================================================================
        -- Event listeners
        -- ========================================================================
        
        hl.on("workspace.active", function(workspace_id)
          print("Workspace changed to:", workspace_id)
          on_workspace_change(workspace_id)
        end)
        
        hl.on("window.active", function()
          on_window_focus()
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
