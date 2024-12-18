
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2024-02-29.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      R6
      askpass
      base64enc
      brio
      bslib
      cachem
      callr
      cli
      clipr
      codetools
      cpp11
      crayon
      credentials
      curl
      desc
      diffobj
      digest
      downlit
      evaluate
      fansi
      fastmap
      fontawesome
      fs
      gert
      gh
      gitcreds
      glue
      highr
      htmltools
      httr2
      ini
      jquerylib
      jsonlite
      knitr
      lifecycle
      magrittr
      memoise
      mime
      openssl
      pillar
      pkgbuild
      pkgconfig
      pkgdown
      pkgload
      praise
      processx
      ps
      purrr
      ragg
      rappdirs
      rematch2
      renv
      rlang
      rmarkdown
      rprojroot
      rstudioapi
      sass
      sys
      systemfonts
      testthat
      textshaping
      tibble
      tinytex
      usethis
      utf8
      vctrs
      waldo
      whisker
      withr
      xfun
      xml2
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
