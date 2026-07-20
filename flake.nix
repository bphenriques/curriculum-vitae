{
  description = "bphenriques's curriculum vitae";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      cv = import ./nix { inherit pkgs; };
    in
    {
      devShells.x86_64-linux.default = cv.devShell;
      packages.x86_64-linux = { inherit (cv) cv coverletter; };
    };
}
