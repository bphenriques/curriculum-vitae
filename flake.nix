{
  description = "bphenriques's curriculum vitae";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = import ./shell.nix { inherit pkgs; };
      });

      # `nix build .#cv` / `.#coverletter` -> hermetic PDF in ./result. CI/releases use these.
      packages = forAllSystems (
        pkgs:
        let
          cvNix = import ./nix { inherit pkgs; };
        in
        {
          default = cvNix.cv;
          inherit (cvNix) cv coverletter;
        }
      );

      # `nix run .#cv` / `.#coverletter` / `.#qrcode` / `.#fonts`. Same commands the
      # dev shell exposes, so this expression is ready to back CI later if wanted.
      apps = forAllSystems (
        pkgs:
        let
          cvNix = import ./nix { inherit pkgs; };
        in
        {
          cv = {
            type = "app";
            program = "${cvNix.build-cv}/bin/build-cv";
          };
          coverletter = {
            type = "app";
            program = "${cvNix.build-coverletter}/bin/build-coverletter";
          };
          qrcode = {
            type = "app";
            program = "${cvNix.regen-qrcode}/bin/regen-qrcode";
          };
          fonts = {
            type = "app";
            program = "${cvNix.regen-fonts}/bin/regen-fonts";
          };
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
