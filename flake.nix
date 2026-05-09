{
  description = "Unified source bundle for DankMaterialShell plugins";

  inputs = {
    worldclock = {
      url = "github:alcxyz/WorldClock/main";
      flake = false;
    };
    calculator = {
      url = "github:alcxyz/DankCalculator/main";
      flake = false;
    };
    quicksearch = {
      url = "github:alcxyz/DankQuickSearch/main";
      flake = false;
    };
    vault = {
      url = "github:alcxyz/DankVault/main";
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
    diskusage = {
      url = "github:alcxyz/DankDiskUsage/main";
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
