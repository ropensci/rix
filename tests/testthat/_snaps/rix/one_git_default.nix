
let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/976fa3369d722e76f37c77493d99829540d43845.tar.gz") {};
  
  git_archive_pkgs = [
    (pkgs.rPackages.buildRPackage {
      name = "lookup";
      src = pkgs.fetchgit {
        url = "https://github.com/jimhester/lookup/";
        rev = "eba63db477dd2f20153b75e2949eb333a36cccfc";
        sha256 = "sha256-arl7LVxL8xGUW3LhuDCSUjcfswX0rdofL/7v8Klw8FM=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          gh
          memoise
          Rcpp
          codetools
          crayon
          rex
          highlite
          jsonlite
          rstudioapi
          withr
          httr;
      };
    })
   ];
   
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      R
      glibcLocales
      nix;
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

  buildInputs = [ git_archive_pkgs   system_packages   ];
  
}
