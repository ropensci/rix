
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-03-10.tar.gz") {};
    

    pyclean = (pkgs.python312Packages.buildPythonPackage {
      pname = "pyclean";
      version = "174d4d4-git";
      src = pkgs.fetchgit {
        url = "https://github.com/b-rodrigues/pyclean";
        rev = "174d4d482d400536bb0d987a3e25ae80cd81ef3c";
        sha256 = "sha256-xTYydkuduPpZsCXE2fv5qZCnYYCRoNFpV7lQBM3LMSg=";
      };
      pyproject = true;
      build-system = [ pkgs.python312Packages.setuptools ];
      doCheck = false;
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.python312Packages) pandas;
      };
    });
 
  pyconf = builtins.attrValues {
    inherit (pkgs.python312Packages) 
      pip
      ipykernel;
  } ++ [ pyclean ];
   
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix
      python312;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    RETICULATE_PYTHON = "${pkgs.python312}/bin/python";

    buildInputs = [ pyconf system_packages ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
