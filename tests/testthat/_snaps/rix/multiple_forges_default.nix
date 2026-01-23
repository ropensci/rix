
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-02-24.tar.gz") {};
  
    fifo = (pkgs.rPackages.buildRPackage {
      name = "fifo";
      src = pkgs.fetchgit {
        url = "https://codeberg.org/adamhsparks/fifo/";
        rev = "85a15cc3cc7d5e3e127155b6c5c2716f81ed54d1";
        sha256 = "sha256-QKyOETXC6GbZnevg8vbvfZ33PLK6J0+aS3aeNyT/NP8=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          brio
          cli
          data_table
          httr2
          lifecycle
          purrr
          rlang
          sf
          terra
          weatherOz;
      } ++ [ nert read.abares ];
    });

    nert = (pkgs.rPackages.buildRPackage {
      name = "nert";
      src = pkgs.fetchgit {
        url = "https://github.com/AAGI-AUS/nert/";
        rev = "05d08aa660d47856bd897faa2d2d4c2dbdbbaa53";
        sha256 = "sha256-6NGKJ/LVVaXnSom6dQki9cuYQUiincifBkv13WK2r+k=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          cli
          data_table
          ggplot2
          lubridate
          nlme
          rlang
          terra
          tidyterra;
      };
    });

    read.abares = (pkgs.rPackages.buildRPackage {
      name = "read.abares";
      src = pkgs.fetchgit {
        url = "https://github.com/ropensci/read.abares/";
        rev = "38b8bcc86af93fb70f656a27b9ddfc8362f962ea";
        sha256 = "sha256-3PE23WxwZNIsksQo4COJtyukTTQryZ68sNGwAA6at6g=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          brio
          cli
          data_table
          fs
          htm2txt
          httr2
          lubridate
          purrr
          readxl
          rlang
          sf
          stars
          stringr
          terra
          tidync
          whoami
          withr;
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
    
    buildInputs = [ fifo nert read.abares system_packages ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
