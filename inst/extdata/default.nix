# This file was generated by the {rix} R package v0.15.7 on 2025-03-17
# with following call:
# >rix(date = "2025-02-28",
#  > git_pkgs = list(package_name = "rix",
#  > repo_url = "https://github.com/ropensci/rix/",
#  > commit = "8f6f4ae2ad7bda70d2b6b58622c3e6e1d023a906"),
#  > ide = "none",
#  > project_path = "inst/extdata",
#  > overwrite = TRUE,
#  > r_ver = "4.4.3")
# It uses the `rstats-on-nix` fork of `nixpkgs` which provides improved
# compatibility with older R versions and R packages for Linux/WSL and
# Apple Silicon computers.
# Report any issues to https://github.com/ropensci/rix
let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-02-28.tar.gz") {};
  
    rix = (pkgs.rPackages.buildRPackage {
      name = "rix";
      src = pkgs.fetchgit {
        url = "https://github.com/ropensci/rix/";
        rev = "8f6f4ae2ad7bda70d2b6b58622c3e6e1d023a906";
        sha256 = "sha256-gQWL/Iv+54pfpZ9DdkNvaZC3uc4mtndkXiBfurP/Ip0=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          codetools
          curl
          jsonlite
          sys;
      };
    });
     
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      glibcLocales
      nix
      R;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [ rix    system_packages   ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
