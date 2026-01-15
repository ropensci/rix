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
      "To speed up builds, configure the rstats-on-nix cache by running:
  rix::setup_cachix()
See vignette(\"b1-setting-up-and-using-rix-on-linux-and-windows\") or
vignette(\"b2-setting-up-and-using-rix-on-macos\") for full instructions.
(You only need to do this once per machine.)"
    )
  }

  if (!nix_conf_exists(nix_conf_path) && nix_build_installed()) {
    packageStartupMessage(
      "To speed up builds, configure the rstats-on-nix cache by running:
  rix::setup_cachix()
See vignette(\"b1-setting-up-and-using-rix-on-linux-and-windows\") or
vignette(\"b2-setting-up-and-using-rix-on-macos\") for full instructions.
(You only need to do this once per machine.)"
    )
  }
}
