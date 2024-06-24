#' List available R versions from Nixpkgs
#' @return A character vector containing the available R versions.
#' @export
#'
#' @examples
#' available_r()
available_r <- function() {
  temp <- new.env(parent = emptyenv())

  data(list = "sysdata",
       package = "rix",
       envir = temp)

  get("sysdata", envir = temp)

  c("latest", sysdata$version)
}
