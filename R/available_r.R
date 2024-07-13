#' List available R versions from Nixpkgs
#' @return A character vector containing the available R versions.
#' @export
#'
#' @examples
#' available_r()
available_r <- function() {
  c("latest", sysdata$version)
}
