# This file was generated by the {rix} R package v0.2.1.9002 on 2023-09-10
# with following call:
# >rix(r_ver = "78058d810644f5ed276804ce7ea9e82d92bee293",
#  > r_pkgs = NULL,
#  > system_pkgs = "nix",
#  > git_pkgs = list(list(package_name = "rix",
#  > repo_url = "https://github.com/b-rodrigues/rix",
#  > branch_name = "master",
#  > commit = "1bd327c7cf315d22ab69865b6fc96c943cd97bd4")),
#  > ide = "other",
#  > project_path = dirname(path),
#  > overwrite = TRUE,
#  > shell_hook = "R --vanilla")
# It uses nixpkgs' revision 78058d810644f5ed276804ce7ea9e82d92bee293 for reproducibility purposes
# which will install R version latest
# Report any issues to https://github.com/b-rodrigues/rix
let
 pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/78058d810644f5ed276804ce7ea9e82d92bee293.tar.gz") {};
  git_archive_pkgs = [(pkgs.rPackages.buildRPackage {
    name = "rix";
    src = pkgs.fetchgit {
      url = "https://github.com/b-rodrigues/rix";
      branchName = "master";
      rev = "1bd327c7cf315d22ab69865b6fc96c943cd97bd4";
      sha256 = "sha256-qi8FXCsKIuoHoERE6ZhTooHH9f94cRIi6mrUVbQU8NY=";
    };
    propagatedBuildInputs = builtins.attrValues {
      inherit (pkgs.rPackages) httr jsonlite sys;
    };
  }) ];
 tex = (pkgs.texlive.combine {
  inherit (pkgs.texlive) scheme-basic ;
});
 system_packages = builtins.attrValues {
  inherit (pkgs) R nix;
};
  in
  pkgs.mkShell {
    buildInputs = [ git_archive_pkgs   system_packages  ];
      shellHook = ''
R --vanilla
'';
  }
