let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2026-01-14.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      codetools
      codemetar
      devtools
      diffviewer
      httr
      jsonlite
      knitr
      languageserver
      lintr
      rhub
      rmarkdown
      styler
      sys
      testthat
      urlchecker;
  };
  
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) 
      scheme-small
      inconsolata;
  });
  
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      aider-chat
      air-formatter
      glibcLocales
      glibcLocalesUtf8
      nix
      pandoc
      R;
  };
  
in

pkgs.mkShell {
  LOCALE_ARCHIVE = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

  buildInputs = [  rpkgs tex system_packages   ];
  
}
