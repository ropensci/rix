let
  pkgs = import (fetchTarball {
  url = "https://github.com/rstats-on-nix/nixpkgs/archive/refs/heads/2026-08-24.tar.gz";
 }) {};
 
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
  
  tex = (pkgs.texliveSmall.withPackages (ps: with ps; [
    inconsolata
  ]));
  
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      air-formatter
      glibcLocales
      glibcLocalesUtf8
      nix
      pandoc
      R;
  };
  
in

pkgs.mkShell {
  LOCALE_ARCHIVE = if pkgs.stdenv.hostPlatform.isx86_64 && pkgs.stdenv.hostPlatform.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";
  GITHUB_PAT = builtins.getEnv "GITHUB_PAT";

  buildInputs = pkgs.lib.flatten [  rpkgs tex system_packages   ];
  
}
