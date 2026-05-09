{
  description = "Unified source bundle for DankMaterialShell plugins";

  inputs = {
    worldclock = {
      url = "git+https://git.alc.xyz/alcxyz/WorldClock.git?ref=main";
      flake = false;
    };
    calculator = {
      url = "git+https://git.alc.xyz/alcxyz/DankCalculator.git?ref=main";
      flake = false;
    };
    quicksearch = {
      url = "git+https://git.alc.xyz/alcxyz/DankQuickSearch.git?ref=main";
      flake = false;
    };
    vault = {
      url = "git+https://git.alc.xyz/alcxyz/DankVault.git?ref=main";
      flake = false;
    };
    translate = {
      url = "git+https://git.alc.xyz/alcxyz/DankTranslate.git?ref=main";
      flake = false;
    };
    spotify = {
      url = "git+https://git.alc.xyz/alcxyz/DankSpotify.git?ref=main";
      flake = false;
    };
    dankcalendar = {
      url = "git+https://git.alc.xyz/alcxyz/DankCalendar.git?ref=main";
      flake = false;
    };
    diskusage = {
      url = "git+https://git.alc.xyz/alcxyz/DankDiskUsage.git?ref=main";
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
