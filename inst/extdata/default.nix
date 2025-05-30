# This file was generated by the {rix} R package v0.17.0 on 2025-05-23
# with following call:
# >rix(date = "2025-04-29",
#  > git_pkgs = list(list(package_name = "rix",
#  > repo_url = "https://github.com/ropensci/rix/",
#  > commit = "4ad3a1debb4eb54d0568c34445a27063b64c5b8b"),
#  > list(package_name = "rixpress",
#  > repo_url = "https://github.com/b-rodrigues/rixpress/",
#  > commit = "bc01fda3d0463bbd8563eee08a80d0ab4d425808")),
#  > ide = "none",
#  > project_path = "inst/extdata",
#  > overwrite = TRUE,
#  > r_ver = "4.5.0")
# It uses the `rstats-on-nix` fork of `nixpkgs` which provides improved
# compatibility with older R versions and R packages for Linux/WSL and
# Apple Silicon computers.
# Report any issues to https://github.com/ropensci/rix
let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-04-29.tar.gz") {};
  
    rix = (pkgs.rPackages.buildRPackage {
      name = "rix";
      src = pkgs.fetchgit {
        url = "https://github.com/ropensci/rix/";
        rev = "4ad3a1debb4eb54d0568c34445a27063b64c5b8b";
        sha256 = "sha256-u60eqcTI6bihrZbMMxFR+STAbh8J7MWqmU22RmiOLi4=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          codetools
          curl
          jsonlite
          sys;
      };
    });

    rixpress = (pkgs.rPackages.buildRPackage {
      name = "rixpress";
      src = pkgs.fetchgit {
        url = "https://github.com/b-rodrigues/rixpress/";
        rev = "bc01fda3d0463bbd8563eee08a80d0ab4d425808";
        sha256 = "sha256-kk8/UMBfZFTzasa6+RWdB8toHmSn8C5lCyVW1FFApaU=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          igraph
          jsonlite
          processx;
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
    
    buildInputs = [ rix rixpress system_packages ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
