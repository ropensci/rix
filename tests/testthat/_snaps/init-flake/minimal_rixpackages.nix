pkgs:

{
  rpkgs = with pkgs.rPackages; [
      dplyr
      ggplot2
      quarto];

  git_archive_pkgs = [];

  tex = null;

  local_r_pkgs = [];

  pyconf = [];

  jlconf = null;

  system_packages = with pkgs; [
      glibcLocales
      nix
      pandoc
      R
      quarto
      which];

  wrapped_pkgs = null;

  shell = pkgs.mkShell {
    LOCALE_ARCHIVE = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    
    buildInputs = [ rpkgs git_archive_pkgs tex pyconf jlconf local_r_pkgs system_packages wrapped_pkgs ];
    
  };
}
