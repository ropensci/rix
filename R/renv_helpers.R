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
        stop(renv_lock_path," does not exist!")
    }
    tryCatch(
        renv_lock <- jsonlite::read_json(renv_lock_path),
        error = function(e) {
            stop("Error reading renv.lock file\n", e)
        }
    )
    renv_lock
}

#' renv_lock_pkgs
#'
#' gets the names of all the packages in an renv.lock file
#'
#' This does NOT get the versions of those packages or handle transitive
#' dependencies in the renv.lock file not directly used in the project.
#' It simply returns a vector of all the package names.
#'
#' @param renv_lock_path location of the renv.lock file from which to get the
#' list of packages, defaults to "renv.lock"
#' @param exclude_other_sources exclude packages not from Repository sources
#' such as those from github repositories, defaults to TRUE. These are likely
#' to not yet be packaged in nix.
#'
#' @return a character vector of all the package names listed in the renv.lock
#' file proved in renv_lock_path.
#'
#' @export
#'
#' @examples
#'
#' rix(r_pkgs = renv_lock_pkgs())
#'
renv_lock_pkgs <- function(
        renv_lock_path = "renv.lock", exclude_other_sources = TRUE
    ) {
    renv_lock <- read_renv_lock(renv_lock_path = renv_lock_path)
    repo_pkgs_lgl <- logical(length = length(renv_lock$Packages))
    for (i in seq_along(renv_lock$Packages)) {
        if (renv_lock$Packages[[i]]$Source == "Repository") {
            repo_pkgs_lgl[i] <- TRUE
        } else {
            repo_pkgs_lgl[i] <- FALSE
        }
    }
    if (any(!repo_pkgs_lgl)) {
        # note
        # When a development version of a package that might be available in
        # in other versions in nix in installed from github this approach
        # excludes such packages
        warning(
            "found packages with a Source other than Repository",
            ", These will be excluded\nExcluding: ",
            paste(names(renv_lock$Packages[!repo_pkgs_lgl]), collapse = ", ")
        )
    }
    names(renv_lock$Packages[repo_pkgs_lgl])
}

#' renv_lock_r_ver
#'
#' @param renv_lock_path location of the renv.lock file from which to get the
#' R version, defaults to "renv.lock"
#'
#' @return a length 1 chatacter vector with the version of R recorded in
#'  renv.lock
#'
#' @export
#'
#' @examples
#'
#' rix(r_ver = renv_lock_r_ver())
#'
renv_lock_r_ver <- function(renv_lock_path = "renv.lock") {
    renv_lock <- read_renv_lock(renv_lock_path = renv_lock_path)
    renv_lock$R$Version
}

