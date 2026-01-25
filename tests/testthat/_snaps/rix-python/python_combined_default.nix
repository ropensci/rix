
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-03-10.tar.gz") {};
    
 
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
      python312
      uv;
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
    shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath (with pkgs; [ zlib gcc.cc glibc stdenv.cc.cc ])}":$LD_LIBRARY_PATH;
    export PYTHONPATH=$PWD/src:$PYTHONPATH;
    echo Hello
  '';
  }; 
in
  {
    inherit pkgs shell;
  }
