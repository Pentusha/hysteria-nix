rec {
  description = "Hysteria is a powerful, lightning fast and censorship resistant proxy.";

  nixConfig = {
    extra-substituters = [ "https://hysteria.cachix.org" ];
    extra-trusted-public-keys = [
      "hysteria.cachix.org-1:zAG2qV/akrj0TPOf28gxWTDj57f8SuYjqjHw2u38vZI="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    options-nix.url = "github:eum3l/options.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      options-nix,
    }:
    let
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem platforms (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnsupportedSystem = true;
        };
        versions = pkgs.lib.importJSON ./versions.json;
      in
      rec {
        formatter = pkgs.nixfmt-rfc-style;
        checks.default = pkgs.callPackage ./check { hysteria = self.nixosModules.default; };

        packages = rec {
          default = hysteria;
          hysteria = pkgs.callPackage ./package.nix {
            inherit platforms versions;
          };

          options = options-nix.lib.mkOptionScript {
            inherit system;
            module = self.nixosModules.default;
            modulePrefix = "services.hysteria";
          };
        };

        devShells.default = pkgs.mkShellNoCC {
          HYSTERIA_LOG_LEVEL = "debug";
          HYSTERIA_TMP = "/tmp/hysteria";
          inputsFrom = [ packages.hysteria ];

          shellHook = ''
            rm -rf -- "$HYSTERIA_TMP"
            cp -r --no-preserve=mode,ownership -- "${self.packages.${system}.hysteria.src}" "$HYSTERIA_TMP"
            cd "$HYSTERIA_TMP"
          '';
        };
      }
    )
    // {
      nixosModules.default = import ./module.nix self.packages;

      nixosConfigurations.vultr = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/vultr
          self.nixosModules.default
        ];
      };
    };
}
