{ pkgs, ... }:
{
  environment.systemPackages = [ (pkgs.callPackage ../../../pkgs/stealth-keyboard { }) ];

  # Grant the active local session access to the lighting interface only.
  services.udev.packages = [ (pkgs.writeTextDir "lib/udev/rules.d/70-stealth-keyboard.rules" ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="113a", ENV{ID_USB_INTERFACE_NUM}=="00", TAG+="uaccess"
  '') ];
}
