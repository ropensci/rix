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
      rev = "d505382ad8ef759a8257227a19043e228a6d70dd";
      sha256 = "sha256-vLb7y/6K3iNy8Hb5XmwksAgq5R6yT14JfbDFVPtt2ZY=";
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
