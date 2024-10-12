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

#' renv2nix
#'
#' @param renv_lock_path location of the renv.lock file, defaults to "renv.lock"
#' @param return_rix_call return the generated rix function call instead of
#' evaluating it this is for debugging purposes, defaults to FALSE
#' @param ... any other paramters to pass to [rix]
#'
#' @return nothing side effects only
#' @export
#'
renv2nix <- function(
    renv_lock_path = "renv.lock", return_rix_call = FALSE, ...

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
    git_pkgs <- NULL
    local_r_pkgs <- NULL
    # remotes package supports these types
    # github (is assumed) gitlab,bitbucket, git, local, svn, url, version, cran, bioc.
    # may need handling for ssh and any other support non https protocols?
    if (any(!repo_pkgs_lgl)) {
        for (x in renv_lock$Packages[!repo_pkgs_lgl]) {
            if (x$RemoteType == "github") {
                git_pkgs[[x$Package]] <- list(
                    package_name = x$Package,
                    repo_url = paste0(
                        # RemoteHost is listed as api.github.com for some reason
                        "https://github.com/", x$RemoteUser, "/",
                        x$RemoteRepo
                    ),
                    commit = x$RemoteSha
                )
            #  this may work with other git remotes and possibly also bitbucket / svn needs checking
            } else if (x$RemoteType == "gitlab") {
                git_pkgs[[x$Package]] <- list (
                    package_name = x$Package,
                    repo_url = paste0(
                        "https://", x$RemoteHost, "/", x$RemoteUser, "/",
                        x$RemoteRepo
                    ),
                    commit = x$RemoteSha
                )
            }
            # as local_r_pkgs expects an archive not sure how to set type here..
            #  else if (x$RemoteType == "local") else {
            #      local_r_pkgs[[x$Package]] <- c(
            #          package_name = paste0(x$RemoteUrl, "/", x$Package, ".tar.gz")
            #      )
            #  }
        }
    }
    rix_call <- call("rix",
        r_ver = renv_lock$R$Version,
        r_pkgs = names(renv_lock$Packages[repo_pkgs_lgl]),
        git_pkgs = git_pkgs,
        local_r_pkgs = local_r_pkgs
    )
    dots <- list(...)
    for(arg in names(dots)) {
        rix_call[[arg]] <- dots[[arg]]
    }

    if (return_rix_call) {
        # print(rix_call)
        # return(deparse(substitute(rix_call)))
        return(rix_call)
    }
    eval(rix_call)
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

