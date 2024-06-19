#' get_latest Get the latest R version and packages
#' @param r_version Character. R version to look for, for example, "4.2.0". If a nixpkgs revision is provided instead, this gets returned.
#' @return A character. The commit hash of the latest nixpkgs-unstable revision
#' @importFrom httr content GET stop_for_status
#' @importFrom jsonlite fromJSON
#' @importFrom curl has_internet
#'
#' @noRd
get_latest <- function(r_version) {

  is_online <- has_internet()

  stopifnot("r_version has to be a character." = is.character(r_version))

  # If the use provides a commit, then the commit gets used.
  # User needs to know which repo it belongs to
  if(nchar(r_version) == 40){
    return(r_version)
  } else if(
           !(r_version %in% c("bleeding_edge", "frozen_edge", available_r()))
         ){
    stop("The provided R version is likely wrong.\nPlease check that you provided a correct R version.\nYou can list available versions using `available_r()`.\nYou can also directly provide a commit, but you need to make sure it points to the right repo used by `rix()`.\nYou can also use 'bleeding_edge' and 'frozen_edge'.")
  } else if(!is_online){
    stop("ERROR! You don't seem to be connected to the internet.")
  } else if(r_version == "bleeding_edge"){
    latest_commit <- "refs/heads/r-daily"
  } else {
    latest_commit <- get_right_commit(r_version)
  }
  latest_commit
}


#' @noRd
get_right_commit <- function(r_version) {

  if(r_version == "frozen_edge"){
    api_url <- "https://api.github.com/repos/rstats-on-nix/nixpkgs/commits?sha=r-daily"

  } else if(r_version %in% Filter(function(x)`!=`(x, "latest"), available_r())){ #all but latest
    temp <- new.env(parent = emptyenv())

    data(list = "r_nix_revs",
         package = "rix",
         envir = temp)

    get("r_nix_revs", envir = temp)

    return(r_nix_revs$revision[r_nix_revs$version == r_version])

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
