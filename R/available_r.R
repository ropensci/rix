#' Return Data Frame with R, Bioc Versions and Supported Platforms
#' @return A data frame with columns:
#' - `year`: character
#' - `R.version`: character; e.g., `"3.5.3"``
#' - `bioc_version`: character; Bioconducotr version, e.g., `"3.22"`
#' - `date`: character; in format `<yyyy>-<mm>-<dd>`
#' - `Linux/wsl`: character; `"supported"`, `"unsupported"`, or `"might work"``
#' - `Apple Silicon`: character; `"supported"`, `"unsupported"`, `"might work"`,
#'   or `"supported (Rstudio broken)"`
#' - `Intel Mac`: character; `"supported"`, `"unsupported"`, or `"might work"``
#' @family available versions
#' @export
#' @importFrom utils read.csv
#'
#' @examples
#' available_dates()
available_df <- function() {
  # nolint start: line_length_linter
  available_df_url <- "https://raw.githubusercontent.com/ropensci/rix/refs/heads/main/inst/extdata/available_df.csv"
  # nolint end

  read.csv(available_df_url)
}

#' List Available R Versions from the rstats-on-nix Fork of Nixpkgs
#' @return A character vector containing the available R versions.
#' @family available versions
#' @export
#'
#' @examples
#' available_r()
available_r <- function() {
  r_versions <- unique(available_df()$`R.version`)
  c(
    "bleeding-edge",
    "frozen-edge",
    "r-devel",
    "bioc-devel",
    "r-devel-bioc-devel",
    "latest-upstream",
    r_versions
  )
}

#' List Available Dates for R and Bioconductor Releases
#' @return A character vector containing the available dates
#' @family available versions
#' @export
#'
#' @examples
#' available_dates()
available_dates <- function() {
  unique(available_df()$date)
}

#' Get Latest R Version for Given Date
#' @param date Character, one of the available dates.
#' @return A character vector showing the version for a given date
#' @noRd
#'
get_version_from_date <- function(date) {
  available_df <- available_df()
  available_df$`R.version`[available_df$date == date]
}

#' Get Latest Most Recent Date for Given R Version
#' @param date Character, one of the available r versions.
#' @return A character vector showing the version for a given date
#' @noRd
#'
get_date_from_version <- function(r_version) {
  available_df <- available_df()
  max(available_df$date[available_df$`R.version` == r_version])
}
