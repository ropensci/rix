#' Return data frame with R, Bioc versions and supported platforms
#' @return A data frame
#' @export
#'
#' @examples
#' available_dates()
available_df <- function() {
  available_df_url <- "https://github.com/ropensci/rix/blob/main/inst/extdata/available_df.csv"

  read.csv(available_df_url)
}

#' List available R versions from the rstats-on-nix fork of Nixpkgs
#' @return A character vector containing the available R versions.
#'
#' @examples
#' available_r()
available_r <- function() {
  r_versions <- unique(available_df()$`R.version`)
  c("latest-upstream", r_versions)
}

#' List available dates.
#' @return A character vector containing the available dates
#'
#' @examples
#' available_dates()
available_dates <- function() {
  unique(available_df()$date)
}
