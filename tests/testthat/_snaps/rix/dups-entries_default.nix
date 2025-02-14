let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2023-12-30.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      checkmate
      Cubist
      matrixStats
      mlr3
      mlr3misc
      paradox
      prospectr
      qs
      tidyverse;
  };
 
    CoxBoost = (pkgs.rPackages.buildRPackage {
      name = "CoxBoost";
      src = pkgs.fetchgit {
        url = "https://github.com/binderh/CoxBoost";
        rev = "HEAD";
        sha256 = "sha256-5Ck0idCpn6oU3RBULqcz7bEtOnYxzKH29aHVzOUWGsQ=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          survival
          Matrix
          prodlim;
      };
    });


    set6 = (pkgs.rPackages.buildRPackage {
      name = "set6";
      src = pkgs.fetchgit {
        url = "https://github.com/xoopR/set6";
        rev = "HEAD";
        sha256 = "sha256-3iDxFyGqSp4msc2BzIFx62nQtO0OsWI8gYhyod4un4A=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          checkmate
          ooplah
          Rcpp
          R6;
      };
    });

    param6 = (pkgs.rPackages.buildRPackage {
      name = "param6";
      src = pkgs.fetchgit {
        url = "https://github.com/xoopR/param6";
        rev = "HEAD";
        sha256 = "sha256-6mfOzx0DPGnKyXJPFm1V1qhsLCIHC26XW8q5jZ2gpAg=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          checkmate
          data_table
          dictionar6
          R6;
      } ++ [ set6 ];
    });

    distr6 = (pkgs.rPackages.buildRPackage {
      name = "distr6";
      src = pkgs.fetchgit {
        url = "https://github.com/xoopR/distr6";
        rev = "HEAD";
        sha256 = "sha256-1PQ2ptGbDumsG5OmAGRqgvoLHu7YinrIupDW1uu8wVA=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          checkmate
          data_table
          ooplah
          R6
          Rcpp;
      } ++ [ set6 param6 ];
    });

    mlr3proba = (pkgs.rPackages.buildRPackage {
      name = "mlr3proba";
      src = pkgs.fetchgit {
        url = "https://github.com/mlr-org/mlr3proba";
        rev = "HEAD";
        sha256 = "sha256-D4baD1WcpCpQbBYfz44QPm8FLVJnZ9dUkU1ujSbebv0=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          mlr3
          checkmate
          data_table
          ggplot2
          mlr3misc
          mlr3pipelines
          paradox
          R6
          Rcpp
          survival;
      } ++ [ distr6 param6 set6 ];
    });





    survivalmodels = (pkgs.rPackages.buildRPackage {
      name = "survivalmodels";
      src = pkgs.fetchgit {
        url = "https://github.com/RaphaelS1/survivalmodels";
        rev = "HEAD";
        sha256 = "sha256-+L6ops0DkXXwjdCSLXkIZ1RPHbt2NoiL6/dQFb18K/o=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          Rcpp;
      } ++ [ distr6 param6 set6 ];
    });

    mlr3extralearners = (pkgs.rPackages.buildRPackage {
      name = "mlr3extralearners";
      src = pkgs.fetchgit {
        url = "https://github.com/mlr-org/mlr3extralearners/";
        rev = "6e2af9ef9ecd420d2be44e9aa2488772bb9f7080";
        sha256 = "sha256-zdoZUSdL90uZcUF/5nxrNhZ9JdVRb6arstW1SjAACX8=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          checkmate
          data_table
          mlr3
          mlr3misc
          paradox
          R6;
      } ++ [ distr6 CoxBoost mlr3proba survivalmodels param6 set6 ];
    });
    
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      glibcLocales
      nix
      R;
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

  buildInputs = [ mlr3extralearners rpkgs  system_packages   ];
  
}
