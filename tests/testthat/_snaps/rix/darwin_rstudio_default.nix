
let
  pkgs = import (fetchTarball {
    url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-02-28.tar.gz";
    sha256 = "0s1ymjmiwz30yvxzkrgrjj5bgn93ya3l8prnz6dv7y6lc3shxlrb";
  }) {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      dplyr;
  };
      
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix;
  };
 
  wrapped_pkgs = pkgs.rstudioWrapper.override {
    packages = [  rpkgs  ];
  };
 
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.stdenv.isx86_64 && pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    
    buildInputs = [ rpkgs system_packages wrapped_pkgs ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
