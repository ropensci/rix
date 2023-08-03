{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8.tar.gz") {} }:

with pkgs;

let
  bootstrap_env = rWrapper.override {
    packages = with rPackages; [

    (buildRPackage {
      name = "rix";
      src = fetchgit {
      url = "https://github.com/b-rodrigues/rix/";
      branchName = "master";
      rev = "c8bc2e2ad2485d9fda06410642fc9ccd641bc490";
      sha256 = "sha256-axmHWXNEL2c00TQGYJEwrgVNkLbbNhrx/LHkzuMa9QM=";
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
  buildInputs = [bootstrap_env];
  shellHook = "R";
}
