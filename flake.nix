{
  description = "Bodkin's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      # Texlive Setup Wiki: https://wiki.nixos.org/wiki/TexLive
      environment.systemPackages =
        [
          pkgs._1password-cli
          pkgs.gfortran
          pkgs.home-manager
          pkgs.lua51Packages.lua
          pkgs.lua51Packages.luarocks
          pkgs.mkalias
          pkgs.neovim
          pkgs.texliveFull
          pkgs.tmux
        ];

        homebrew = {
            enable = true;
            brews = [
              "mas"
            ];

            masApps = {
                "XCode" = 497799835;
            };


            casks = [
              "hammerspoon"
              "firefox"
            ];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };


        # System Settings
        system.primaryUser = "bodkin";

        system.keyboard = {
           enableKeyMapping = true;
           remapCapsLockToEscape = true;
        };

        system.defaults = {
          dock.autohide = true;
          dock.persistent-apps = [
              "/System/Applications/Apps.app"
              "/Applications/Safari.app"
              "/Applications/Orion.app"
              "/Applications/Google Chrome.app"
              "/System/Applications/Contacts.app"
              "/System/Applications/Mail.app"
              "/System/Applications/Calendar.app"
              "/System/Applications/Music.app"
              "/System/Applications/Notes.app"
              "/Applications/1Password.app"
              "/Users/bodkin/Applications/Home Manager Apps/Visual Studio Code.app"
              "/Users/bodkin/Applications/Home Manager Apps/Ghostty.app"
              "/Users/bodkin/Applications/Home Manager Apps/Emacs.app"
          ];
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.GuestEnabled = false;
          NSGlobalDomain.AppleICUForce24HourTime = true;
          NSGlobalDomain.AppleInterfaceStyle = "Dark";
          NSGlobalDomain.KeyRepeat = 2;
        };

        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = [
              "/Applications"
              "/Users/bodkin/Applications/Home Manager Apps"
            ];
          };
        in
          pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';


      # Necessary for using flakes on this system.
      #nix.settings.experimental-features = "nix-command flakes";
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."macosm1" = nix-darwin.lib.darwinSystem {
      modules = [ 
        configuration
        nix-homebrew.darwinModules.nix-homebrew {
            nix-homebrew = {
                enable = true;
                # Apple Silicon
                enableRosetta = true;
                # User owning home brew prefix
                user = "bodkin";

                autoMigrate = false;
            };
          }
      ];
    };

    # Expose the package set, including overlay, for convenience.
    darwinPackages = self.darwinConfigurations."macosm1".pkgs;
  };
}
