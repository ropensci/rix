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
           rev = "34f4715e7fa37748d3db047ce3b7f4dafe1da59c";
           sha256 = "sha256-NUu+xn8r6wy5n2U6cyKgCxOw/z97waDxkoXoG1zwpI8=";
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
