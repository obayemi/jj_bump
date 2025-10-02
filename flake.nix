{
  description = "A script to bump jj bookmarks to the last non-empty revision";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "jj-bump";
          version = "0.1.0";

          src = ./.;

          buildInputs = [ pkgs.bash ];

          installPhase = ''
            mkdir -p $out/bin
            cp jj_bump $out/bin/jj-bump
            chmod +x $out/bin/jj-bump
          '';

          meta = with pkgs.lib; {
            description = "Bump jj bookmarks to the last non-empty revision";
            license = licenses.mit;
            platforms = platforms.unix;
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/jj-bump";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            jujutsu
          ];
        };
      });
}
