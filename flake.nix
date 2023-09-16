{
  description = "A pixel perfect port of dmenu, rewritten in Rust with extensive plugin support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23.05";
    flake-utils.url = "github:numtide/flake-utils/v1.0.0";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-manifest = {
      url =
        "https://static.rust-lang.org/dist/2023-06-01/channel-rust-1.70.0.toml";
      flake = false;
    };
  };

  outputs = inputs:
    with inputs;
    let f = system:
      let
        # Construct nixpkgs with a fenix overlay that pins the rust toolchain
        # to version 1.70.0.
        pkgs = let
          overlays = let
            toolchain =
              fenix.packages.${system}.fromManifestFile rust-manifest;
            cargo = toolchain.cargo;
            rustc = toolchain.rustc;
            fenixOverlay = self: super: {
              inherit (toolchain) cargo rustc;
              rustPlatform = super.makeRustPlatform {
                cargo = toolchain;
                rustc = toolchain;
              };
            };
          in [ fenixOverlay ];
        in import nixpkgs {
          inherit system overlays;
        };

        package = let
          derivation = import ./derivation.nix;
          derivationArguments = {
            inherit (pkgs)
              stdenv rustc rustPlatform lib fetchFromGitHub fetchpatch cargo expat
              fontconfig m4 pkg-config python3;
            inherit (pkgs.xorg)
              libXft libXinerama;
          };
        in derivation derivationArguments;

        devShell = let
          shell = import ./shell.nix;
          shellArguments = { inherit pkgs package; };
        in shell shellArguments;

        app = {
          type = "app";
          program = "${package}/bin/${pname}";
        };
      in {
        apps.default = app;
        devShells.default = devShell;
        packages.default = package;
      };
    in flake-utils.lib.eachSystem [ "aarch64-linux" "x86_64-linux" ] f;
}
