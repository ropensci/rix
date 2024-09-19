#' Evaluate function in R or shell command via `nix-shell` environment
#'
#' This function needs an installation of Nix. `with_nix()` has two effects
#' to run code in isolated and reproducible environments.
#' 1. Evaluate a function in R or a shell command via the `nix-shell`
#'   environment (Nix expression for custom software libraries; involving pinned
#'   versions of R and R packages via Nixpkgs)
#' 2. If no error, return the result object of `expr` in `with_nix()` into the
#'   current R session.
#'
#'
#'
#' `with_nix()` gives you the power of evaluating a main function `expr`
#' and its function call stack that are defined in the current R session
#' in an encapsulated nix-R session defined by Nix expression (`default.nix`),
#' which is located in at a distinct project path (`project_path`).
#'
#' `with_nix()` is very convenient because it gives direct code feedback in
#' read-eval-print-loop style, which gives a direct interface to the very
#' reproducible infrastructure-as-code approach offered by Nix and Nixpkgs. You
#' don't need extra efforts such as setting up DevOps tooling like Docker and
#' domain specific tools like \{renv\} to control complex software environments
#' in R and any other language. It is for example useful for the following
#' purposes.
#'
#' 1. test compatibility of custom R code and software/package dependencies in
#'   development and production environments
#' 2. directly stream outputs (returned objects), messages and errors from any
#'   command line tool offered in Nixpkgs into an R session.
#' 3. Test if evolving R packages change their behavior for given unchanged
#'   R code, and whether they give identical results or not.
#'
#' `with_nix()` can evaluate both R code from a nix-R session within
#' another nix-R session, and also from a host R session (i.e., on macOS or
#' Linux) within a specific nix-R session. This feature is useful for testing
#' the reproducibility and compatibility of given code across different software
#' environments. If testing of different sets of environments is necessary, you
#' can easily do so by providing Nix expressions in custom `.nix` or
#' `default.nix` files in different subfolders of the project.
#'
#' `rix_init()` is run automatically to generate a custom `.Rprofile`
#' file for the subshell in `project_dir`. The defaults in that file ensure
#' that only R packages from the Nix store, that are defined in the subshell
#' `.nix` file are loaded and system's libraries are excluded.
#'
#' To do its job, `with_nix()` heavily relies on patterns that manipulate
#' language expressions (aka computing on the language) offered in base R as
#' well as the \{codetools\} package by Luke Tierney.
#'
#' Some of the key steps that are done behind the scene:
#' 1. recursively find, classify, and export global objects (globals) in the
#' call stack of `expr` as well as propagate R package environments found.
#' 2. Serialize (save to disk) and deserialize (read from disk) dependent
#'  data structures as `.Rds` with necessary function arguments provided,
#'  any relevant globals in the call stack, packages, and `expr` outputs
#'  returned in a temporary directory.
#' 3. Use pure `nix-shell` environments to execute a R code script
#'   reconstructed catching expressions with quoting; it is launched by commands
#'  like this via `{sys}` by Jeroen Ooms:
#'  `nix-shell --pure --run "Rscript --vanilla"`.
#'
#' @param expr Single R function or call, or character vector of length one with
#' shell command and possibly options (flags) of the command to be invoked.
#' For `program = R`, you can both use a named or an anonymous function.
#' The function provided in `expr` should not evaluate when you pass arguments,
#' hence you need to wrap your function call like
#' `function() your_fun(arg_a = "a", arg_b = "b")`, to avoid evaluation and make
#' sure `expr` is a function (see details and examples).
#' @param program String stating where to evaluate the expression. Either `"R"`,
#' the default, or `"shell"`. `where = "R"` will evaluate the expression via
#' `RScript` and `where = "shell"` will run the system command in `nix-shell`.
#' @param project_path Path to the folder where the `default.nix` file resides.
#' The default is `"."`, which is the working directory in the current R
#' session. This approach also useful when you have different subfolders
#' with separate software environments defined in different `default.nix` files.
#' @param message_type String how detailed output is. Currently, there is
#' either `"simple"` (default), `"quiet` or `"verbose"`, which shows the script
#' that runs via `nix-shell`.
#' @importFrom codetools findGlobals checkUsage
#' @export
#' @return
#' - if `program = "R"`, R object returned by function given in `expr`
#' when evaluated via the R environment in `nix-shell` defined by Nix
#' expression.
#' - if `program = "shell"`, list with the following elements:
#'     - `status`: exit code
#'     - `stdout`: character vector with standard output
#'     - `stderr`: character vector with standard error
#' of `expr` command sent to a command line interface provided by a Nix package.
#' @examples
#' \dontrun{
#' # create an isolated, runtime-pure R setup via Nix
#' project_path <- "./sub_shell"
#' rix_init(
#'   project_path = project_path,
#'   rprofile_action = "create_missing"
#' )
#' # generate nix environment in `default.nix`
#' rix(
#'   r_ver = "4.2.0",
#'   project_path = project_path
#' )
#' # evaluate function in Nix-R environment via `nix-shell` and `Rscript`,
#' # stream messages, and bring output back to current R session
#' out <- with_nix(
#'   expr = function(mtcars) nrow(mtcars),
#'   program = "R", project_path = project_path,
#'   message_type = "simple"
#' )
#'
#' # There no limit in the complexity of function call stacks that `with_nix()`
#' # can possibly handle; however, `expr` should not evaluate and
#' # needs to be a function for `program = "R"`. If you want to pass the
#' # a function with arguments, you can do like this
#' get_sample <- function(seed, n) {
#'   set.seed(seed)
#'   out <- sample(seq(1, 10), n)
#'   return(out)
#' }
#'
#' out <- with_nix(
#'   expr = function() get_sample(seed = 1234, n = 5),
#'   program = "R",
#'   project_path = ".",
#'   message_type = "simple"
#' )
#'
#' ## You can also attach packages with `library()` calls in the current R
#' ## session, which will be exported to the nix-R session.
#' ## Other option: running system commands through `nix-shell` environment.
#' }
with_nix <- function(expr,
                     program = c("R", "shell"),
                     project_path = ".",
                     message_type = c("simple", "quiet", "verbose")) {
  nix_file <- file.path(project_path, "default.nix")
  # nolint start: line_length_linter
  stopifnot(
    "`project_path` must be character of length 1." =
      is.character(project_path) && length(project_path) == 1L,
    "`project_path` has no `default.nix` file. Use one that contains `default.nix`" =
      file.exists(nix_file),
    "`message_type` must be character." = is.character(message_type),
    "`expr` needs to be a call or function for `program = R`, and character of length 1 for `program = shell`" =
      is.function(expr) || is.call(expr) || (is.character(expr) && length(expr) == 1L)
  )
  # nolint end

  program <- match.arg(program, choices = c("R", "shell"))
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )

  is_quiet <- message_type == "quiet"

  # ad-hoc solution for RStudio's limitation that R sessions cannot yet inherit
  # proper `PATH` from custom `.Rprofile` on macOS (2023-01-17)
  # adjust `PATH` to include `/nix/var/nix/profiles/default/bin`
  is_rstudio <- is_rstudio_session()
  is_nix_r <- is_nix_r_session()

  # cat message if not quiet
  message_r_session_nix_rstudio(is_nix_r, is_rstudio, message_type)

  if (isTRUE(is_rstudio) && isFALSE(is_nix_r)) {
    set_nix_path()
  }

  if (isTRUE(is_nix_r)) {
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
    # nolint start: object_name_linter
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
    # nolint end
  }

  has_nix_shell <- nix_shell_available() # TRUE if yes, FALSE if no

  if (isFALSE(has_nix_shell)) {
    stop_no_nix_shell()
  }

  if (program == "R") {
    # get the function arguments as a pairlist;
    # save formal arguments of pairlist via `tag = value`; e.g., if we have a
    # `expr = function(p = p_root) dir(path = p)`, the input object
    # to be serialized will be serialized under `"p.Rds"`  in a tmp dir, and
    # will contain object `p_root`, which is defined in the global environment
    # and bound to `"."` (project root)
    args <- as.list(formals(expr))

    if (isFALSE(is_quiet)) {
      cat(
        "\n* using environment defined by Nix expression in file:\n",
        normalizePath(file.path(project_path, "default.nix")), "\n"
      )
    }

    if (message_type == "verbose") {
      cat(
        "\n==> preparing to exchange arguments and globals in `expr`",
        "between the current source and Nix R target sessions ...\n"
      )
    }

    # 1) save all function args onto a temporary folder each with
    # `<tag.Rds>` and `value` as serialized objects from RAM -------------------
    tmpdir <- tempdir()
    on.exit(unlink(tmpdir, recursive = TRUE, force = TRUE), add = TRUE)
    temp_dir <- file.path(tmpdir, "with_nix")
    if (!dir.exists(temp_dir)) {
      dir.create(temp_dir, recursive = TRUE)
    }
    on.exit(unlink(temp_dir, recursive = TRUE, force = TRUE), add = TRUE)
    serialize_args(args, temp_dir)

    # cast list of symbols/names and calls to list of strings; this is to prepare
    # deparsed version (string) of deserializing arguments from disk;
    # elements of args for now should be of type "symbol" or "language"
    args_vec <- vapply(args, deparse, FUN.VALUE = character(1L))

    # do code inspection checks to report messages with potential code problems,
    # and find global variables of `expr` recursively
    # using {codetools} wrapper
    globals_expr <- recurse_find_check_globals(expr, args_vec, message_type)

    # wrapper around `serialize_lobjs()`
    globals <- serialize_globals(globals_expr, temp_dir)

    # extract additional packages to export
    pkgs <- serialize_pkgs(globals_expr, temp_dir, message_type)

    # 2) deserialize formal arguments of `expr` in nix session
    # and necessary global objects ---------------------------------------------
    # 3) serialize resulting output from evaluating function given as `expr`

    # main code to be run in nix R session
    rnix_file <- file.path(temp_dir, "with_nix_r.R")

    rnix_quoted <- quote_rnix(
      expr, program,
      message_type = message_type,
      args_vec, globals, pkgs, temp_dir, rnix_file
    )
    rnix_deparsed <- deparse_chr1(expr = rnix_quoted, collapse = "\n")

    # 4): for 2) and 3) write script to disk, to run later via `Rscript` from
    # `nix-shell` environment
    writeLines(text = rnix_deparsed, file(rnix_file))

    # 3) run expression in nix session, based on temporary script
    if (isFALSE(is_quiet)) {
      cat(paste0("\n==> running deparsed expression via `nix-shell`...\n\n"))
    }

    # command to run deparsed R expression via nix-shell
    cmd_rnix_deparsed <- c(
      file.path(project_path, "default.nix"),
      "--pure", # required so that nix glibc is used
      "--run",
      sprintf(
        "Rscript --no-site-file --no-environ --no-restore '%s'",
        rnix_file
      )
    )

    proc <- sys::exec_background(cmd = "nix-shell", cmd_rnix_deparsed)

    poll_sys_proc_nonblocking(
      cmd = cmd_rnix_deparsed, proc, what = "expr",
      message_type
    )
  } else if (program == "shell") { # end of `if (program == "R")`
    shell_cmd <- c(
      file.path(project_path, "default.nix"),
      "--pure",
      "--run",
      expr
    )
    proc <- sys::exec_internal(cmd = "nix-shell", shell_cmd)
  }

  # 5) deserialize final output of `expr` evaluated in nix-shell
  # into host R session
  if (program == "R") {
    out <- readRDS(file = file.path(temp_dir, "_out.Rds"))
  } else if (program == "shell") {
    status <- poll_sys_proc_blocking(
      cmd = shell_cmd, proc, what = "expr", message_type
    )
    out <- sys::as_text(proc$stdout)
  }

  if (isFALSE(is_quiet)) {
    cat("\n### Finished code evaluation in `nix-shell` ###\n")
  }

  if (isTRUE(is_nix_r)) {
    # set back library paths to state before calling `with_nix()`
    .libPaths(current_libpaths)
  } else {
    if (nzchar(LD_LIBRARY_PATH_default)) {
      # set old LD_LIBRARY_PATH (only if system's R session and if it wasn't
      # `""`)
      on.exit(
        {
          Sys.setenv(LD_LIBRARY_PATH = LD_LIBRARY_PATH_default)
        },
        add = TRUE
      )
    }
  }

  # return output from evaluated function
  if (isFALSE(is_quiet)) {
    cat("\n* evaluating `expr` in `nix-shell` returns:\n")
  }

  if (program == "R") {
    if (isFALSE(is_quiet)) {
      print(out)
    }
  } else if (program == "shell") {
    if (isFALSE(is_quiet)) {
      print(out)
    }
  }
  cat("")

  on.exit(
    {
      if (program == "R") {
        unlink(temp_dir, recursive = TRUE, force = TRUE)
        # only R expressions are nonblockings
        tools::pskill(pid = proc)
      }
    },
    after = FALSE,
    add = TRUE
  )

  return(out)
}
