
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2023-10-30.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      AsioHeaders
      DT
      GlobalOptions
      MASS
      Matrix
      R6
      RColorBrewer
      Rcpp
      RcppEigen
      V8
      base64enc
      beeswarm
      bigD
      bit
      bit64
      bitops
      bslib
      cachem
      callr
      chromote
      circlize
      cli
      clipr
      colorspace
      commonmark
      cowplot
      cpp11
      crayon
      crosstalk
      curl
      data_table
      datasauRus
      digest
      dplyr
      ellipsis
      evaluate
      fansi
      farver
      fastmap
      flextable
      fontawesome
      fs
      gdtools
      generics
      ggbeeswarm
      ggforce
      ggplot2
      ggridges
      glue
      gridExtra
      gt
      gtExtras
      gtable
      highr
      hms
      htmltools
      htmlwidgets
      httpuv
      isoband
      jquerylib
      jsonlite
      juicyjuice
      knitr
      labeling
      later
      lattice
      lazyeval
      lifecycle
      magrittr
      markdown
      mgcv
      mime
      munsell
      nlme
      officer
      paletteer
      pillar
      pkgconfig
      plyr
      polyclip
      prettyunits
      prismatic
      processx
      progress
      promises
      ps
      purrr
      rappdirs
      reactR
      reactable
      reactablefmtr
      readr
      rematch2
      renv
      rlang
      rmarkdown
      rstudioapi
      sass
      scales
      scico
      shape
      shiny
      sourcetools
      stringi
      stringr
      systemfonts
      tibble
      tidyr
      tidyselect
      tinytex
      tippy
      tweenr
      tzdb
      utf8
      uuid
      vctrs
      vipor
      viridis
      viridisLite
      vroom
      webshot
      webshot2
      websocket
      withr
      xfun
      xml2
      xtable
      yaml
      zip;
  };
 
    colorblindr = (pkgs.rPackages.buildRPackage {
      name = "colorblindr";
      src = pkgs.fetchgit {
        url = "https://github.com/clauswilke/colorblindr";
        rev = "90d64f8fc50bee7060be577f180ae019a9bbbb84";
        sha256 = "sha256-VKVFBKJGWJfJRj/lqCbawiaNAWkztKa1kyIdNluW2E0=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          colorspace
          ggplot2
          cowplot
          shiny
          scales;
      };
    });

    colourScaleR = (pkgs.rPackages.buildRPackage {
      name = "colourScaleR";
      src = pkgs.fetchgit {
        url = "https://github.com/RichardJActon/colourScaleR";
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
      nix
      pandoc
      which;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    
    buildInputs = [ colorblindr colourScaleR rpkgs   system_packages   ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
