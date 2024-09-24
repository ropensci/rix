#' Invoke shell command `nix-build` from an R session
#' @param project_path Path to the folder where the `default.nix` file resides.
#' @param message_type Character vector with messaging type, Either `"simple"`
#' (default), `"quiet"` for no messaging, or `"verbose"`.
#' @return integer of the process ID (PID) of `nix-build` shell command
#' launched, if `nix_build()` call is assigned to an R object. Otherwise, it
#' will be returned invisibly.
#' @details The `nix-build` command line interface has more arguments. We will
#' probably not support all of them in this R wrapper, but currently we have
#' support for the following `nix-build` flags:
#' - `--max-jobs`: Maximum number of build jobs done in parallel by Nix.
#'   According to the official docs of Nix, it defaults to `1`, which is one
#'   core. This option can be useful for shared memory multiprocessing or
#'   systems with high I/O latency. To set `--max-jobs` used, you can declare
#'   with `options(rix.nix_build_max_jobs = <integer>)`. Once you call
#'   `nix_build()` the flag will be propagated to the call of `nix-build`.
#' @importFrom tools pskill
#' @export
#' @examples
#' \dontrun{
#' nix_build()
#' }
nix_build <- function(project_path = getwd(),
                      message_type = c("simple", "quiet", "verbose")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  # if nix store is not PATH variable; e.g. on macOS (system's) RStudio
  PATH <- set_nix_path() # nolint: object_name_linter
  if (isTRUE(nzchar(Sys.getenv("NIX_STORE")))) {
    # for Nix R sessions, guarantee that the system's user library
    # (R_LIBS_USER) is not in the search path for packages => run-time purity
    current_libpaths <- .libPaths()
    # don't do this in covr test environment, because this sets R_LIBS_USER
    # to multiple paths
    R_LIBS_USER <- Sys.getenv("R_LIBS_USER") # nolint: object_name_linter
    if (isFALSE(nzchar(Sys.getenv("R_COVR")))) {
      remove_r_libs_user()
    }
  } else {
    # nolint next: object_name_linter
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
        LD_LIBRARY_PATH_default # nolint: object_name_linter
      )
      cat("\n", "Setting `LD_LIBRARY_PATH` to `''` during `nix_build()`")
    }
  }
  has_nix_build <- nix_build_installed() # TRUE if yes, FALSE if no
  nix_dir <- normalizePath(project_path)
  nix_file <- file.path(nix_dir, "default.nix")

  # nolint start: line_length_linter
  stopifnot(
    "`project_path` must be character of length 1." =
      is.character(project_path) && length(project_path) == 1L,
    "`project_path` has no `default.nix` file. Use one that contains `default.nix`" =
      file.exists(nix_file),
    "`nix-build` not available. To install, we suggest you follow https://zero-to-nix.com/start/install ." =
      isTRUE(has_nix_build)
  )
  # nolint end

  max_jobs <- getOption("rix.nix_build_max_jobs", default = 1L)
  stopifnot(
    "option `rix.nix_build_max_jobs` is not integerish" =
      is_integerish(max_jobs)
  )
  max_jobs <- as.integer(max_jobs)

  cmd <- "nix-build"

  if (max_jobs == 1L) {
    args <- nix_dir
  } else {
    args <- c("--max-jobs", as.character(max_jobs), nix_dir)
  }

  cat(paste0(
    "Running `", paste0(cmd, " ", args, collapse = " "), "`",
    " ...\n"
  ))

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
