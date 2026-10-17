{
  description = "Unified source bundle for DankMaterialShell plugins";

  inputs = {
    worldclock = {
      url = "github:rochacbruno/WorldClock/main";
      flake = false;
    };
    calculator = {
      url = "github:rochacbruno/DankCalculator/main";
      flake = false;
    };
    screenshot = {
      url = "github:JDKamalakar/DMS-Screenshot/main";
      flake = false;
    };
    quicksearch = {
      url = "github:alcxyz/DankQuickSearch/main";
      flake = false;
    };
    vault = {
      url = "github:alcxyz/DankVault/dev";
      flake = false;
    };
    translate = {
      url = "github:alcxyz/DankTranslate/main";
      flake = false;
    };
    spotify = {
      url = "github:alcxyz/DankSpotify/main";
      flake = false;
    };
    dankcalendar = {
      url = "github:alcxyz/DankCalendar/main";
      flake = false;
    };
    danksession = {
      url = "github:alcxyz/DankSession/main";
      flake = false;
    };
    diskusage = {
      url = "github:alcxyz/DankDiskUsage/main";
      flake = false;
    };
    aiusage = {
      url = "github:alcxyz/DankAIUsage/main";
      flake = false;
    };
    displaycontrol = {
      url = "github:alcxyz/DankDisplayControl/dev";
      flake = false;
    };
    firstparty = {
      url = "github:AvengeMedia/dms-plugins";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    {
      srcs = builtins.removeAttrs inputs [ "self" ];
    };
}
