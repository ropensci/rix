#' get_sri_hash_deps Get the SRI hash of the NAR serialization of a Github repo
#' @param repo_url A character. The URL to the package's Github repository or to the `.tar.gz` package hosted on CRAN.
#' @param branch_name A character. The branch of interest, NULL for archived CRAN packages.
#' @param commit A character. The commit hash of interest, for reproducibility's sake, NULL for archived CRAN packages.
#' @importFrom httr content GET http_error
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
get_sri_hash_deps <- function(repo_url, branch_name, commit) {
  # handle to get error for status code 404
  h <- curl::new_handle(failonerror = TRUE)
  
  url <- paste0(
    "http://git2nixsha.dev:1506/hash?repo_url=",
    repo_url, "&branchName=", branch_name, "&commit=", commit
  )
  
  # extra diagnostics
  extra_diagnostics <- 
    c("\nIf it's a Github repo, check the url, branch name and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number.")
  
  req <- try_get_request(url = url, handle = h,
    extra_diagnostics = extra_diagnostics)
  
  # plumber endpoint delivers list with
  # - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
  # - `deps`: string with R package dependencies separarated by `" "`
  sri_hash_deps_list <- jsonlite::fromJSON(rawToChar(req$content))
  
  return(sri_hash_deps_list)
}
