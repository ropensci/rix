{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/ec4c864edddba0d234d2c20e7cd002d98a534ee3.tar.gz") {} }:

with pkgs;

let
  bootstrap_env = rWrapper.override {
    packages = with rPackages; [

    (buildRPackage {
      name = "rix";
      src = fetchgit {
      url = "https://github.com/b-rodrigues/rix/";
      branchName = "master";
      rev = "72abc180b69d4a707f8b696a13a6acb9a7715a8f";
      sha256 = "sha256-u+mGggWEUXauLoY5PZG8JfytG9lvT/2NBNdh1z20Xe8=";
      };
    propagatedBuildInputs = [
      httr
      jsonlite
    ];
      })
    ];
  };
in
mkShell {
  buildInputs = [bootstrap_env curl];
  shellHook = "R";
}
