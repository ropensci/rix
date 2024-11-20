# This file was generated by the {rix} R package v0.13.1 on 2024-11-20
# with following call:
# >rix(r_ver = "976fa3369d722e76f37c77493d99829540d43845",
#  > git_pkgs = list(package_name = "rix",
#  > repo_url = "https://github.com/ropensci/rix/",
#  > commit = "b164178ff58159511d9224ce97288e5d5c5e9c77"),
#  > ide = "other",
#  > project_path = "inst/extdata",
#  > overwrite = TRUE)
# It uses nixpkgs' revision 976fa3369d722e76f37c77493d99829540d43845 for reproducibility purposes
# which will install R version 4.3.1.
# Report any issues to https://github.com/ropensci/rix
let
 pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/976fa3369d722e76f37c77493d99829540d43845.tar.gz") {};
  
  git_archive_pkgs = [
    (pkgs.rPackages.buildRPackage {
      name = "rix";
      src = pkgs.fetchgit {
        url = "https://github.com/ropensci/rix/";
        rev = "b164178ff58159511d9224ce97288e5d5c5e9c77";
        sha256 = "sha256-IBms4KcO6Jyrkk2o5RnH+YlSaBHEHKcbN2v1aLiO1E4=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          codetools
          curl
          jsonlite
          sys;
      };
    })
   ];
   
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

  buildInputs = [ git_archive_pkgs   system_packages   ];
  
}
