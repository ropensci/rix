#' detect_versions Detects if CRAN packages need to be downloaded from the
#' archive.
#' @param r_pkgs A list of packages, to get from CRAN (either current packages
#'   or archived packages).
#' @return A list of two elements, "cran_packages" and "archive_packages"
#' @noRd
detect_versions <- function(r_pkgs) {
  if (any(grepl("@", r_pkgs))) {
    cran_packages <- Filter(function(x) (!grepl("@", x)), r_pkgs)
    archive_packages <- Filter(function(x) (grepl("@", x)), r_pkgs)

    # then concatenate cran_packages and r_pkgs
    # and archive_packages and git_pkgs
    # fetchgit will handle redirecting git_pkgs to nix.fetchgit
    # and archive_packges to nix.fetchzip
    output <- list(
      "cran_packages" = cran_packages,
      "archive_packages" = archive_packages
    )
  } else {
    output <- list(
      "cran_packages" = r_pkgs,
      "archive_packages" = NULL
    )
  }

  output
}
