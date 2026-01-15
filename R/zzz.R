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

  # Only show cachix message if Nix is installed but cache is not configured
  if (nix_build_installed() && !is_cachix_configured_anywhere()) {
    packageStartupMessage(
      "To speed up builds, configure the rstats-on-nix cache by running:
  rix::setup_cachix()
See vignette(\"setting-up-linux-windows\") or
vignette(\"setting-up-macos\") for full instructions.
(You only need to do this once per machine.)"
    )
  }
}
