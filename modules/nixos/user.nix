{ config, inputs, pkgs, lib, stdenv, ... }:

{
  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.samm = {
    #user
    isNormalUser = true;
    home = "/home/samm";
    description = "Sam Merlin";
    extraGroups = [ "video" "networkmanager" "wheel" "ydotool" "audio" "i2c" "dialout" "docker" ];
  };
}
