#' Return data frame with R, Bioc versions and supported platforms
#' @return A data frame
#' @export
#'
#' @examples
#' available_dates()
available_df <- function() {
  # nolint start: line_length_linter
  available_df_url <- "https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv"
  # nolint end

  read.csv(available_df_url)
}

#' List available R versions from the rstats-on-nix fork of Nixpkgs
#' @return A character vector containing the available R versions.
#' @export
#'
#' @examples
#' available_r()
available_r <- function() {
  r_versions <- unique(available_df()$`R.version`)
  c("latest-upstream", r_versions)
}

#' List available dates.
#' @return A character vector containing the available dates
#' @export
#'
#' @examples
#' available_dates()
available_dates <- function() {
  unique(available_df()$date)
}

#' Get latest R version for given date
#' @return A character vector showing the version for a given date
#'
get_version_from_date <- function(date) {
  available_df <- available_df()
  available_df$`R.version`[available_df$date == date]
}

#' Get latest most recent date for given R version
#' @return A character vector showing the version for a given date
#'
get_date_from_version <- function(r_version) {
  available_df <- available_df()
  max(available_df$date[available_df$`R.version` == r_version])
}
