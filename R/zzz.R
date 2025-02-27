#' zzz Global imports
#' @noRd
#' @importFrom utils data
utils::globalVariables(c("sysdata", "is_internet_down", "type", "package"))

#' @noRd
.onAttach <- function(libname, pkgname) {
  if (!nix_build_installed()) {
    packageStartupMessage(
      "Nix is not installed on this system.
You cannot generate expressions that include packages hosted on GitHub, GitLab or
from the CRAN archives using the `pkg@version` notation.
To proceed, install Nix or use a system where it is available."
    )
  }

  nix_conf_path <- "~/.config/nix/nix.conf"

  if (
    nix_conf_exists(nix_conf_path) &&
      !is_cachix_configured(readLines(nix_conf_path))
  ) {
    packageStartupMessage(
      "To speed up the build process of your development environments,
configure the rstats-on-nix binary repository! Read the `Getting started`
vignette for instructions see
https://docs.ropensci.org/rix/articles/a-getting-started.html#installing-and-configuring-nix
(you only need to do this once per machine you use {rix} on)."
    )
  }

  if (!nix_conf_exists(nix_conf_path) && nix_build_installed()) {
    packageStartupMessage(
      "To speed up the build process of your development environments,
configure the rstats-on-nix binary repository! Read the `Getting started`
vignette for instructions see
https://docs.ropensci.org/rix/articles/a-getting-started.html#installing-and-configuring-nix
(you only need to do this once per machine you use {rix} on)."
    )
  }
}
