  git_archive_pkgs = [(pkgs.rPackages.buildRPackage {
    name = "rix";
    src = pkgs.fetchgit {
      url = "https://github.com/b-rodrigues/rix";
      branchName = "master";
      rev = "b4501842723ef19391c7653e0b44a487505d89f2";
      sha256 = "sha256-pQdRKxzNhDPPWW1T9oaQEtkLTdmU0+Ry0aGzEGfeYFo=";
    };
    propagatedBuildInputs = builtins.attrValues {
      inherit (pkgs.rPackages) httr jsonlite sys;
    };
  }) ];
  system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocales nix;
};
  in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
    LANG = en_US.UTF-8;
    LC_ALL = en_US.UTF-8;
    LC_TIME = en_US.UTF-8;
    LC_MONETARY = en_US.UTF-8;
    LC_PAPER = en_US.UTF-8
    buildInputs = [ git_archive_pkgs   system_packages  ];
      shellHook = "R --vanilla";
  }
