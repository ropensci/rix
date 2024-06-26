#' Return the sri hash of a path using `nix hash path --sri path` if Nix is available locally
#' @param repo_url URL to Github repository
#' @param branch_name Branch to checkout
#' @param commit Commit hash
nix_hash <- function(repo_url, branch_name, commit) {

  if(grepl("github", repo_url)){
    hash_git(repo_url, branch_name, commit)
  } else if(grepl("cran.*Archive.*", repo_url)){
    hash_cran(repo_url)
  } else {
    stop("repo_url argument is wrong. Please provide an url to a Github repo to install a package from Github, or to the CRAN Archive to install a package from the CRAN archive.")
  }

}

#' Return the sri hash of a CRAN package source using `nix hash path --sri path`
#' @param repo_url URL to CRAN package source
hash_cran <- function(repo_url){

  path_to_folder <- paste0(tempdir(), "repo",
                        paste0(sample(letters, 5), collapse = ""))

  dir.create(path_to_folder)

  path_to_tarfile <- paste0(path_to_folder, "/package.tar.gz")

  path_to_src <- paste0(path_to_folder, "/package_src")

  dir.create(path_to_src)

  download.file(url = repo_url,
                destfile = path_to_tarfile)

  untar(path_to_tarfile, exdir = path_to_src)

  # Compute hash of subfolder
  command <- paste0("nix hash path --sri ", path_to_src, "/*/")

  sri_hash <- system(command, intern = TRUE)

  paths <- list.files(path_to_src, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

  unlink(path_to_folder, recursive = TRUE, force = TRUE)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps)
  )

      }

#' Return the sri hash of a Github repository
#' @param repo_url URL to Github repository
#' @param branch_name Branch to checkout
#' @param commit Commit hash
#' @importFrom git2r clone checkout
hash_git <- function(repo_url, branch_name, commit){

  path_to_repo <- paste0(tempdir(), "repo",
                         paste0(sample(letters, 5), collapse = ""))

  git2r::clone(
           url = repo_url,
           local_path = path_to_repo,
           branch = branch_name,
           progress = FALSE
         )

  git2r::checkout(path_to_repo, branch = commit)

  unlink(paste0(path_to_repo, "/.git"), recursive = TRUE, force = TRUE)

  command <- paste0("nix hash path --sri ", path_to_repo)

  sri_hash <- system(command, intern = TRUE)

  paths <- list.files(path_to_repo, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

  unlink(path_to_repo, recursive = TRUE, force = TRUE)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps)
  )
}


#' Get the SRI hash of the NAR serialization of a Github repo, if nix is not available locally
#' @param repo_url A character. The URL to the package's Github repository or to the `.tar.gz` package hosted on CRAN.
#' @param branch_name A character. The branch of interest, NULL for archived CRAN packages.
#' @param commit A character. The commit hash of interest, for reproducibility's sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
nix_hash_online <- function(repo_url, branch_name, commit) {
  # handle to get error for status code 404
  h <- curl::new_handle(failonerror = TRUE)

  url <- paste0(
    "http://git2nixsha.dev:1506/hash?repo_url=",
    repo_url, "&branchName=", branch_name, "&commit=", commit
  )

  # extra diagnostics
  extra_diagnostics <- c("SRI hash of the NAR serialization could not be",
    "computed via git2nixsha.dev API endpoint.")

  req <- try_get_request(
    url = url, handle = h,
    extra_diagnostics = extra_diagnostics
  )

  # plumber endpoint delivers list with
  # - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
  # - `deps`: string with R package dependencies separated by `" "`
  sri_hash_deps_list <- jsonlite::fromJSON(rawToChar(req$content))

  return(sri_hash_deps_list)
}

#' Return the sri hash of a path using `nix hash path --sri path` either with local Nix, or using an online service if Nix is not available
#' @param repo_url A character. The URL to the package's Github repository or to the `.tar.gz` package hosted on CRAN.
#' @param branch_name A character. The branch of interest, NULL for archived CRAN packages.
#' @param commit A character. The commit hash of interest, for reproducibility's sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
get_sri_hash_deps <- function(repo_url, branch_name, commit) {

  if(nix_shell_available()){
    nix_hash(repo_url, branch_name, commit)
  } else {
    nix_hash_online(repo_url, branch_name, commit)
  }

}
