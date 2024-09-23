#' Initiate and maintain an isolated, project-specific, and runtime-pure R
#' setup via Nix.
#'
#' Creates an isolated project folder for a Nix-R configuration.
#' `rix::rix_init()` also adds, appends, or updates with or without backup a
#' custom `.Rprofile` file with code that initializes a startup R environment
#' without system's user libraries within a Nix software environment. Instead,
#' it restricts search paths to load R packages exclusively from the Nix store.
#' Additionally, it makes Nix utilities like `nix-shell` available to run system
#' commands from the system's RStudio R session, for both Linux and macOS.
#'
#' **Enhancement of computational reproducibility for Nix-R environments:**
#'
#' The primary goal of `rix::rix_init()` is to enhance the computational
#' reproducibility of Nix-R environments during runtime. Concretely, if you
#' already have a system or user library of R packages (if you have R installed
#' through the usual means for your operating system), using `rix::rix_init()`
#' will prevent Nix-R environments to load packages from the user library which
#' would cause issues. Notably, no restart is required as environmental
#' variables are set in the current session, in addition to writing an
#' `.Rprofile` file. This is particularly useful to make [rix::with_nix()]
#' evaluate custom R functions from any "Nix-to-Nix" or "System-to-Nix" R
#' setups. It introduces two side-effects that take effect both in a current or
#' later R session setup:
#'
#' 1. **Adjusting `R_LIBS_USER` path:**
#'    By default, the first path of `R_LIBS_USER` points to the user library
#'    outside the Nix store (see also [base::.libPaths()]). This creates
#'    friction and potential impurity as R packages from the system's R user
#'    library are loaded. While this feature can be useful for interactively
#'    testing an R package in a Nix environment before adding it to a `.nix`
#'    configuration, it can have undesired effects if not managed carefully.
#'    A major drawback is that all R packages in the `R_LIBS_USER` location need
#'    to be cleaned to avoid loading packages outside the Nix configuration.
#'    Issues, especially on macOS, may arise due to segmentation faults or
#'    incompatible linked system libraries. These problems can also occur
#'    if one of the (reverse) dependencies of an R package is loaded  along the
#'    process.
#'
#' 2. **Make Nix commands available when running system commands from RStudio:**
#'    In a host RStudio session not launched via Nix (`nix-shell`), the
#'    environmental variables from `~/.zshrc` or `~/.bashrc` may not be
#'    inherited. Consequently, Nix command line interfaces like `nix-shell`
#'    might not be found. The `.Rprofile` code written by `rix::rix_init()`
#'    ensures that Nix command line programs are accessible by adding the path
#'    of the "bin" directory of the default Nix profile,
#'    `"/nix/var/nix/profiles/default/bin"`, to the `PATH` variable in an
#'    RStudio R session.
#'
#' These side effects are particularly recommended when working in flexible R
#' environments, especially for users who want to maintain both the system's
#' native R setup and utilize Nix expressions for reproducible development
#' environments. This init configuration is considered pivotal to enhance the
#' adoption of Nix in the R community, particularly until RStudio in Nixpkgs is
#' packaged for macOS. We recommend calling `rix::rix_init()` prior to comparing R
#' code ran between two software environments with `rix::with_nix()`.
#'
#' `rix::rix_init()` is called automatically by `rix::rix()` when generating a
#' `default.nix` file, and when called by `rix::rix()` will only add the `.Rprofile`
#' if none exists. In case you have a custom `.Rprofile` that you wish to keep
#' using, but also want to benefit from what `rix_init()` offers, manually call
#' it and set the `rprofile_action` to `"append"`.
#'
#' @param project_path Character with the folder path to the isolated nix-R
#'   project. If the folder does not exist yet, it will be created.
#' @param rprofile_action Character. Action to take with `.Rprofile` file
#'   destined for `project_path` folder. Possible values include
#'   `"create_missing"`, which only writes `.Rprofile` if it does not yet exist
#'   (otherwise does nothing) - this is the action set when using `rix()` - ;
#'   `"create_backup"`, which copies the existing `.Rprofile` to a new backup
#'   file, generating names with POSIXct-derived strings that include the time
#'   zone information. A new `.Rprofile` file will be written with default code
#'   from `rix::rix_init()`; `"overwrite"` overwrites the `.Rprofile` file if it
#'   does exist; `"append"` appends the existing file with code that is tailored
#'   to an isolated Nix-R project setup.
#' @param message_type Character. Message type, defaults to `"simple"`, which
#'   gives minimal but sufficient feedback. Other values are currently `"quiet`,
#'   which writes `.Rprofile` without message, and `"verbose"`, which displays
#'   the mechanisms implemented to achieve fully controlled R project
#'   environments in Nix.
#' @export
#' @seealso [with_nix()]
#' @return Nothing, this function only has the side-effect of writing a file
#' called ".Rprofile" to the specified path.
#' @examples
#' \dontrun{
#' # create an isolated, runtime-pure R setup via Nix
#' project_path <- "./sub_shell"
#' if (!dir.exists(project_path)) dir.create(project_path)
#' rix_init(
#'   project_path = project_path,
#'   rprofile_action = "create_missing",
#'   message_type = c("simple")
#' )
#' }
rix_init <- function(project_path,
                     rprofile_action = c(
                       "create_missing", "create_backup",
                       "overwrite", "append"
                     ),
                     message_type = c("simple", "quiet", "verbose")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  is_quiet <- message_type == "quiet"

  rprofile_action <- match.arg(rprofile_action,
    choices = c("create_missing", "create_backup", "overwrite", "append")
  )
  stopifnot(
    "`project_path` needs to be character of length 1" =
      is.character(project_path) && length(project_path) == 1L
  )

  if (isFALSE(is_quiet)) {
    cat(
      "\n### Bootstrapping isolated, project-specific, and runtime-pure",
      "R setup via Nix ###\n\n"
    )
  }
  if (isFALSE(dir.exists(project_path))) {
    dir.create(path = project_path, recursive = TRUE)
    project_path <- normalizePath(path = project_path)
    if (isFALSE(is_quiet)) {
      cat("==> Created isolated nix-R project folder:\n", project_path, "\n")
    }
  } else {
    project_path <- normalizePath(path = project_path)
    if (isFALSE(is_quiet)) {
      cat(
        "==> Existing isolated nix-R project folder:\n", project_path,
        "\n"
      )
    }
  }

  # create project-local `.Rprofile` with pure settings
  # first create the call, deparse it, and write it to .Rprofile
  rprofile_quoted <- nix_rprofile()
  rprofile_deparsed <- deparse_chr1(expr = rprofile_quoted, collapse = "\n")
  rprofile_file <- file.path(project_path, ".Rprofile")
  rprofile_con <- file(rprofile_file, open = "wb", encoding = "native.enc")

  rprofile_text <- get_rprofile_text(rprofile_deparsed)
  on.exit(close(rprofile_con))
  write_rprofile <- function(rprofile_text, rprofile_file) {
    writeLines(enc2utf8(rprofile_text), rprofile_con, useBytes = TRUE)
  }

  is_nix_r <- is_nix_r_session()
  is_rstudio <- is_rstudio_session()

  # signal message if not quiet
  message_r_session_nix_rstudio(is_nix_r, is_rstudio, message_type)

  rprofile_exists <- file.exists(rprofile_file)
  timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  rprofile_backup <- paste0(rprofile_file, "_backup_", timestamp)

  switch(rprofile_action,
    create_missing = {
      if (isTRUE(rprofile_exists)) {
        if (isFALSE(is_quiet)) {
          cat(
            "\n* Keep existing `.Rprofile`. in `project_path`:\n",
            paste0(project_path, "/"), "\n"
          )
        }
      } else {
        write_rprofile(rprofile_text, rprofile_file = rprofile_con)
        if (isFALSE(is_quiet)) {
          message_rprofile(action_string = "Added", project_path = project_path)
        }
      }
      set_message_session_PATH(message_type = message_type)
    },
    create_backup = {
      if (isTRUE(rprofile_exists)) {
        file.copy(from = rprofile_file, to = rprofile_backup)
        write_rprofile(rprofile_text, rprofile_file = rprofile_con)
        if (isFALSE(is_quiet)) {
          cat(
            "\n==> Backed up existing `.Rprofile` in file:\n", rprofile_backup,
            "\n"
          )
          message_rprofile(
            action_string = "Overwrote",
            project_path = project_path
          )
        }

        if (message_type == "verbose") {
          cat("\n* Current lines of local `.Rprofile` are\n:")
          cat(readLines(con = rprofile_con), sep = "\n")
        }
        set_message_session_PATH(message_type = message_type)
      }
    },
    overwrite = {
      write_rprofile(rprofile_text, rprofile_file = rprofile_con)
      if (isTRUE(rprofile_exists)) {
        message_rprofile(
          action_string = "Overwrote", project_path = project_path
        )
      } else {
        message_rprofile(
          action_string = "Added", project_path = project_path
        )
      }
    },
    append = {
      cat(paste0(rprofile_text, "\n"), file = rprofile_con, append = TRUE)
      message_rprofile(
        action_string = "Appended", project_path = project_path
      )
    }
  )

  if (message_type == "verbose") {
    cat("\n\n* Current lines of local `.Rprofile` are:\n\n")
    cat(readLines(con = rprofile_action), sep = "\n")
  }
}

#' Get character vector of length two with comment and code write `.Rprofile`
#' to evaluate R expressions in a pure R library runtime and also RStudio IDE
#' on macOS
#'
#' @param rprofile_deparsed deparsed string with containing `.Rprofile` code.
#' @return Character vector of length 2.
#' @noRd
get_rprofile_text <- function(rprofile_deparsed) {
  c(
    "### File generated by `rix::rix_init()` ###
# 1. Currently, system RStudio does not inherit environmental variables
#   defined in `$HOME/.zshrc`, `$HOME/.bashrc` and alike. This is workaround to
#   make the path of the nix store and hence basic nix commands available
#   in an RStudio session
# 2. For nix-R session, remove `R_LIBS_USER`, system's R user library.`.
#   This guarantees no user libraries from the system are loaded and only
#   R packages in the Nix store are used. This makes Nix-R behave in pure manner
#   at run-time.",
    rprofile_deparsed
  )
}

#' Print message for `.Rprofile` addition
#' @param action_string string
#' @param project_path string with project path
#' @noRd
message_rprofile <- function(action_string = "Added",
                             project_path = ".") {
  msg <- paste0(
    "\n==> ", action_string,
    " `.Rprofile` file and code lines for new R sessions launched from:\n",
    project_path,
    "\n\n* Added the location of the Nix store to `PATH` ",
    "environmental variable for new R sessions on host/docker RStudio:\n",
    "/nix/var/nix/profiles/default/bin"
  )
  cat(msg)
}

#' Get current `PATH` entries, report and modify to include default Nix profile
#' path
#'
#' Print `PATH` environent variable, and modfiy it as as side effect so that ``
#' `"/nix/var/nix/profiles/default/bin"` is included. Confirm message with
#' by printing modified PATH.
#' @return Character vector that lists `PATH` entries after modification, which
#' are separated by `":"`.
#' @noRd
# nolint start: object_name_linter
set_message_session_PATH <- function(message_type =
                                       c("simple", "quiet", "verbose")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  if (message_type == "verbose") {
    cat("\n\n* Current `PATH` variable set in R session is:\n\n")
    cat(Sys.getenv("PATH"))
  }
  if (message_type != "quiet") {
    cat(
      "\n\n==> Also adjusting `PATH` via `Sys.setenv()`, so that",
      "system commands can invoke key Nix commands like `nix-build` in this",
      "RStudio session outside Nix"
    )
  }
  PATH <- set_nix_path()
  if (message_type == "verbose") {
    cat("\n\n* Updated `PATH` variable is:\n\n", PATH)
  }
}
# nolint end: object_name_linter


#' Report whether the current R session is running in Nix and RStudio, or not.
#' @param is_nix_r logical scalar. `TRUE` means in a Nix R environment
#' @param is_rstudio `TRUE` means source R session is inside RStudio
#' @param message_type character vector of lenght one. Either `"simple"`
#' (default), `"quiet"`, or `"verbose"`. Currently, `"simple"` and `"verbose"``
#' create identical messages, while `"quiet"` omits diagnostics messages
#' @return NULL
#' @noRd
message_r_session_nix_rstudio <- function(is_nix_r,
                                          is_rstudio,
                                          message_type =
                                            c("simple", "quiet", "verbose")) {
  stopifnot(
    "`is_nix_r` needs to be TRUE or FALSE" =
      is.logical(is_nix_r) && length(is_nix_r) == 1L,
    "`is_rstudio` needs to be TRUE or FALSE" =
      is.logical(is_rstudio) && length(is_rstudio) == 1L
  )
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )

  if (isTRUE(is_nix_r)) {
    nix_r_msg <-
      "\n* current R session running inside Nix environment"
  } else {
    nix_r_msg <-
      "\n* current R session running outside Nix environment"
  }

  if (isTRUE(is_rstudio)) {
    rstudio_msg <- "from RStudio\n"
  } else {
    rstudio_msg <- "not from RStudio\n"
  }

  # derive compound message
  msg <- paste0(nix_r_msg, " and ", rstudio_msg)

  switch(message_type,
    simple = cat(msg),
    verbose = cat(msg)
  )
}


#' Is the current R session running in a Nix software environment or not?
#'
#' Query `NIX_STORE` environmental variable in current R session. Only nonzero
#' if inside a Nix R.
#' session.
#' @return Logical vector of length one.
#' @noRd
is_nix_r_session <- function() {
  is_nix_r <- nzchar(Sys.getenv("NIX_STORE"))
  return(is_nix_r)
}


#' Has the current R session been launched from RStudio or not?
#'
#' Query `RSTUDIO` environmental variable in current R session. Value is `"1"`
#' if inside RStudio R session.
#' @noRd
is_rstudio_session <- function(message_type = c("simple", "quiet", "verbose")) {
  is_rstudio <- Sys.getenv("RSTUDIO") == "1"
  return(is_rstudio)
}


#' If not yet present, add the Nix default path of the system-wide profile to
#' `PATH` environment variable inside R session.
#'
#' The default profile for the system is typically located at
#' `/nix/var/nix/profiles/default`.
#' @details creates the side effect of adding the .
#' `"/nix/var/nix/profiles/default/bin"`, when it is not yet part of `PATH`
#' @return returns current `PATH` invisibly
#' @noRd
set_nix_path <- function() {
  old_path <- Sys.getenv("PATH")
  nix_path <- "/nix/var/nix/profiles/default/bin"
  has_nix_path <- any(grepl(nix_path, old_path))
  if (isFALSE(has_nix_path)) {
    Sys.setenv(
      PATH = paste(old_path, "/nix/var/nix/profiles/default/bin", sep = ":")
    )
  }
  invisible(Sys.getenv("PATH"))
}


# ¨ Construct expression of `.Rprofile` used by `rix_init()` by quoting
#' expressions via `quote()`.
#' @return language object with parsed expression
#' @noRd
nix_rprofile <- function() {
  # nolint start: object_name_linter
  quote({
    is_rstudio <- Sys.getenv("RSTUDIO") == "1"
    is_nix_r <- nzchar(Sys.getenv("NIX_STORE"))
    if (isFALSE(is_nix_r) && isTRUE(is_rstudio)) {
      # Currently, RStudio does not propagate environmental variables defined in
      # `$HOME/.zshrc`, `$HOME/.bashrc` and alike. This is workaround to
      # make the path of the nix store and hence basic nix commands available
      # in an RStudio session
      cat("{rix} detected RStudio R session")
      old_path <- Sys.getenv("PATH")
      nix_path <- "/nix/var/nix/profiles/default/bin"
      has_nix_path <- any(grepl(nix_path, old_path))
      if (isFALSE(has_nix_path)) {
        Sys.setenv(
          PATH = paste(
            old_path, nix_path,
            sep = ":"
          )
        )
      }
      rm(old_path, nix_path)
    }

    if (isTRUE(is_nix_r)) {
      install.packages <- function(...) {
        stop(
          "You are currently in an R session running from Nix.\n",
          "Don't install packages using install.packages(),\nadd them to ",
          "the default.nix file instead."
        )
      }

      update.packages <- function(...) {
        stop(
          "You are currently in an R session running from Nix.\n",
          "Don't update packages using update.packages(),\n",
          "generate a new default.nix with a more recent version of R. ",
          "If you need bleeding edge packages, read the",
          "'Understanding the rPackages set release cycle and using ",
          "bleeding edge packages' vignette."
        )
      }

      remove.packages <- function(...) {
        stop(
          "You are currently in an R session running from Nix.\n",
          "Don't remove packages using `remove.packages()``,\ndelete them ",
          "from the default.nix file instead."
        )
      }
      current_paths <- .libPaths()
      userlib_paths <- Sys.getenv("R_LIBS_USER")
      user_dir <- grep(
        paste(userlib_paths, collapse = "|"),
        current_paths,
        fixed = TRUE
      )
      new_paths <- current_paths[-user_dir]
      # sets new library path without user library, making nix-R pure at
      # run-time
      .libPaths(new_paths)
      rm(current_paths, userlib_paths, user_dir, new_paths)
    }

    rm(is_rstudio, is_nix_r)
  })
  # nolint end: object_name
}
