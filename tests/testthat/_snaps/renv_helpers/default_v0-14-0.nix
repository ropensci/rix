
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2021-10-28.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      BiocGenerics
      BiocManager
      BiocVersion
      ComplexHeatmap
      GetoptLong
      GlobalOptions
      IRanges
      MASS
      Matrix
      R6
      RColorBrewer
      Rcpp
      S4Vectors
      askpass
      assertthat
      attempt
      base64enc
      bit
      bit64
      brew
      brio
      bs4Dash
      bslib
      cachem
      callr
      circlize
      cli
      clipr
      clue
      cluster
      codetools
      colorspace
      commonmark
      config
      covr
      cpp11
      crayon
      credentials
      curl
      desc
      devtools
      diffobj
      digest
      doParallel
      dockerfiler
      downlit
      dplyr
      ellipsis
      evaluate
      fansi
      farver
      fastmap
      fontawesome
      foreach
      fresh
      fs
      generics
      gert
      ggplot2
      gh
      gitcreds
      glue
      golem
      gridExtra
      gtable
      here
      highr
      hms
      htmltools
      htmlwidgets
      httpuv
      httr
      ini
      isoband
      iterators
      jquerylib
      jsonlite
      knitr
      labeling
      later
      latex2exp
      lattice
      lazyeval
      lifecycle
      magrittr
      matrixStats
      memoise
      mgcv
      mime
      munsell
      nlme
      openssl
      packrat
      parsedate
      pillar
      pkgbuild
      pkgconfig
      pkgload
      png
      praise
      prettyunits
      processx
      progress
      promises
      ps
      purrr
      rappdirs
      rcmdcheck
      reactR
      reactable
      readr
      rematch
      rematch2
      remotes
      renv
      rex
      rhub
      rjson
      rlang
      rmarkdown
      roxygen2
      rprojroot
      rsconnect
      rstudioapi
      rversions
      sass
      scales
      scico
      sessioninfo
      shape
      shiny
      shinyWidgets
      sourcetools
      stringi
      stringr
      sys
      systemfonts
      testthat
      tibble
      tidyr
      tidyselect
      tinytex
      tzdb
      usethis
      utf8
      uuid
      vctrs
      viridis
      viridisLite
      vroom
      waiter
      waldo
      whisker
      whoami
      withr
      xfun
      xml2
      xopen
      xtable
      yaml
      zip;
  };
 
    colourScaleR = (pkgs.rPackages.buildRPackage {
      name = "colourScaleR";
      src = pkgs.fetchgit {
        url = "https://github.com/richardjacton/colourScaleR";
        rev = "b18385cc06998c16300c30f36424187d899bbb02";
        sha256 = "sha256-zZYUhvJ2HxtALrVi+WZoX8q2WgH6PjLZD27WWCXgZyU=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          viridis
          scico
          RColorBrewer
          scales
          circlize
          gridExtra
          purrr;
      };
    });
     
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [ colourScaleR rpkgs   system_packages   ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
