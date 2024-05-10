let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/refs/heads/r-daily.tar.gz") {};
 system_packages = builtins.attrValues {
  inherit (pkgs) R glibcLocalesUtf8 pandoc nix;
};
 r_packages = builtins.attrValues {
  inherit (pkgs.rPackages) devtools fledge fusen codetools jsonlite httr sys testthat knitr rmarkdown;
};
  tex = (pkgs.texlive.combine {
  inherit (pkgs.texlive) scheme-small;
});
  in
  pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then  "${pkgs.glibcLocalesUtf8}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";

    buildInputs = [ system_packages r_packages tex];

  }
