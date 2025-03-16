
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-03-10.tar.gz") { config.allowUnfree = true; };
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      dplyr
      janitor;
  };
  
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) 
      scheme-small
      amsmath;
  });
 
  pypkgs = builtins.attrValues {
    inherit (pkgs.python312Packages) 
      pip
      ipykernel
      plotnine
      polars;
  };
  
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix
      positron-bin
      python312;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [  rpkgs tex pypkgs system_packages   ];
    
  }; 
in
  {
    inherit pkgs shell;
  }
