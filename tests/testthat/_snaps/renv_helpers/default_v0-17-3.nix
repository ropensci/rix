
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/976fa3369d722e76f37c77493d99829540d43845.tar.gz") {};
 
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

  buildInputs = [  rpkgs  system_packages   ];
  
}
