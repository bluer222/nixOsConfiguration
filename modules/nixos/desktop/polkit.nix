{ config, pkgs, ... }:

{
  security.polkit.enable = true;

  # Dolphin "Open as Administrator" / privileged file ops go through kio-admin + polkit.
  environment.systemPackages = with pkgs; [
    kdePackages.kio-admin
  ];

  # UWSM runs GUI apps under user@.service (often with no logind session on the
  # pid). The agent registers for the seat session via User.Display, but polkit
  # cannot match sessionless/untracked processes to it — Dolphin then reports
  # "PolicyKit authentication system appears to be not available".
  # Grant wheel the same outcomes an active seat session would get for the
  # common GUI privilege paths; interactive run0/pkexec still use the agent.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (!subject.local || !subject.isInGroup("wheel"))
        return;

      if (action.id.indexOf("org.freedesktop.udisks2.") === 0)
        return polkit.Result.YES;

      if (action.id.indexOf("org.kde.kpmcore.") === 0)
        return polkit.Result.YES;

      if (action.id.indexOf("org.kde.kio.admin.") === 0)
        return polkit.Result.YES;
    });
  '';
}
