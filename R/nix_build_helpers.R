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

#' @noRd
fix_ld_library_path <- function() {
  old_ld_library_path <- Sys.getenv("LD_LIBRARY_PATH")
  Sys.setenv(LD_LIBRARY_PATH="")
  invisible(old_ld_library_path)
}

#' @noRd
poll_sys_proc_blocking <- function(cmd, proc,
                                   what = c("nix-build", "expr"),
                                   message_type = 
                                     c("simple", "quiet", "verbose")
) {
  what <- match.arg(what)
  message_type <- match.arg(message_type)
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
  
  return(invisible(status))
}

#' @noRd
poll_sys_proc_nonblocking <- function(cmd, proc, 
                                      what = c("nix-build", "expr"),
                                      message_type = 
                                        c("simple", "quiet", "verbose")) {
  what <- match.arg(what, choices = c("nix-build", "expr"))
  message_type <- match.arg(message_type,
                            choices = c("simple", "quiet", "verbose"))
  is_quiet <- message_type == "quiet"
  
  if (message_type == "verbose") {
    cat(paste0("* Process ID (PID) is ", proc))
    cat("\n==> receiving stdout and stderr streams from `nix-build`...\n")
  }
  
  status <- sys::exec_status(proc, wait = TRUE)
  
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
  
  err_msg <- switch(
    x_char,
    "100" = "generic build failure (100).",
    "101" = "build timeout (101).",
    "102" = "hash mismatch (102).",
    "104" = "not deterministic (104).",
    stop(paste0("general exit code ", x_char, "."))
  )
  
  return(err_msg)
}
