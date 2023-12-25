{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/x86_64-linux";
  };
  description = "bdinfo flake";

  outputs = { self, nixpkgs, systems }@inputs: 
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = eachSystem (system:
        nixpkgs.legacyPackages.${system}
      );
    in
  {
    packages = eachSystem (system:
      let
        pkgs = pkgsFor.${system};
        inherit (pkgs) lib;
      in {
        default = let 
          bdinfoSource = builtins.readFile ./src/bdinfo.c;
          versionMatch = builtins.match ".*#define[[:space:]]+BDINFO_VERSION[[:space:]]+\"([^\"]*)\".*" bdinfoSource;
          ffmpeg = pkgs.ffmpeg_6;
        in
          pkgs.stdenv.mkDerivation {
          pname = "bdinfo";
          version = builtins.head versionMatch;
          src = ./.;
          buildInputs = [ ffmpeg pkgs.libbluray ];
          nativeBuildInputs = [ pkgs.pkg-config ];
          installPhase = ''
            make PREFIX=$out install
          '';
          meta = {
            homepage = "https://github.com/schnusch/bdinfo";
            platforms = lib.platforms.linux;
            description = "Get bluray info and extract tracks.";
          };
        };
      }
    );
  };
}
