
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/REVISION.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      dplyr
      janitor
      quarto;
  };
 
  git_archive_pkgs = [
    (pkgs.rPackages.buildRPackage {
      name = "fusen";
      src = pkgs.fetchgit {
        url = "https://github.com/ThinkR-open/fusen";
        rev = "d617172447d2947efb20ad6a4463742b8a5d79dc";
        sha256 = "sha256-TOHA1ymLUSgZMYIA1a2yvuv0799svaDOl3zOhNRxcmw=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          attachment
          cli
          desc
          devtools
          glue
          here
          magrittr
          parsermd
          roxygen2
          stringi
          tibble
          tidyr
          usethis
          yaml;
      };
    })


    (pkgs.rPackages.buildRPackage {
      name = "housing";
      src = pkgs.fetchgit {
        url = "https://github.com/rap4all/housing/";
        rev = "1c860959310b80e67c41f7bbdc3e84cef00df18e";
        sha256 = "sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          dplyr
          ggplot2
          janitor
          purrr
          readxl
          rlang
          rvest
          stringr
          tidyr;
      };
    })
 
    (pkgs.rPackages.buildRPackage {
      name = "AER";
      src = pkgs.fetchzip {
       url = "https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz";
       sha256 = "sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          car
          lmtest
          sandwich
          survival
          zoo
          Formula;
      };
    })
  ];
 
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) 
      scheme-small
      amsmath;
  });
  
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix
      quarto;
  };
  
in

pkgs.mkShell {
  LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

  buildInputs = [ git_archive_pkgs rpkgs tex system_packages   ];
  
}
