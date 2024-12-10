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
don't forget to run `setup_cachix()`!")
  }
}
