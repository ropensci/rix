
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2023-10-30.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      BH
      R6
      RApiSerialize
      Rcpp
      RcppParallel
      anytime
      askpass
      assertthat
      backports
      base64enc
      bit
      bit64
      brew
      brio
      bslib
      cachem
      callr
      checkmate
      cli
      clipr
      commonmark
      cpp11
      crayon
      credentials
      curl
      desc
      devtools
      diffobj
      digest
      downlit
      dplyr
      ellipsis
      evaluate
      fansi
      fastmap
      fontawesome
      fs
      generics
      gert
      getopt
      gh
      gitcreds
      glue
      highr
      hms
      htmltools
      htmlwidgets
      httpuv
      httr
      httr2
      ini
      jquerylib
      jsonlite
      knitr
      later
      lifecycle
      lubridate
      magrittr
      memoise
      mime
      miniUI
      openssl
      optparse
      pillar
      pkgbuild
      pkgconfig
      pkgdown
      pkgload
      praise
      prettyunits
      processx
      profvis
      progress
      promises
      ps
      purrr
      qs
      ragg
      rappdirs
      rcmdcheck
      rdflib
      readr
      redland
      rematch2
      remotes
      renv
      rjson
      rlang
      rmarkdown
      roxygen2
      rprojroot
      rstudioapi
      rversions
      sass
      sessioninfo
      shiny
      shinyWidgets
      sourcetools
      stringfish
      stringi
      stringr
      sys
      systemfonts
      testthat
      textshaping
      tibble
      tidyr
      tidyselect
      timechange
      tinytex
      tzdb
      urlchecker
      usethis
      utf8
      uuid
      vctrs
      vroom
      waldo
      whisker
      withr
      xfun
      xml2
      xopen
      xtable
      yaml
      zip;
  };
 
  git_archive_pkgs = [
    (pkgs.rPackages.buildRPackage {
      name = "emo";
      src = pkgs.fetchgit {
        url = "https://github.com/hadley/emo";
        rev = "3f03b11491ce3d6fc5601e210927eff73bf8e350";
        sha256 = "sha256-b9IlaJ6c0FlXKizvJU8SEv49mlp2de7Y0at5DK5yBVA=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          stringr
          glue
          crayon
          magrittr
          assertthat
          lubridate
          rlang
          purrr;
      };
    })
   ];
   
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix;
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

  buildInputs = [ git_archive_pkgs rpkgs  system_packages   ];
  
}
