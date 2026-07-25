{ pkgs, ... }:

let
  oxygen = "${pkgs.kdePackages.oxygen-sounds}/share/sounds/oxygen/stereo";

  pwPlay = "${pkgs.pipewire}/bin/pw-play";
  notifySend = "${pkgs.libnotify}/bin/notify-send";
  upower = "${pkgs.upower}/bin/upower";

  hyprBattery = pkgs.writers.writePython3Bin "hypr-battery" {
    flakeIgnore = [
      "E501"
      "W503"
    ];
  } ''
    import re
    import subprocess
    import sys

    UPOWER = "${upower}"
    NOTIFY = "${notifySend}"
    PW_PLAY = "${pwPlay}"

    SOUND_PLUG = "${oxygen}/power-plug.ogg"
    SOUND_UNPLUG = "${oxygen}/power-unplug.ogg"
    SOUND_LOW = "${oxygen}/battery-low.ogg"
    SOUND_FULL = "${oxygen}/battery-full.ogg"

    STATE_RE = re.compile(r"state:\s+(\S+)")
    PCT_RE = re.compile(r"percentage:\s+(\d+)%")

    PLUGGED_STATES = {"charging", "pending-charge", "fully-charged"}


    def play(path):
        subprocess.Popen(
            [PW_PLAY, path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


    def notify(summary, body="", urgency="normal"):
        subprocess.Popen(
            [NOTIFY, "-u", urgency, "-a", "Power", summary, body],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


    def main():
        plugged = None
        percentage = None
        low_notified = False
        on_display = False

        proc = subprocess.Popen(
            [UPOWER, "--monitor-detail"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
        assert proc.stdout is not None

        for line in proc.stdout:
            line = line.strip()
            if not line:
                continue

            lower = line.lower()
            if "device:" in lower or "device changed:" in lower:
                # Aggregate device only — avoids double events from BAT* + DisplayDevice.
                on_display = "displaydevice" in lower
                continue
            if not on_display:
                continue

            m_state = STATE_RE.search(line)
            if m_state:
                state = m_state.group(1)
                if state in PLUGGED_STATES:
                    is_plugged = True
                elif state == "discharging":
                    is_plugged = False
                else:
                    continue

                if plugged is None:
                    plugged = is_plugged
                    continue

                if is_plugged and not plugged:
                    plugged = True
                    play(SOUND_PLUG)
                    notify("Power plugged in")
                elif (not is_plugged) and plugged:
                    plugged = False
                    play(SOUND_UNPLUG)
                    notify("Power unplugged")
                continue

            m_pct = PCT_RE.search(line)
            if m_pct:
                new_pct = int(m_pct.group(1))
                if percentage is None:
                    percentage = new_pct
                    low_notified = new_pct < 20
                    continue

                if new_pct == percentage:
                    continue
                percentage = new_pct

                if percentage < 20:
                    if not low_notified:
                        low_notified = True
                        play(SOUND_LOW)
                        notify("Battery low", f"{percentage}% remaining", "critical")
                else:
                    low_notified = False

                if percentage == 100:
                    play(SOUND_FULL)
                    notify("Battery full")

        return proc.wait()


    if __name__ == "__main__":
        sys.exit(main() or 0)
  '';

  hyprAudioLeds = pkgs.writers.writePython3Bin "hypr-audio-leds" {
    libraries = [ pkgs.python3Packages.pulsectl ];
    flakeIgnore = [
      "E501"
      "W503"
    ];
  } ''
    import subprocess
    import sys
    import time

    import pulsectl

    PW_PLAY = "${pwPlay}"
    MUTE_LED = "/sys/class/leds/platform::mute/brightness"
    MICMUTE_LED = "/sys/class/leds/platform::micmute/brightness"

    SOUND_ADDED = "${oxygen}/device-added.ogg"
    SOUND_REMOVED = "${oxygen}/device-removed.ogg"


    def play(path):
        subprocess.Popen(
            [PW_PLAY, path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


    def write_led(path, value):
        try:
            with open(path, "w", encoding="utf-8") as f:
                f.write(str(value))
        except OSError:
            pass


    def device_set(pulse):
        sinks = {s.name for s in pulse.sink_list()}
        sources = {
            s.name
            for s in pulse.source_list()
            if not s.name.endswith(".monitor")
        }
        return sinks | sources


    def sync_leds(pulse):
        # LED on when muted.
        try:
            sink = pulse.get_sink_by_name(pulse.server_info().default_sink_name)
            write_led(MUTE_LED, 1 if sink.mute else 0)
        except pulsectl.PulseError:
            pass

        try:
            source = pulse.get_source_by_name(
                pulse.server_info().default_source_name
            )
            write_led(MICMUTE_LED, 1 if source.mute else 0)
        except pulsectl.PulseError:
            pass


    def main():
        while True:
            try:
                with pulsectl.Pulse("hypr-audio-leds") as pulse:
                    known = device_set(pulse)
                    sync_leds(pulse)

                    def on_event(_ev):
                        raise pulsectl.PulseLoopStop

                    pulse.event_mask_set("sink", "source", "server", "card")
                    pulse.event_callback_set(on_event)

                    while True:
                        pulse.event_listen()
                        current = device_set(pulse)
                        added = current - known
                        removed = known - current
                        if added:
                            play(SOUND_ADDED)
                        if removed:
                            play(SOUND_REMOVED)
                        known = current
                        sync_leds(pulse)
            except pulsectl.PulseDisconnected:
                time.sleep(1)
            except Exception as exc:
                print(f"hypr-audio-leds: {exc}", file=sys.stderr)
                time.sleep(1)


    if __name__ == "__main__":
        main()
  '';
in
{
  systemd.user.services.hypr-battery = {
    Unit = {
      Description = "Battery / AC plug monitor (sounds + notifications)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${hyprBattery}/bin/hypr-battery";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hypr-audio-leds = {
    Unit = {
      Description = "Mute LED sync + audio device plug sounds";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "pipewire.service"
        "wireplumber.service"
        "pipewire-pulse.service"
      ];
      Wants = [
        "pipewire.service"
        "wireplumber.service"
      ];
    };
    Service = {
      ExecStart = "${hyprAudioLeds}/bin/hypr-audio-leds";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.albert = {
    Unit = {
      Description = "Albert launcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.albert}/bin/albert";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.mcontrolcenter = {
    Unit = {
      Description = "MControlCenter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mcontrolcenter}/bin/mcontrolcenter";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.kwalletd6 = {
    Unit = {
      Description = "KDE Wallet daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
