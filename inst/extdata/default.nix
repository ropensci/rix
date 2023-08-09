{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8.tar.gz") {} }:

  with pkgs;

  let
    my-r = rWrapper.override {
      packages = with rPackages; [
        (buildRPackage {
           name = "rix";
           src = fetchgit {
           url = "https://github.com/b-rodrigues/rix/";
           branchName = "master";
           rev = "c8b4f6a92b8b56a96a5f1819ca884aca69f2afa7";
           sha256 = "sha256-Ek16NbD4XnbHTQ2vPVeA0mia336EBeXsVIL3QRXzPsk=";
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
      LOCALE_ARCHIVE = "${glibcLocales}/lib/locale/locale-archive";
      buildInputs = [
        my-r
        ];
  }
