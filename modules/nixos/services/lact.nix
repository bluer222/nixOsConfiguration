{ config, lib, pkgs, ... }:

{
  config.services.lact.enable = true;

  config.systemd.services.lactd = {
    # A failed start (or crash after bind) leaves /run/lactd.sock; LACT then
    # refuses to start even though nothing is listening.
    serviceConfig.ExecStartPre = [
      "${pkgs.coreutils}/bin/rm -f /run/lactd.sock"
    ];
  };

  # Nix-managed /etc/lact/config.yaml is a store symlink, so LACT cannot
  # persist schema migrations. Keep `version` at the daemon's current schema
  # (7 in lact 0.10) and use nvidia_gpu_vf_curve offsets, not gpu_vf_curve.
  config.services.lact.settings = {
    version = 7;
    daemon = {
      log_level = "info";
      admin_group = "wheel";
      disable_clocks_cleanup = false;
    };
    apply_settings_timer = 5;
    gpus = {
      "10DE:28A0-1462:13C0-0000:01:00.0" = {
        fan_control_enabled = false;
        min_memory_clock = 405;
        max_memory_clock = 8001;
        nvidia_gpu_vf_curve = {
          "0" = { voltage = 450; clockspeed_offset = 0; };
          "1" = { voltage = 460; clockspeed_offset = 0; };
          "2" = { voltage = 465; clockspeed_offset = 0; };
          "3" = { voltage = 470; clockspeed_offset = 0; };
          "4" = { voltage = 475; clockspeed_offset = -15; };
          "5" = { voltage = 485; clockspeed_offset = -15; };
          "6" = { voltage = 490; clockspeed_offset = -15; };
          "7" = { voltage = 495; clockspeed_offset = 0; };
          "8" = { voltage = 500; clockspeed_offset = -15; };
          "9" = { voltage = 510; clockspeed_offset = -15; };
          "10" = { voltage = 515; clockspeed_offset = 0; };
          "11" = { voltage = 520; clockspeed_offset = -15; };
          "12" = { voltage = 525; clockspeed_offset = -15; };
          "13" = { voltage = 535; clockspeed_offset = 0; };
          "14" = { voltage = 540; clockspeed_offset = -15; };
          "15" = { voltage = 545; clockspeed_offset = 0; };
          "16" = { voltage = 550; clockspeed_offset = -15; };
          "17" = { voltage = 560; clockspeed_offset = 0; };
          "18" = { voltage = 565; clockspeed_offset = -15; };
          "19" = { voltage = 570; clockspeed_offset = 0; };
          "20" = { voltage = 575; clockspeed_offset = -15; };
          "21" = { voltage = 585; clockspeed_offset = 0; };
          "22" = { voltage = 590; clockspeed_offset = -15; };
          "23" = { voltage = 595; clockspeed_offset = -15; };
          "24" = { voltage = 600; clockspeed_offset = 0; };
          "25" = { voltage = 610; clockspeed_offset = 0; };
          "26" = { voltage = 615; clockspeed_offset = -15; };
          "27" = { voltage = 620; clockspeed_offset = 0; };
          "28" = { voltage = 625; clockspeed_offset = 0; };
          "29" = { voltage = 635; clockspeed_offset = 0; };
          "30" = { voltage = 640; clockspeed_offset = -15; };
          "31" = { voltage = 645; clockspeed_offset = -15; };
          "32" = { voltage = 650; clockspeed_offset = -15; };
          "33" = { voltage = 660; clockspeed_offset = -15; };
          "34" = { voltage = 665; clockspeed_offset = -15; };
          "35" = { voltage = 670; clockspeed_offset = -15; };
          "36" = { voltage = 675; clockspeed_offset = -15; };
          "37" = { voltage = 685; clockspeed_offset = -15; };
          "38" = { voltage = 690; clockspeed_offset = 286; };
          "39" = { voltage = 695; clockspeed_offset = 286; };
          "40" = { voltage = 700; clockspeed_offset = 286; };
          "41" = { voltage = 710; clockspeed_offset = 271; };
          "42" = { voltage = 715; clockspeed_offset = 286; };
          "43" = { voltage = 720; clockspeed_offset = 286; };
          "44" = { voltage = 725; clockspeed_offset = 271; };
          "45" = { voltage = 735; clockspeed_offset = 286; };
          "46" = { voltage = 740; clockspeed_offset = 271; };
          "47" = { voltage = 745; clockspeed_offset = 286; };
          "48" = { voltage = 750; clockspeed_offset = 286; };
          "49" = { voltage = 760; clockspeed_offset = 286; };
          "50" = { voltage = 765; clockspeed_offset = 271; };
          "51" = { voltage = 770; clockspeed_offset = 286; };
          "52" = { voltage = 775; clockspeed_offset = 286; };
          "53" = { voltage = 785; clockspeed_offset = 286; };
          "54" = { voltage = 790; clockspeed_offset = 286; };
          "55" = { voltage = 795; clockspeed_offset = 286; };
          "56" = { voltage = 800; clockspeed_offset = 286; };
          "57" = { voltage = 810; clockspeed_offset = 286; };
          "58" = { voltage = 815; clockspeed_offset = 286; };
          "59" = { voltage = 820; clockspeed_offset = 286; };
          "60" = { voltage = 825; clockspeed_offset = 286; };
          "61" = { voltage = 835; clockspeed_offset = 286; };
          "62" = { voltage = 840; clockspeed_offset = 286; };
          "63" = { voltage = 845; clockspeed_offset = 286; };
          "64" = { voltage = 850; clockspeed_offset = 286; };
          "65" = { voltage = 860; clockspeed_offset = 286; };
          "66" = { voltage = 865; clockspeed_offset = 286; };
          "67" = { voltage = 870; clockspeed_offset = 286; };
          "68" = { voltage = 875; clockspeed_offset = 286; };
          "69" = { voltage = 885; clockspeed_offset = 286; };
          "70" = { voltage = 890; clockspeed_offset = 286; };
          "71" = { voltage = 895; clockspeed_offset = 286; };
          "72" = { voltage = 900; clockspeed_offset = 286; };
          "73" = { voltage = 910; clockspeed_offset = 286; };
          "74" = { voltage = 915; clockspeed_offset = 301; };
          "75" = { voltage = 920; clockspeed_offset = 286; };
          "76" = { voltage = 925; clockspeed_offset = 286; };
          "77" = { voltage = 935; clockspeed_offset = 286; };
          "78" = { voltage = 940; clockspeed_offset = 286; };
          "79" = { voltage = 945; clockspeed_offset = 271; };
          "80" = { voltage = 950; clockspeed_offset = 241; };
          "81" = { voltage = 960; clockspeed_offset = 226; };
          "82" = { voltage = 965; clockspeed_offset = 211; };
          "83" = { voltage = 970; clockspeed_offset = 196; };
          "84" = { voltage = 975; clockspeed_offset = 181; };
          "85" = { voltage = 985; clockspeed_offset = 166; };
          "86" = { voltage = 990; clockspeed_offset = 151; };
          "87" = { voltage = 995; clockspeed_offset = 136; };
          "88" = { voltage = 1000; clockspeed_offset = 121; };
          "89" = { voltage = 1010; clockspeed_offset = 106; };
          "90" = { voltage = 1015; clockspeed_offset = 91; };
          "91" = { voltage = 1020; clockspeed_offset = 91; };
          "92" = { voltage = 1025; clockspeed_offset = 76; };
          "93" = { voltage = 1035; clockspeed_offset = 76; };
          "94" = { voltage = 1040; clockspeed_offset = 61; };
          "95" = { voltage = 1045; clockspeed_offset = 61; };
          "96" = { voltage = 1050; clockspeed_offset = 46; };
          "97" = { voltage = 1060; clockspeed_offset = 46; };
          "98" = { voltage = 1065; clockspeed_offset = 31; };
          "99" = { voltage = 1070; clockspeed_offset = 31; };
          "100" = { voltage = 1075; clockspeed_offset = 31; };
          "101" = { voltage = 1085; clockspeed_offset = 31; };
          "102" = { voltage = 1090; clockspeed_offset = 16; };
          "103" = { voltage = 1095; clockspeed_offset = 16; };
          "104" = { voltage = 1100; clockspeed_offset = 16; };
          "105" = { voltage = 1110; clockspeed_offset = 16; };
          "106" = { voltage = 1115; clockspeed_offset = 16; };
          "107" = { voltage = 1120; clockspeed_offset = 16; };
          "108" = { voltage = 1125; clockspeed_offset = 16; };
          "109" = { voltage = 1135; clockspeed_offset = 16; };
          "110" = { voltage = 1140; clockspeed_offset = 16; };
          "111" = { voltage = 1145; clockspeed_offset = 16; };
          "112" = { voltage = 1150; clockspeed_offset = 16; };
          "113" = { voltage = 1160; clockspeed_offset = 16; };
          "114" = { voltage = 1165; clockspeed_offset = 16; };
          "115" = { voltage = 1170; clockspeed_offset = 16; };
          "116" = { voltage = 1175; clockspeed_offset = 16; };
          "117" = { voltage = 1185; clockspeed_offset = 16; };
          "118" = { voltage = 1190; clockspeed_offset = 16; };
          "119" = { voltage = 1195; clockspeed_offset = 16; };
          "120" = { voltage = 1200; clockspeed_offset = 16; };
          "121" = { voltage = 1210; clockspeed_offset = 16; };
          "122" = { voltage = 1215; clockspeed_offset = 16; };
          "123" = { voltage = 1220; clockspeed_offset = 16; };
          "124" = { voltage = 1225; clockspeed_offset = 16; };
          "125" = { voltage = 1235; clockspeed_offset = 16; };
          "126" = { voltage = 1240; clockspeed_offset = 16; };
        };
      };
    };
    current_profile = null;
    auto_switch_profiles = false;
  };
}
