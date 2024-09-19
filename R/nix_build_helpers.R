#' Avoid impure R library paths in the Nix runtime caused by default
#' `.libPaths()` mechanism in Nix.
#'
#' Remove the global library tree of the default user library location
#' (`R_LIBS_USER`) in Nix, which is the same as the used by the host operating
#' system. This entry is at the first positio of `.libPaths()`. It addresses an
#' issue that arises when combining R environments managed by the host operating
#  system with those managed by Nix on the same computer. Due to the current
#' packaging approach of R in Nix, it is challenging to maintain runtime-pure R
#' library paths. `nix-shell --pure` also does not resolve the issue. By
#' default, R packages are loaded from user-specific library directories of the
#' host operating system, which can lead wrong behavior on Unix systems and
#' segmentation faults on MacOS (Darwin).  In this context, "runtime-pure"
#' refers to ensuring  that R only uses packages from `.libPaths()` in the Nix
#' store, avoiding any unintended loading of R packages installed outside Nix.
#'  @return Invisibly returns previous (if no `R_LIBS_USER` not in
#' `.libPaths()`) or updated `.libPaths()` library paths as character vector.
#' @noRd
remove_r_libs_user <- function() {
  current_paths <- .libPaths()
  userlib_paths <- Sys.getenv("R_LIBS_USER")
  user_dir <- grep(paste(userlib_paths, collapse = "|"), current_paths)
  match <- length(user_dir) != 0L
  if (isTRUE(match)) {
    new_paths <- current_paths[-user_dir]
  }
  # sets new library path without user library, making nix-R pure at
  # run-time
  invisible({
    if (isTRUE(match)) {
      .libPaths(new_paths)
    } else {
      .libPaths()
    }
  })
}

#' Set `LD_LIBRARY_PATH` to `""`.

#' We currently use this helper when not in a Nix R session in both `nix_build()`
#' and `with_nix()`.
#' On some systems, like Ubuntu 22.04, we found that a preset
#' `LD_LIBRARY_PATH` environment variable in the system's R session
#' (R installed via apt) is responsible for causing  a segmentation fault
#' for both `nix-build` and `nix-shell` when invoked via
#' `sys::exec_internal()`, `base::system()` or `base::system2()` from R.
#' This seems due to incompatible linked libraries or permission issue that
#' conflict when mixing Nix packages and libraries from the system.
#' Therefore, we set it to `""` and set  back the default (old)
#' `LD_LIBRARY_PATH` when `with_nix()` exits. For newer RStudio versions,
#'  LD_LIBRARY_PATH is not `""` anymore
#' https://github.com/rstudio/rstudio/issues/12585 => seems to work since
#' RStudio 2023.12.0-daily+346 ; however, since we want to go back in time, too,
#' we'll leave that tweak to ensure properly working behavior.
#' @return returns old value for `LD_LIBRARY_PATH` environment variable
#' @noRd
fix_ld_library_path <- function() {
  old_ld_library_path <- Sys.getenv("LD_LIBRARY_PATH")
  Sys.setenv(LD_LIBRARY_PATH = "")
  invisible(old_ld_library_path)
}

#'
#' @noRd
poll_sys_proc_blocking <- function(cmd, proc,
                                   what = c("nix-build", "expr", "nix-hash"),
                                   message_type =
                                     c("simple", "quiet", "verbose")) {
  what <- match.arg(what, choices = c("nix-build", "expr", "nix-hash"))
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  is_quiet <- message_type == "quiet"

  status <- proc$status
  if (isFALSE(is_quiet)) {
    if (status == 0L) {
      cat(paste0("\n==> ", sys::as_text(proc$stdout)))
      cat(paste0("\n==> `", what, "` succeeded!", "\n"))
    } else {
      msg <- nix_build_exit_msg()
      cat(paste0("`", cmd, "`", " failed with ", msg))
    }
  }

  # return(invisible(status))
}

#' Poll running non-blocking process started previously via.
#' `sys::exec_background()`
#'
#' Typically, it is used for a `nix-build` process launched via `nix_build()`
#' wrapper. The process status is queried via
#' `sys::exec_status(cmd, wait = TRUE)`, there it behaves not strictly like
#' how one would expect from non-blocking code execution, because the R console
#' will not get free until the process is finished (status 0) or exits early
#' with an error code. The waiting is implemented to not create race conditions
#'
#' @noRd
poll_sys_proc_nonblocking <- function(cmd,
                                      proc,
                                      what = c("nix-build", "expr", "nix-hash"),
                                      message_type =
                                        c("simple", "quiet", "verbose")) {
  what <- match.arg(what, choices = c("nix-build", "expr", "nix-hash"))
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  is_quiet <- message_type == "quiet"

  if (message_type == "verbose") {
    cat(paste0("* Process ID (PID) is ", proc))
    cat("\n==> receiving stdout and stderr streams from `nix-build`...\n")
  }

  status <- sys::exec_status(proc, wait = TRUE)

  if (is.na(status)) {
    tools::pskill(pid = proc)
    stop(
      "`nix_build()` likely interrupted by SIGINT (ctrl+c)\n",
      "Stop process with PID ", proc
    )
  }

  if (isFALSE(is_quiet)) {
    if (status == 0L) {
      cat(paste0("\n==> `", what, "` succeeded!"))
    }
  }

  return(invisible(status))
}

#' @noRd
is_integerish <- function(x, tol = .Machine$double.eps^0.5) {
  return(abs(x - round(x)) < tol)
}

#' @noRd
nix_build_installed <- function() {
  which_nix_build <- Sys.which("nix-build")
  if (nzchar(which_nix_build)) {
    return(invisible(TRUE))
  } else {
    return(invisible(FALSE))
  }
}

#' @noRd
nix_build_exit_msg <- function(x) {
  x_char <- as.character(x)

  err_msg <- switch(x_char,
    "100" = "generic build failure (100).",
    "101" = "build timeout (101).",
    "102" = "hash mismatch (102).",
    "104" = "not deterministic (104).",
    stop(paste0("general exit code ", x_char, "."))
  )

  return(err_msg)
}
