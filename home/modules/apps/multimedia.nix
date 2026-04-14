{ config, pkgs, ... }:

{
  # Multimedia and editing packages
  programs.obs-studio.enable = true;
  #programs.obs-studio.enableVirtualCamera = true;
  #cant do above bc of howdy
  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
  boot.extraModprobeConfig = ''options v4l2loopback devices=1 video_nr=3 card_label="OBS Cam" exclusive_caps=1'';

  environment.systemPackages = with pkgs; [
    vlc
    audacity
    ffmpeg-full
    kdePackages.kolourpaint
    kdePackages.krecorder
    gimp3
    qview
    cura-appimage
    upscayl
  ];
}
