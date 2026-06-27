#' make_nixpkgs_url Find the Right Nix Revision
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

    nix_url <- paste0(
      "https://github.com/",
      github_repo,
      "archive/",
      latest_commit,
      ".tar.gz"
    )

    sha256 <- if (grepl("^refs/heads/", latest_commit)) {
      NULL
    } else if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", latest_commit)) {
      df <- available_df()
      if ("sha256" %in% names(df)) {
        sha <- df$sha256[match(latest_commit, df$date)]
        if (is.na(sha)) NULL else sha
      } else {
        NULL
      }
    } else {
      try_get_nix_tarball_hash(nix_url)
    }

    list(
      "url" = nix_url,
      "latest_commit" = latest_commit,
      "r_ver" = r_ver,
      "sha256" = sha256
    )
  } else {
    nix_url <- paste0(
      "https://github.com/rstats-on-nix/nixpkgs/archive/",
      date,
      ".tar.gz"
    )

    df <- available_df()
    sha256 <- if ("sha256" %in% names(df)) {
      sha <- df$sha256[match(date, df$date)]
      if (is.na(sha)) NULL else sha
    } else {
      NULL
    }

    list(
      "url" = nix_url,
      "latest_commit" = date,
      "r_ver" = get_version_from_date(date),
      "sha256" = sha256
    )
  }
}
