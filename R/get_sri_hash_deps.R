#' get_sri_hash_deps Get the SRI hash of the NAR serialization of a Github repo
#' @param repo_url A character. The URL to the package's Github repository or to the `.tar.gz` package hosted on CRAN.
#' @param branch_name A character. The branch of interest, NULL for archived CRAN packages.
#' @param commit A character. The commit hash of interest, for reproducibility's sake, NULL for archived CRAN packages.
#' @importFrom httr content GET http_error
#' @return The SRI hash as a character
#' @noRd
get_sri_hash_deps <- function(repo_url, branch_name, commit){
  result <- httr::GET(paste0("http://git2nixsha.dev:1506/hash?repo_url=",
                             repo_url,
                             "&branchName=",
                             branch_name,
                             "&commit=",
                             commit))

  if(http_error(result)){
    stop(paste0("Error in pulling URL: ", repo_url, ". If it's a Github repo, check the url, branch name and commit. Are these correct? If it's an archived CRAN package, check the name of the package and the version number."))
  }


  lapply(httr::content(result), unlist)

}
