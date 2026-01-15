
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2023-10-30.tar.gz") {};
  
    housing = (pkgs.rPackages.buildRPackage {
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
    });
      
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    
    buildInputs = [ housing system_packages ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
