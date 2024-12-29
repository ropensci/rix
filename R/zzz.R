#' zzz Global imports
#' @noRd
#' @importFrom utils data
utils::globalVariables(c("sysdata", "is_internet_down", "type", "package"))

#' @noRd
.onLoad <- function(libname, pkgname) {
  if (!nix_build_installed()) {
    message("Nix doesn't seem to be installed on this system.
You can still generate Nix expressions, but you won't be able to build them.")
  }

  nix_conf_path <- "~/.config/nix/nix.conf"

  if (nix_conf_exists(nix_conf_path) && !is_cachix_configured(readLines(nix_conf_path))) {
    message("To speed up the build process of your development environments,
configure the rstats-on-nix binary repository! Read the `Getting started`
vignette for instructions (https://docs.ropensci.org/rix/articles/a-getting-started.html#installing-and-configuring-nix).
(you only need to do this once per machine you use {rix} on)")
  }

  if (!nix_conf_exists(nix_conf_path) && nix_build_installed()) {
    message("To speed up the build process of your development environments,
configure the rstats-on-nix binary repository! Read the `Getting started`
vignette for instructions (https://docs.ropensci.org/rix/articles/a-getting-started.html#installing-and-configuring-nix).
(you only need to do this once per machine you use {rix} on)")
  }
}
