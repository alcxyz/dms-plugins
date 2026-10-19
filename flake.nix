{
  description = "Unified source bundle for DankMaterialShell plugins";

  inputs = {
    worldclock = {
      # Exact upstream revisions: the daily input update must not promote
      # unreviewed third-party commits (ADR-004).
      url = "github:rochacbruno/WorldClock/061752535b5b38f8290edb7108a25cb5f779d405";
      flake = false;
    };
    calculator = {
      url = "github:rochacbruno/DankCalculator/07d7c123a5aee9ac4fd4347bbae36d5957b021f9";
      flake = false;
    };
    screenshot = {
      url = "github:JDKamalakar/DMS-Screenshot/663eecc48d8532143c5995148aa561122d6bfd7e";
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
      # Exact upstream revision, like the plugin inputs above (ADR-004).
      url = "github:AvengeMedia/dms-plugins/a8a508bc371e7c3f2c7862d8840b88cf5c63978f";
      flake = false;
    };
  };

  outputs =
    { self, ... }@inputs:
    {
      srcs = builtins.removeAttrs inputs [ "self" ];
    };
}
