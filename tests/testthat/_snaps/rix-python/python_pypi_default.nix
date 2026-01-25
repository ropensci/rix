
let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-03-10.tar.gz") {};
    
 
    ryxpress = (pkgs.python312Packages.buildPythonPackage {
      pname = "ryxpress";
      version = "0.1.1";
      src = pkgs.fetchzip {
        url = "https://files.pythonhosted.org/packages/6c/8c/e5d5bbb805d8caf814c6348eaa3d4d14f6049d1637ec63b26d1c31eec940/ryxpress-0.1.1.tar.gz";
        sha256 = "sha256-V6BnAV2sMWPhjR+zVkjjNgqsP2II1ZjdRQFcuuQ/0Z4=";
      };
      doCheck = false;
      propagatedBuildInputs = [ ]; 
    });

  pyconf = builtins.attrValues {
    inherit (pkgs.python312Packages) 
      pip
      ipykernel;
  } ++ [ ryxpress ];
   
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
