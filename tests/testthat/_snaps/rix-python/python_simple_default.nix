
let
  pkgs = import (fetchTarball {
    url = "https://github.com/rstats-on-nix/nixpkgs/archive/2025-03-10.tar.gz";
    sha256 = "0wpb2av6nnzw88bcgxps65mc6rca7l25hryym7z5w39p5dvgq3is";
  }) {};
    
 
  pyconf = builtins.attrValues {
    inherit (pkgs.python312Packages) 
      pip
      ipykernel
      numpy;
  };
   
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix
      python312;
  };
  
  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.stdenv.isx86_64 && pkgs.stdenv.isLinux then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
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
