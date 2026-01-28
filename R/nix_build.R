#' Invoke Shell Command `nix-build` From an R Session
#' @param project_path Path to the folder where the `default.nix` file resides.
#' @param message_type Character vector with messaging type. Either `"simple"`
#' (default), `"quiet"` for no messaging, or `"verbose"`.
#' @param args A character vector of additional arguments to be passed directly to
#'   the `nix-build` command. If the project directory (i.e. `project_path`) is not
#'   included in `args`, it will be appended automatically.
#' @return Integer of the process ID (PID) of the `nix-build` shell command
#'   launched, if the `nix_build()` call is assigned to an R object.
#'   Otherwise, it will be returned invisibly.
#' @details This function is a wrapper for the `nix-build` command-line interface.
#'   Users can supply any flags supported by `nix-build` via the `args` parameter.
#'   If no custom arguments are provided, only the project directory is passed.
#' @importFrom tools pskill
#' @family Nix execution
#' @export
#' @examples
#' \dontrun{
#'   # Run nix-build with default arguments (project directory)
#'   nix_build()
#'
#'   # Run nix-build with custom arguments
#'   nix_build(args = c("--max-jobs", "2", "--quiet"))
#' }
nix_build <- function(
  project_path = getwd(),
  message_type = c("simple", "quiet", "verbose"),
  args = NULL
) {
  message_type <- match.arg(
    message_type,
    choices = c("simple", "quiet", "verbose")
  )

  # if nix store is not in the PATH variable; e.g. on macOS (system's) RStudio
  PATH <- set_nix_path() # nolint: object_name_linter
  if (isTRUE(nzchar(Sys.getenv("NIX_STORE")))) {
    # for Nix R sessions, guarantee that the system's user library
    # (R_LIBS_USER) is not in the search path for packages => run-time purity
    current_libpaths <- .libPaths()
    # don't do this in covr test environment, because this sets R_LIBS_USER
    # to multiple paths
    R_LIBS_USER <- Sys.getenv("R_LIBS_USER")
    if (isFALSE(nzchar(Sys.getenv("R_COVR")))) {
      remove_r_libs_user()
    }
  } else {
    LD_LIBRARY_PATH_default <- Sys.getenv("LD_LIBRARY_PATH")
    if (nzchar(LD_LIBRARY_PATH_default)) {
      # On some systems, like Ubuntu 22.04, we found that a preset
      # `LD_LIBRARY_PATH` environment variable in the system's R session
      # (R installed via apt) is responsible for causing  a segmentation fault
      # for both `nix-build` and `nix-shell` when invoked via
      # `sys::exec_internal`, `base::system()` or `base::system2()` from R.
      # This seems due to incompatible linked libraries or permission issue that
      # conflict when mixing Nix packages and libraries from the system.
      # Therefore, we set it to `""` and set  back the default (old)
      # `LD_LIBRARY_PATH` when `with_nix()` exits. For newer RStudio versions,
      # LD_LIBRARY_PATH is not `""` anymore
      # https://github.com/rstudio/rstudio/issues/12585
      fix_ld_library_path()
      cat(
        "* Current LD_LIBRARY_PATH in system R session is:",
        LD_LIBRARY_PATH_default
      )
      cat("\n", "Setting `LD_LIBRARY_PATH` to `''` during `nix_build()`")
    }
  }

  has_nix_build <- nix_build_installed() # TRUE if available, FALSE if not
  nix_dir <- normalizePath(project_path)
  nix_file <- file.path(nix_dir, "default.nix")

  stopifnot(
    "`project_path` must be character of length 1." = is.character(
      project_path
    ) &&
      length(project_path) == 1L,
    "`project_path` has no `default.nix` file. Use one that contains `default.nix`" = file.exists(
      nix_file
    ),
    "`nix-build` not available. To install, we suggest you follow the 'Setting up and using Nix' vignette for your operating system." = isTRUE(
      has_nix_build
    )
  )

  cmd <- "nix-build"

  # If no custom args provided, just use the project directory.
  # Otherwise, ensure that the project directory is appended.
  if (is.null(args)) {
    args <- nix_dir
  } else {
    args <- as.character(args)
    if (!(nix_dir %in% args)) {
      args <- c(args, nix_dir)
    }
  }

  if (identical(Sys.getenv("TESTTHAT"), "false")) {
    cat(paste0(
      "Running `",
      paste0(cmd, " ", args, collapse = " "),
      "`",
      " ...\n"
    ))
  }

  proc <- sys::exec_background(cmd = cmd, args = args)

  poll_sys_proc_nonblocking(cmd, proc, what = "nix-build", message_type)

  if (isTRUE(nzchar(Sys.getenv("NIX_STORE")))) {
    # set back library paths to state before calling `with_nix()`
    .libPaths(new = current_libpaths)
  } else {
    if (nzchar(LD_LIBRARY_PATH_default)) {
      # set old LD_LIBRARY_PATH (only if system's R session and if it wasn't
      # `""`)
      on.exit(
        Sys.setenv(LD_LIBRARY_PATH = LD_LIBRARY_PATH_default),
        add = TRUE
      )
    }
  }

  on.exit(
    {
      tools::pskill(pid = proc)
    },
    add = TRUE
  )

  return(invisible(proc))
}
