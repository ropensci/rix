#' List available R versions from Nixpkgs
#' @return A character vector containing the available R versions.
#' @export
#'
#' @examples
#' available_r()
available_r <- function() {
  c("latest", sysdata$version)
}

#' List available dates.
#' @return A character vector containing the available dates
#' @export
#'
#' @examples
#' available_dates()
available_dates <- function() {
  list(
    "year" = c(rep("2021", 4), rep("2022", 6), rep("2023", 6), rep("2024", 4)),
    "R version" = c("4.0.5", "4.1.0", "4.1.0", "4.1.1",
                    "4.1.2", "4.1.3", "4.2.0", "4.2.1", "4.2.1", "4.2.2",
                    "4.2.2", "4.2.3", "4.3.0", "4.3.1", "4.3.1", "4.3.2",
                    "4.3.3", "4.4.0", "4.4.1", "4.4.1"),
    "date" = c("2021-04-01",
               "2021-05-29",
               "2021-08-03",
               "2021-10-28",
               "2022-01-16",
               "2022-04-19",
               "2022-06-22",
               "2022-08-22",
               "2022-10-20",
               "2022-12-20",
               "2023-02-13",
               "2023-04-01",
               "2023-06-15",
               "2023-08-15",
               "2023-10-30",
               "2023-12-30",
               "2024-02-29",
               "2024-04-29",
               "2024-06-14",
               "2024-10-01"
               )
  ) |>
    as.data.frame()
}
