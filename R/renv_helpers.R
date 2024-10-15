#' read_renv_lock
#'
#' Reads renv.lock if it exists and can be parsed as json.
#'
#' @param renv_lock_path location of the renv.lock file, defaults to "renv.lock"
#'
#' @return the result of reading renv.lock with [jsonlite::read_json]
#'
#' @importFrom jsonlite read_json
read_renv_lock <- function(renv_lock_path = "renv.lock") {
  if (!file.exists(renv_lock_path)) {
    stop(renv_lock_path, " does not exist!")
  }
  tryCatch(
    renv_lock <- jsonlite::read_json(renv_lock_path),
    error = function(e) {
      stop("Error reading renv.lock file\n", e)
    }
  )
  renv_lock
}

#' renv_remote_pkg
#'
#' Construct a list to be passed in a list to the git_pkgs argument of [rix]
#' The list returned contains the information necessary to have nix attempt to
#' build the package from an external repository.
#'
#' @param renv_lock_pkg_info a the list representation of a single package
#' entry from an renv.lock file.
#' @param type the type of remote package, defaults to the RemoteType of the
#' renv entry.
#' currently supported types: 'github' 'gitlab'
#' see [remotes](https://remotes.r-lib.org/) for more.
#'
#' @return a list with three elements named:
#'  "package_name", "repo_url", "commit"
#'
#' @examples
#' \dontrun{
#' renv_remote_pkgs(read_renv_lock()$Packages$renv)
#' }
renv_remote_pkg <- function(
    renv_lock_pkg_info,
    type = renv_lock_pkg_info$RemoteType) {
  type <- match.arg(type, c(
    "github", "gitlab"
    # , "bitbucket", "git", "local", "svn", "url", "version", "cran", "bioc"
  ))
  pkg_info <- vector(mode = "list", length = 3)
  names(pkg_info) <- c("package_name", "repo_url", "commit")
  switch(type,
    "github" = {
      pkg_info[[1]] <- renv_lock_pkg_info$Package
      pkg_info[[2]] <- paste0(
        # RemoteHost is listed as api.github.com for some reason
        "https://github.com/", renv_lock_pkg_info$RemoteUser, "/",
        renv_lock_pkg_info$RemoteRepo
      )
      pkg_info[[3]] <- renv_lock_pkg_info$RemoteSha
    },
    "gitlab" = {
      pkg_info[[1]] <- renv_lock_pkg_info$Package
      pkg_info[[2]] <- paste0(
        "https://", renv_lock_pkg_info$RemoteHost, "/",
        renv_lock_pkg_info$RemoteUser, "/",
        renv_lock_pkg_info$RemoteRepo
      )
      pkg_info[[3]] <- renv_lock_pkg_info$RemoteSha
    }
  )
  pkg_info
}

#' renv_remote_pkgs
#'
#' Construct a list to be passed the git_pkgs argument of [rix]
#' The list returned contains the information necessary to have nix attempt to
#' build the packages from their external repositories.
#'
#' @param renv_lock_pkgs the list of package information from an renv.lock file.
#'
#' @return a list of lists with three elements named:
#'  "package_name", "repo_url", "commit"
#'
#' @examples
#' \dontrun{
#' renv_remote_pkgs(read_renv_lock()$Packages)
#' }
renv_remote_pkgs <- function(renv_lock_pkgs) {
  lapply(renv_lock_pkgs, renv_remote_pkg)
}

#' renv2nix
#'
#' @param renv_lock_path location of the renv.lock file, defaults to "renv.lock"
#' @param return_rix_call return the generated rix function call instead of
#' evaluating it this is for debugging purposes, defaults to FALSE
#' @param method the method of generating a nix environment from and renv.lock file.
#' "fast" is an inexact conversion which simply extracts the R version and a list of all the
#' packages in an renv.lock file and adds them to the `r_pkgs` argument of [rix], unless they
#' are from external package repositories such as being installed directly from a github
#' repository in which case an attempt is made to handle them and pass them to the
#' `git_pkgs` argument of [rix]
#'
#' Currently defaults to "fast", "accurate" is not yet implemented
#' @param ... any other parameters to pass to [rix]
#'
#' @return nothing side effects only, unless `return_rix_call = TRUE` in which case an unevaluated
#' call to the [rix] function is returned
#' @export
#'
renv2nix <- function(
    renv_lock_path = "renv.lock",
    return_rix_call = FALSE,
    method = c("fast", "accurate"),
    ...) {
  method <- match.arg(method, c("fast", "accurate"))
  renv_lock <- read_renv_lock(renv_lock_path = renv_lock_path)
  if (method == "fast") {
    repo_pkgs_lgl <- logical(length = length(renv_lock$Packages))
    for (i in seq_along(renv_lock$Packages)) {
      if (renv_lock$Packages[[i]]$Source == "Repository") {
        repo_pkgs_lgl[i] <- TRUE
      } else {
        repo_pkgs_lgl[i] <- FALSE
      }
    }
    git_pkgs <- NULL
    # as local_r_pkgs expects an archive not sure how to set type here..
    # local_r_pkgs <- NULL
    if (any(!repo_pkgs_lgl)) {
      git_pkgs <- renv_remote_pkgs(renv_lock$Packages[!repo_pkgs_lgl])
    }
    rix_call <- call("rix",
      r_ver = renv_lock$R$Version,
      r_pkgs = names(renv_lock$Packages[repo_pkgs_lgl]),
      git_pkgs = git_pkgs # ,
      # local_r_pkgs = local_r_pkgs
    )
    dots <- list(...)
    for (arg in names(dots)) {
      rix_call[[arg]] <- dots[[arg]]
    }

    if (return_rix_call) {
      # print(rix_call)
      return(rix_call)
    }
    eval(rix_call)
  } else {
    stop(
      "'accurate' renv based environments with package version matching",
      " is not yet implemented :("
    )
  }
}

#' renv_lock_r_ver
#'
#' @param renv_lock_path location of the renv.lock file from which to get the
#' R version, defaults to "renv.lock"
#'
#' @return a length 1 character vector with the version of R recorded in
#'  renv.lock
#'
#' @examples
#'
#' rix(r_ver = renv_lock_r_ver())
#'
renv_lock_r_ver <- function(renv_lock_path = "renv.lock") {
  renv_lock <- read_renv_lock(renv_lock_path = renv_lock_path)
  renv_lock$R$Version
}
