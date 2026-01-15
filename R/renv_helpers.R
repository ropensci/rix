#' read_renv_lock
#'
#' Reads renv.lock if it exists and can be parsed as json.
#'
#' @param renv_lock_path location of the renv.lock file, defaults to "renv.lock"
#'
#' @return the result of reading renv.lock with [jsonlite::read_json]
#'
#' @importFrom jsonlite read_json
#' @keywords internal
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

#' renv_remote_pkgs
#'
#' Construct a list to be passed the git_pkgs argument of [rix]
#' The list returned contains the information necessary to have nix attempt to
#' build the packages from their external repositories.
#'
#' @param renv_lock_remote_pkgs the list of package information from an renv.lock file.
#' @param host the host of remote package, defaults to NULL meaning the RemoteHost of the
#' renv entry will be used.
#' currently supported hosts: 'api.github.com' 'gitlab.com'
#' see [remotes](https://remotes.r-lib.org/) for more.
#'
#' @return a list of lists with three elements named:
#'  "package_name", "repo_url", "commit"
#'
#' @examples
#' \dontrun{
#' renv_remote_pkgs(read_renv_lock()$Packages)
#' }
#' @keywords internal
renv_remote_pkgs <- function(
  renv_lock_remote_pkgs,
  host = NULL
) {
  # , "bitbucket", "git", "local", "svn", "url", "version", "cran", "bioc"
  supported_pkg_hosts <- c("api.github.com", "gitlab.com")
  if (!(is.null(host) || (host %in% supported_pkg_hosts))) {
    stop("Unsupported remote host: ", host)
  }
  initial_host_state <- host
  git_pkgs <- vector(mode = "list", length = length(renv_lock_remote_pkgs))
  names(git_pkgs) <- names(renv_lock_remote_pkgs)
  for (i in seq_along(renv_lock_remote_pkgs)) {
    renv_lock_pkg_info <- renv_lock_remote_pkgs[[i]]
    if (is.null(host)) {
      if (is.null(renv_lock_pkg_info$RemoteHost)) {
        stop(
          "Not a package installed from a remote outside of the main package repositories\n",
          "renv_remote_pkgs() only handles pkgs where RemoteHost is specified"
        )
      } else if (renv_lock_pkg_info$RemoteHost %in% supported_pkg_hosts) {
        host <- renv_lock_pkg_info$RemoteHost
      } else {
        stop(
          renv_lock_pkg_info$Package,
          " has unsupported remote host: ",
          renv_lock_pkg_info$RemoteHost,
          "\nSupported hosts are: ",
          paste0(supported_pkg_hosts, collapse = ", ")
        )
      }
    } else {
      if (host != renv_lock_pkg_info$RemoteHost) {
        stop(
          "Remote host (",
          renv_lock_pkg_info$RemoteHost,
          ") of ",
          renv_lock_pkg_info$Package,
          " does not match the provided host (",
          host,
          ")"
        )
      }
    }

    pkg_info <- vector(mode = "list", length = 3)
    names(pkg_info) <- c("package_name", "repo_url", "commit")
    switch(
      host,
      "api.github.com" = {
        pkg_info[[1]] <- renv_lock_pkg_info$Package
        pkg_info[[2]] <- paste0(
          # RemoteHost is listed as api.github.com for some reason
          "https://github.com/",
          renv_lock_pkg_info$RemoteUser,
          "/",
          renv_lock_pkg_info$RemoteRepo
        )
        pkg_info[[3]] <- renv_lock_pkg_info$RemoteSha
      },
      "gitlab.com" = {
        pkg_info[[1]] <- renv_lock_pkg_info$Package
        pkg_info[[2]] <- paste0(
          "https://",
          renv_lock_pkg_info$RemoteHost,
          "/",
          renv_lock_pkg_info$RemoteUser,
          "/",
          renv_lock_pkg_info$RemoteRepo
        )
        pkg_info[[3]] <- renv_lock_pkg_info$RemoteSha
      }
    )
    host <- initial_host_state
    git_pkgs[[i]] <- pkg_info
  }
  git_pkgs
}

#' renv2nix
#'
#' @param renv_lock_path Character, path of the renv.lock file, defaults to
#'   "renv.lock"
#' @param project_path Character, where to write `default.nix`, for example
#'   "/home/path/to/project". The file will thus be written to the file
#'   "/home/path/to/project/default.nix". If the folder does not exist, it will
#'   be created.
#' @param return_rix_call Logical, return the generated rix function call
#'   instead of evaluating it this is for debugging purposes, defaults to
#'   `FALSE`
#' @param method Character, the method of generating a nix environment from an
#'   renv.lock file. "fast" is an inexact conversion which simply extracts the R
#'   version and a list of all the packages in an renv.lock file and adds them
#'   to the `r_pkgs` argument of `rix()`. This will use a snapshot of `nixpkgs`
#'   that should contain package versions that are not too different from the
#'   ones defined in the `renv.lock` file. For packages installed from GitHub or
#'   similar, an attempt is made to handle them and pass them to the `git_pkgs`
#'   argument of `rix()`. Currently defaults to "fast", "accurate" is not yet
#'   implemented.
#' @param override_r_ver Character, defaults to NULL, override the R version
#'   defined in the `renv.lock` file with another version. This is especially
#'   useful if the `renv.lock` file lists a version of R not (yet) available
#'   through Nix, or if the R version included in the `renv.lock` is too old
#'   compared to the package versions. Can also be a date, check
#'   `available_dates()`.
#' @inheritDotParams rix system_pkgs local_r_pkgs:shell_hook
#'
#' @return Nothing, this function is called for its side effects only, unless
#'   `return_rix_call = TRUE` in which case an unevaluated call to `rix()` is
#'   returned
#' @details In order for this function to work properly, we recommend not
#'   running it inside the same folder as an existing `{renv}` project. Instead,
#'   run it from a new, empty directory which path you pass to `project_path`,
#'   and use `renv_lock_path` to point to the `renv.lock` file in the original
#'   `{renv}` folder. We recommend that you start from an empty folder to hold
#'   your new Nix project, and copy the `renv.lock` file only (not any of the
#'   other files and folders generated by `{renv}`) and then call `renv2nix()`
#'   there. For more details, see `vignette("f-renv2nix")`.
#' @export
#' @examples
#' \dontrun{
#' # if the lock file is in another folder
#' renv2nix(
#'   renv_lock_path = "path/to/original/renv_project/renv.lock",
#'   project_path = "path/to/rix_project"
#' )
#' # you could also copy the renv.lock file in the folder of the Nix
#' # project (don’t copy any other files generated by `{renv}`)
#' renv2nix(
#'   renv_lock_path = "path/to/rix_project/renv.lock",
#'   project_path = "path/to/rix_project"
#' )
#' }
#'
renv2nix <- function(
  renv_lock_path = "renv.lock",
  project_path,
  return_rix_call = FALSE,
  method = c("fast", "accurate"),
  override_r_ver = NULL,
  ...
) {
  method <- match.arg(method, c("fast", "accurate"))
  renv_lock <- read_renv_lock(renv_lock_path = renv_lock_path)
  if (method == "fast") {
    repo_pkgs <- list()
    remote_pkgs <- list()
    # unsupported_pkgs <- list()
    renv_lock_pkg_names <- names(renv_lock$Packages)
    for (i in seq_along(renv_lock$Packages)) {
      if (renv_lock$Packages[[i]]$Source %in% c("Repository", "Bioconductor")) {
        repo_pkgs[[renv_lock_pkg_names[i]]] <- renv_lock$Packages[[i]]
      } else if (
        renv_lock$Packages[[i]]$RemoteHost %in%
          c("api.github.com", "gitlab.com")
      ) {
        remote_pkgs[[renv_lock_pkg_names[i]]] <- renv_lock$Packages[[i]]
      } else {
        # unsupported_pkgs[[renv_lock_pkg_names[i]]] <- renv_lock$Packages[[i]]
        warning(
          renv_lock$Packages[[i]]$Package,
          " has the unsupported remote host ",
          renv_lock$Packages[[i]]$RemoteHost,
          " and will not be included in the Nix expression.",
          "\n Consider manually specifying the git remote or a local package install."
        )
      }
    }
    git_pkgs <- NULL
    # as local_r_pkgs expects an archive not sure how to set host here..
    # local_r_pkgs <- NULL
    if (length(remote_pkgs) > 0) {
      git_pkgs <- renv_remote_pkgs(remote_pkgs)
    }
    r_version <- renv_lock_r_ver(
      renv_lock = renv_lock,
      override_r_ver = override_r_ver
    )
    if (grepl("^\\d{4}-\\d{2}-\\d{2}$", r_version)) {
      rix_call <- call(
        "rix",
        date = r_version,
        r_pkgs = names(repo_pkgs),
        git_pkgs = git_pkgs,
        project_path = project_path
        # local_r_pkgs = local_r_pkgs
      )
    } else {
      rix_call <- call(
        "rix",
        r_ver = r_version,
        r_pkgs = names(repo_pkgs),
        git_pkgs = git_pkgs,
        project_path = project_path
        # local_r_pkgs = local_r_pkgs
      )
    }
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
      "The 'accurate' method to generate Nix expressions with exact package versions",
      "matching the ones in the `renv.lock` file is not yet implemented."
    )
  }
}

#' renv_lock_r_ver
#'
#' @param renv_lock renv.lock file from which to get the R version
#' @param override_r_ver Character, override the R version defined in the
#'   `renv.lock` file with another version. This is especially useful if
#'   the `renv.lock` file lists a version of R not (yet) available through Nix.
#'   Can also be a date.
#'
#' @return a length 1 character vector with the version of R recorded in
#'  renv.lock
#'
#' @examples
#' \dontrun{
#' rix(r_ver = renv_lock_r_ver())
#' }
#' @keywords internal
renv_lock_r_ver <- function(renv_lock, override_r_ver = NULL) {
  if (is.null(override_r_ver)) {
    renv_lock$R$Version
  } else {
    override_r_ver
  }
}
