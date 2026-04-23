{
  description = "Unified source bundle for DankMaterialShell plugins";

  inputs = {
    worldclock = {
      url = "github:alcxyz/WorldClock";
      flake = false;
    };
    calculator = {
      url = "github:alcxyz/DankCalculator";
      flake = false;
    };
    quicksearch = {
      url = "github:alcxyz/DankQuickSearch";
      flake = false;
    };
    vault = {
      url = "github:alcxyz/DankVault";
      flake = false;
    };
    translate = {
      url = "github:alcxyz/DankTranslate";
      flake = false;
    };
    spotify = {
      url = "github:alcxyz/DankSpotify";
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
