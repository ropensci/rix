#' make_nixpkgs_url Find the right Nix revision
#' @param r_version Character. R version to look for, for example, "4.2.0". If a
#' nixpkgs revision is provided instead, this gets returned.
#' @return A character. The url to use
#'
#' @examples
#' make_nixpkgs_url("4.2.0")
#' @noRd
make_nixpkgs_url <- function(r_ver) {
  if (r_ver %in% c("bleeding_edge", "frozen_edge")) {
    github_repo <- "rstats-on-nix/nixpkgs/"
  } else {
    github_repo <- "NixOS/nixpkgs/"
  }

  latest_commit <- get_latest(r_ver)

  list(
    "url" = paste0(
      "https://github.com/", github_repo, "archive/", latest_commit, ".tar.gz"
    ),
    "latest_commit" = latest_commit,
    "r_ver" = r_ver
  )
}
