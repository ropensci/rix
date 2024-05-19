#' get_latest Get the latest R version and packages
#' @param r_version Character. R version to look for, for example, "4.2.0". If a nixpkgs revision is provided instead, this gets returned.
#' @return A character. The commit hash of the latest nixpkgs-unstable revision
#' @importFrom httr content GET stop_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom curl has_internet
#'
#' @noRd
get_latest <- function(r_ver) {

  is_online <- has_internet()

  if(!is_online){
    stop("ERROR! You don't seem to be connected to the internet.")
  } else if(r_ver == "bleeding_edge"){
    latest_commit <- "refs/heads/r-daily"
  } else {
    latest_commit <- get_latest_or_frozen(r_ver)
  }
  latest_commit
}

#' @noRd
get_latest_or_frozen <- function(r_ver) {
  if(r_ver == "frozen_edge"){
    api_url <- "https://api.github.com/repos/rstats-on-nix/nixpkgs/commits?sha=r-daily"
  } else {
    api_url <- "https://api.github.com/repos/NixOS/nixpkgs/commits?sha=nixpkgs-unstable"
  }
  tryCatch({
    response <- httr::GET(url = api_url)
    httr::stop_for_status(response)
    commit_data <- jsonlite::fromJSON(httr::content(response, "text"))
    latest_commit <- commit_data$sha[1]
    return(latest_commit)
  }, error = function(e) {
    cat("Error:", e$message, "\n")
    return(NULL)
  })

}
