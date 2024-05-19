#' get_latest Get the latest R version and packages
#' @return A character. The commit hash of the latest nixpkgs-unstable revision
#' @importFrom httr content GET stop_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom curl has_internet
#'
#' @noRd
get_latest <- function() {
  api_url <- "https://api.github.com/repos/NixOS/nixpkgs/commits?sha=nixpkgs-unstable"

  is_online <- has_internet()

  if(!is_online){
    stop("ERROR! You don't seem to be connected to the internet.")
  } else {
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

}
