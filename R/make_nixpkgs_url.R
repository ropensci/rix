#' make_nixpkgs_url Find the right Nix revision
#' @param r_version Character. R version to look for, for example, "4.2.0". If a
#' nixpkgs revision is provided instead, this gets returned.
#' @param date Character. Snapshot date to use for building env.
#' @return A character. The url to use
#'
#' @examples
#' make_nixpkgs_url("4.2.0")
#' @noRd
make_nixpkgs_url <- function(r_ver = NULL, date = NULL) {
  if (is.null(date)) {
    if (r_ver %in% c("latest-upstream")) {
      github_repo <- "NixOS/nixpkgs/"
    } else {
      github_repo <- "rstats-on-nix/nixpkgs/"
    }

    latest_commit <- get_latest(r_ver)

    list(
      "url" = paste0(
        "https://github.com/",
        github_repo,
        "archive/",
        latest_commit,
        ".tar.gz"
      ),
      "latest_commit" = latest_commit,
      "r_ver" = r_ver
    )
  } else {
    list(
      "url" = paste0(
        "https://github.com/rstats-on-nix/nixpkgs/archive/",
        date,
        ".tar.gz"
      ),
      "latest_commit" = date,
      "r_ver" = get_version_from_date(date)
    )
  }
}
