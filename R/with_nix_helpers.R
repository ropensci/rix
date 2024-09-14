#' Stop with descriptive error how to solve when `nix-shell` cannot be found
#' in current shell environment or R session
#' @noRd
stop_no_nix_shell <- function(msg = no_nix_shell_msg()) {
  stop(
    msg,
    call. = FALSE
  )
}

no_nix_shell_msg <- function() {
  paste0(
    "`nix-shell` is needed but is not available in your current ",
    "shell environment.\n",
    "* If you are in an R session of your host operating system, you
    either\n1a) need to install Nix first, or if you have already done so ",
    "\n",
    "To install, we suggest you follow https://zero-to-nix.com/start/install .",
    "\n",
    "1b) make sure that the location of the nix store is in the `PATH`
    variable of this R session (mostly necessary in RStudio).\n",
    "* If you ran `with_nix()` from R launched in a `nix-shell`, you need
    to make sure that `pkgs.nix` is in the `buildInput` for ",
    "`pkgs.mkShell`.\nIf you used `rix::rix()` to generate your main nix
    configuration of this session, just regenerate it with the additonal
    argument `system_pkgs = 'nix'."
  )
}


#' Serialize a list of R expressions as `.Rds` to disk
#'
#' This helper is currently only called from the wrapper `serialize_globals()`,
#' where all recursively found global R objects of `expr` need to be saved
#' on disk in a temporary directory, so that they can later be deserialized
#' inside the Nix R environment
#' @param lobjs list of **R** expressions
#' @param file path of temporary directory where list of expressions are
#' saved as individual `.Rds` files
#' @details It is called for its side effects to save expressions as `.Rds`
#' files.
#' @noRd
serialize_lobjs <- function(lobjs, temp_dir) {
  invisible({
    for (i in seq_along(lobjs)) {
      if (!any(nzchar(deparse(lobjs[[i]])))) {
        # for unnamed arguments like `expr = function(x) print(x)`
        # x would be an empty symbol, see also ; i.e. arguments without
        # default expressions; i.e. tagged arguments with no value
        # https://stackoverflow.com/questions/3892580/create-missing-objects-aka-empty-symbols-empty-objects-needed-for-f # nolint
        lobjs[[i]] <- as.symbol(names(lobjs)[i])
      }
      saveRDS(
        object = lobjs[[i]],
        file = file.path(temp_dir, paste0(names(lobjs)[i], ".Rds"))
      )
    }
  })
}

#' Get all function args of `expr` as R objects and save them into `.Rds` files.
#'
#' Save function arguments into a folder each with `<tag.Rds>` and `value`.
#' This is used for the first serialization step in the source environment
#' inside `with_nix()`.
#' @param args list of symbols where names of elements are character
#' representations of symbols, or list containing empty symbol(s)
#' @noRd
serialize_args <- function(args, temp_dir) {
  invisible({
    for (i in seq_along(args)) {
      if (!nzchar(deparse(args[[i]]))) {
        # for unnamed arguments like `expr = function(x) print(x)`
        # x would be an empty symbol, see also ; i.e. arguments without
        # default expressions; i.e., tagged arguments with no value
        # nolint next: line_length_linter
        # https://stackoverflow.com/questions/3892580/create-missing-objects-aka-empty-symbols-empty-objects-needed-for-f
        args[[i]] <- as.symbol(names(args)[i])
      }
      args[[i]] <- get(as.character(args[[i]]))
      saveRDS(
        object = args[[i]],
        file = file.path(temp_dir, paste0(names(args)[i], ".Rds"))
      )
    }
  })
}


#' Check if the current environment is the empty environment
#' @return logical vector of length one
#' @noRd
is_empty <- function(x) identical(x, emptyenv())


#' Find the environment where R object is defined
#'
#' Is used by helper `classify_globals()`, to return the environment where
#' the object called `name`. The environment stack is queried until the empty
#' environment is reached.
#' @param name  string with the name of the R object (a global)
#' @param env environment (class) where to search is started in direction to
#' the empty environment
#' @return environment (class), where object of called `<name>` is found
#' @noRd
where <- function(name, env = parent.frame()) {
  while (!is_empty(env)) {
    if (exists(name, envir = env, inherits = FALSE)) {
      return(env)
    }
    # inspect parent
    env <- parent.env(env)
  }
}

#' Finds and checks global functions and variables recursively for closure
#' @param expr an **R** expression
#' @param args_vec character vector with arguments
#' @noRd
recurse_find_check_globals <- function(expr,
                                       args_vec,
                                       message_type =
                                         c("simple", "quiet", "verbose")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  is_quiet <- message_type == "quiet"

  if (message_type == "verbose") {
    cat("\n==> inspecting code recursively in call stack of `expr`...")
    codetools::checkUsage(fun = expr)
  }

  codetools::checkUsage(fun = expr)

  globals_expr <- codetools::findGlobals(fun = expr)
  globals_lst <- classify_globals(globals_expr, args_vec)

  round_i <- 1L

  repeat {
    get_globals_exprs <- function(globals_lst) {
      globals_exprs <- names(unlist(Filter(
        function(x) !is.null(x),
        unname(globals_lst[c("globalenv_fun", "env_fun")])
      )))
      return(globals_exprs)
    }

    if (round_i == 1L) {
      # first round
      globals_exprs <- get_globals_exprs(globals_lst)
    } else {
      # successive rounds
      globals_exprs <- unlist(lapply(globals_lst, get_globals_exprs))
    }
    lapply(
      globals_exprs,
      codetools::checkUsage
    )
    cat("\n")

    globals_new <- lapply(
      globals_exprs,
      function(x) codetools::findGlobals(fun = x)
    )

    globals_lst_new <- lapply(
      globals_new,
      function(x) classify_globals(globals_expr = x, args_vec)
    )

    if (round_i == 1L) {
      result_list <- c(list(globals_lst), globals_lst_new)
    } else {
      result_list <- c(result_list, globals_lst_new)
    }

    # prepare current globals to find new globals one recursion level deeper
    # in the call stack in the next repeat
    globals_lst <- globals_lst_new

    globals_lst <- lapply(globals_lst, function(x) lapply(x, unlist))

    # packages need to be excluded for getting more globals
    globals_lst <- lapply(
      globals_lst,
      function(x) {
        x[c("globalenv_fun", "globalenv_other", "env_other", "env_fun")]
      }
    )

    globals_null <- all(is.null(unlist(globals_lst)))
    # TRUE if no more candidate global values
    all_non_pkgs_null <- all(globals_null)

    round_i <- round_i + 1L

    if (is.null(globals_lst) || all_non_pkgs_null) break
  }

  result_list <- Filter(function(x) !is.null(x), result_list)
  result_list <- lapply(
    result_list,
    function(x) Filter(function(x) !is.null(x), x)
  )

  pkgs <- unlist(lapply(result_list, "[", "pkgs"))

  unlist_unname <- function(x) {
    unlist(
      lapply(x, function(x) unlist(unname(x)))
    )
  }

  globalenv_fun <- lapply(result_list, "[", "globalenv_fun")
  globalenv_fun <- unlist_unname(globalenv_fun)

  globalenv_other <- lapply(result_list, "[", "globalenv_other")
  globalenv_other <- unlist_unname(globalenv_other)

  env_other <- lapply(result_list, "[", "env_other")
  env_other <- unlist_unname(env_other)

  env_fun <- lapply(result_list, "[", "env_fun")
  env_fun <- unlist_unname(env_fun)

  exports <- list(
    pkgs = pkgs,
    globalenv_fun = globalenv_fun,
    globalenv_other = globalenv_other,
    env_other = env_other,
    env_fun = env_fun
  )

  return(exports)
}

#' Classify global objects found when apply `codetools::findGlobals` on
#' `expr`, and also on all global object found via recursion of the same
#' function
#' @param globals_expr character vector of object names assigned for each
#' global object found
#' @param args_vec character vector with deparsed function argument names
#' @return list with object category, where each object category contains
#' contains a character vector with the the respective environment as value and
#' the object name assigned as name. If no global object is assigned for a,
#' category, `NULL` element will be returned. Available object category
#' elements are:
#' * `globalenv_fun`: Character vector with function(s) in the global
#' environment
#' * `globalenv_other`: Character vector with the R objects in the global
#' environment
#' * `env_other`: Character vector with other environments found
#' * `env_fun`: Character vector with functions assigned to custom othe
#' other environments
#' * `pkgs`: Packages found
#' @noRd
classify_globals <- function(globals_expr, args_vec) {
  envs_check <- lapply(globals_expr, where)
  names(envs_check) <- globals_expr

  vec_envs_check <- vapply(envs_check, environmentName, character(1L))
  # directly remove formals
  vec_envs_check <- vec_envs_check[!names(vec_envs_check) %in% args_vec]
  if (length(vec_envs_check) == 0L) {
    vec_envs_check <- NULL
  }

  if (!is.null(vec_envs_check)) {
    globs_pkg <- grep("^package:", vec_envs_check, value = TRUE)
    if (length(globs_pkg) == 0L) {
      globs_pkg <- NULL
    }
    # globs base can be ignored
    globs_base <- grep("^base$", vec_envs_check, value = TRUE)
    globs_globalenv <- grep("^R_GlobalEnv$", vec_envs_check, value = TRUE)
    globs_globalenv <- Filter(nzchar, globs_globalenv)
    # empty globs; can be ignored for now
    globs_empty <- Filter(function(x) !nzchar(x), vec_envs_check)
    if (length(globs_empty) == 0L) {
      globs_empty <- NULL
    }
    globs_other <- vec_envs_check[
      !names(vec_envs_check) %in% names(
        c(globs_pkg, globs_globalenv, globs_empty, globs_base)
      )
    ]
    if (length(globs_other) == 0L) {
      globs_other <- NULL
    }
  }

  is_globalenv_funs <- vapply(
    names(globs_globalenv), function(x) is.function(get(x)),
    FUN.VALUE = logical(1L)
  )

  is_otherenv_funs <- vapply(
    names(globs_other), function(x) is.function(get(x)),
    FUN.VALUE = logical(1L)
  )

  globs_globalenv_fun <- globs_globalenv[is_globalenv_funs]
  if (length(globs_globalenv_fun) == 0L) {
    globs_globalenv_fun <- NULL
  }
  globs_globalenv_other <- globs_globalenv[!is_globalenv_funs]
  if (length(globs_globalenv_other) == 0L) {
    globs_globalenv_other <- NULL
  }

  globs_otherenv_fun <- globs_other[is_otherenv_funs]
  if (length(globs_otherenv_fun) == 0L) {
    globs_otherenv_fun <- NULL
  }
  globs_otherenv_other <- globs_other[!is_otherenv_funs]
  if (length(globs_otherenv_other) == 0L) {
    globs_otherenv_other <- NULL
  }

  default_pkgnames <- paste0("package:", getOption("defaultPackages"))
  pkgenvs_attached <- setdiff(globs_pkg, c(default_pkgnames, "base"))

  if (!length(pkgenvs_attached) == 0L) {
    pkgs_to_attach <- gsub("^package:", "", pkgenvs_attached)
  } else {
    pkgs_to_attach <- NULL
  }

  globs_classified <- list(
    globalenv_fun = globs_globalenv_fun,
    globalenv_other = globs_globalenv_other,
    env_other = globs_otherenv_other,
    env_fun = globs_otherenv_fun,
    pkgs = pkgs_to_attach
  )
  globs_null <- all(vapply(globs_classified, is.null, logical(1L)))
  if (globs_null) globs_classified <- NULL

  return(globs_classified)
}


#' Serialize expressions of all global objects found.
#'
#' Wrapper around `serialize_lobjs()`
#'
#' @param globals_expr List with character vector of global R objects detected
#' with elements per object category (`pkgs`, `globalenv_fun`,
#' `globalenv_other`, `env_other`, `env_fun`)
#' @param temp_dir String with temporary directory to save R objects in memory
#' do disk
#' @param message_type Character vector with messaging type, Either `"simple"`
#' (default), `"quiet"` for no messaging, or `"verbose"` to report which object
#' categories are saved under which `.Rds` file and path.
#' @noRd
serialize_globals <- function(globals_expr,
                              temp_dir,
                              message_type = c("simple", "quiet", "verbose")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  funs <- globals_expr$globalenv_fun
  if (!is.null(funs)) {
    if (message_type == "verbose") {
      cat(
        "==> serializing global functions under `<function-name>.Rds` in
      temporary folder at",
        paste0(normalizePath(temp_dir), "...\n"), paste(names(funs)), "\n"
      )
    }
    globalenv_funs <- lapply(
      names(funs),
      function(x) get(x = x, envir = .GlobalEnv)
    )
    names(globalenv_funs) <- names(globals_expr$globalenv_fun)
    serialize_lobjs(lobjs = globalenv_funs, temp_dir)
  }
  others <- globals_expr$globalenv_other
  if (!is.null(others)) {
    if (message_type == "verbose") {
      cat(
        "==> serializing non-function object(s), e.g., other environments",
        paste(names(others)), " ...\n"
      )
    }
    globalenv_others <- lapply(
      names(others),
      function(x) get(x = x, envir = .GlobalEnv)
    )
    names(globalenv_others) <- names(globals_expr$globalenv_other)
    serialize_lobjs(lobjs = globalenv_others, temp_dir)
  }
  env_funs <- globals_expr$env_fun
  if (!is.null(env_funs)) {
    cat(
      "==> Serializing function(s) from other environment(s):",
      paste(names(env_funs)), "\n"
    )
    env_funs <- lapply(
      names(env_funs),
      function(x) get(x = x)
    )
    names(env_funs) <- names(globals_expr$env_fun)
    serialize_lobjs(lobjs = env_funs, temp_dir)
  }
  env_others <- globals_expr$env_other
  if (!is.null(env_others)) {
    cat(
      "==> Serializing non-function object(s) from custom environment(s)::",
      paste(names(env_others)), "\n"
    )
    env_others <- lapply(
      names(env_others),
      function(x) get(x = x)
    )
    names(env_others) <- names(globals_expr$env_other)
    serialize_lobjs(lobjs = env_others, temp_dir)
  }

  return(c(funs, others, env_funs, env_others))
}


#' Save name of R packages as `_pkgs.Rds` file into temporary directory
#'
#' All R packages will be serialized from character vector element `pkgs`. If it
#' is `NULL`, then `NULL` will be in `_pkgs.Rds` in the temporary directory
#'
#' @param globals_expr List with character vector of global R objects detected
#' with elements per object category (`pkgs`, `globalenv_fun`,
#' `globalenv_other`, `env_other`, `env_fun`).
#' @param temp_dir Character vector with temporary directory to save `_pkgs.Rds`
#' @param message_type Type of message. Either `"simple"` (default),
#' `"quiet"`, or `"verbose"`.
#' @return character vector with name of R packages.
#' @noRd
serialize_pkgs <- function(globals_expr,
                           temp_dir,
                           message_type = c("simple", "verbose", "quiet")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose")
  )
  is_quiet <- message_type == "quiet"
  pkgs <- globals_expr$pkgs
  if (!is.null(pkgs) && isFALSE(is_quiet)) {
    cat(
      "=> Serializing package(s) required to run `expr`:\n",
      paste(pkgs), "\n"
    )
  }
  saveRDS(
    object = pkgs,
    file = file.path(temp_dir, "_pkgs.Rds")
  )
  return(pkgs)
}

#' Quote language objects via partial substitution of expressions
#' reads like R code, and avoids code injection.
#'
#' This is used to boilerplate a custom R script that is evaluated by calling
#' `Rscript` in Nix target environment
#' @param expr Typically a function
#' @param program string, currently `"R"`
#' @param message_type character vector of length one with message type;
#' either `"simple"`, `"quiet"`, or `"verbose"`
#' @param args_vec character vector with argument names
#' @param globals character vector with global objects found
#' @param pkgs if no packages to export, `NULL`, otherwise character vector
#' of packages to be exported
#' @param temp_dir string with file path to temporary directory to be used to
#' evaluate expression in Nix R session
#' @param rnix_file string with path to `with_nix_r.R` R script evaluated via
#' `Rscript` in `nix-shell`
#' @return A language object
#' @noRd
quote_rnix <- function(expr,
                       program,
                       message_type,
                       args_vec,
                       globals,
                       pkgs,
                       temp_dir,
                       rnix_file) {
  expr_quoted <- bquote({
    message_type <- .(message_type)
    is_quiet <- message_type == "quiet"
    if (isFALSE(is_quiet)) {
      cat("\n### start evaluating `expr` in `nix-shell` ###")
    }
    if (message_type == "verbose") {
      cat(
        "\n\n* wrote R script evaluated via `Rscript` in `nix-shell`:",
        .(rnix_file)
      )
    }
    temp_dir <- .(temp_dir)
    cat("\n", Sys.getenv("NIX_PATH"))
    # fix library paths for nix R on macOS and linux; avoid permission issue
    current_paths <- .libPaths()
    userlib_paths <- Sys.getenv("R_LIBS_USER")
    user_dir <- grep(paste(userlib_paths, collapse = "|"), current_paths)
    new_paths <- current_paths[-user_dir]
    .libPaths(new_paths)
    r_version_num <- paste0(R.version$major, ".", R.version$minor)
    if (isFALSE(is_quiet)) {
      cat("\n* evaluating `expr` in Nix shell with R version", r_version_num, "\n\n")
    }
    # assign `args_vec` as in c(...) form.
    args_vec <- .(with_assign_vecnames_call(vec = args_vec))
    # deserialize arguments from disk
    for (i in seq_along(args_vec)) {
      nm <- args_vec[i]
      obj <- args_vec[i]
      assign(
        x = nm,
        value = readRDS(file = file.path(temp_dir, paste0(obj, ".Rds")))
      )
      if (message_type == "verbose") {
        cat(
          paste0(
            "  ==> reading file ", "'", obj, ".Rds", "'",
            " for argument named `", obj, "` ...\n"
          )
        )
      }
    }

    globals <- .(with_assign_vecnames_call(vec = globals))
    for (i in seq_along(globals)) {
      nm <- globals[i]
      obj <- globals[i]
      assign(
        x = nm,
        value = readRDS(file = file.path(temp_dir, paste0(obj, ".Rds")))
      )
      if (message_type == "verbose") {
        cat(
          paste0(
            "  ==> reading file ", "'", obj, ".Rds", "'",
            " for global object named `", obj, "`\n"
          )
        )
      }
    }

    # for now name of character vector containing packages is hard-coded
    # pkgs <- .(with_assign_vecnames_call(vec = pkgs))
    # pkgs <- .(pkgs)
    pkgs <- .(with_assign_vec_call(vec = pkgs))
    lapply(pkgs, library, character.only = TRUE)

    # execute function call in `expr` with list of correct args
    lst <- as.list(args_vec)
    names(lst) <- args_vec
    lst <- lapply(lst, as.name)
    rnix_out <- do.call(.(expr), lst)
    if (message_type == "verbose") {
      cat("\n* called `expr` with args:", args_vec, "\n")
      cat(
        "\n* The type of the output object returned by `expr` is",
        paste0(typeof(rnix_out), ".\n")
      )
    }
    saveRDS(object = rnix_out, file = file.path(temp_dir, "_out.Rds"))
    if (message_type == "verbose") {
      cat("\n* saved output to", file.path(temp_dir, "_out.Rds"))
      cat("\n\n* the following objects are in the global Nix R environment:\n")
      cat(ls())
      cat("\n")
    }
    if (message_type != "quiet") {
      cat("\n* `sessionInfo()` output:\n\n")
      try(cat(capture.output(sessionInfo()), sep = "\n"))
    }
  }) # end of `bquote()`

  return(expr_quoted)
}

# https://github.com/cran/codetools/blob/master/R/codetools.R
# finding global variables

# reconstruct argument vector (character) in Nix R;
# build call to generate `args_vec`
#' @noRd
with_assign_vecnames_call <- function(vec) {
  cl <- call("c")
  for (i in seq_along(vec)) {
    cl[[i + 1L]] <- names(vec[i])
  }
  return(cl)
}


#' Create call that combines character inputs arguments via `c()`
#'
#' @examples
#' with_assign_vec_call(c("a", "b"))
#' @noRd
with_assign_vec_call <- function(vec) {
  cl <- call("c")
  for (i in seq_along(vec)) {
    cl[[i + 1L]] <- vec[i]
  }
  return(cl)
}

#' Deparse expression into string (character vector of length 1)
#'
#' This re-implements what `deparse1()` does, because the function has only been
#' around since 4.0.0
#' @param expr any **R** expression
#' @return representation of `expr` as character vector of length 1
#' @author R Core Team
#' @noRd
deparse_chr1 <- function(expr, width_cutoff = 500L, collapse = " ", ...) {
  paste(deparse(expr, width_cutoff, ...), collapse = collapse)
}


#'
#' @noRd
nix_shell_available <- function() {
  which_nix_shell <- Sys.which("nix-shell")
  is_available <- nzchar(which_nix_shell)
  return(is_available)
}
