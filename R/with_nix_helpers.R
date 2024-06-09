#' @noRd
stop_no_nix_shell <- function() {
  stop(
    paste0("`nix-shell` is needed but is not available in your current ",
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
      argument `system_pkgs = 'nix'."),
      call. = FALSE
  )
}


#' serialize language objects
#' @noRd
serialize_lobjs <- function(lobjs, temp_dir) {
  invisible({
    for (i in seq_along(lobjs)) {
      if (!any(nzchar(deparse(lobjs[[i]])))) {
        # for unnamed arguments like `expr = function(x) print(x)`
        # x would be an empty symbol, see also ; i.e. arguments without 
        # default expressions; i.e. tagged arguments with no value
        # https://stackoverflow.com/questions/3892580/create-missing-objects-aka-empty-symbols-empty-objects-needed-for-f
        lobjs[[i]] <- as.symbol(names(lobjs)[i])
      }
      saveRDS(
        object = lobjs[[i]],
        file = file.path(temp_dir, paste0(names(lobjs)[i], ".Rds"))
      )
    }
  })
}

#' serialize arguments
#' @noRd
serialize_args <- function(args, temp_dir) {
  invisible({
    for (i in seq_along(args)) {
      if (!nzchar(deparse(args[[i]]))) {
        # for unnamed arguments like `expr = function(x) print(x)`
        # x would be an empty symbol, see also ; i.e. arguments without 
        # default expressions; i.e., tagged arguments with no value
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

#' @noRd
# to determine which extra packages to load in Nix R prior evaluating `expr`
get_expr_extra_pkgs <- function(globals_expr) {
  envs_check <- lapply(globals_expr, where)
  names_envs_check <- vapply(envs_check, environmentName, character(1L))
  
  default_pkgnames <- paste0("package:", getOption("defaultPackages"))
  pkgenvs_attached <- setdiff(
    grep("^package:", names_envs_check, value = TRUE), 
    c(default_pkgnames, "base")
  )
  if (!length(pkgenvs_attached) == 0L) {
    pkgs_to_attach <- gsub("^package:", "", pkgenvs_attached)
    return(pkgs_to_attach)
  } else {
    return(NULL)
  }
}


#' @noRd
is_empty <- function(x) identical(x, emptyenv())


#' @noRd
where <- function(name, env = parent.frame()) {
  while(!is_empty(env)) {
    if (exists(name, envir = env, inherits = FALSE)) {
      return(env)
    }
    # inspect parent
    env <- parent.env(env)
  }
}

#' Finds and checks global functions and variables recursively for closure
#' `expr`
#' @noRd
recurse_find_check_globals <- function(expr,
                                       args_vec,
                                       message_type =
                                         c("simple", "quiet", "verbose")
                                       ) {
  
  message_type <- match.arg(message_type,
                            choices = c("simple", "quiet", "verbose"))
  is_quiet <- message_type == "quiet"
  
  if (message_type == "verbose") {
    cat("\n==> inspecting code recursively in call stack of `expr`...")
    codetools::checkUsage(fun = expr)
    cat("\n")
  }

  codetools::checkUsage(fun = expr)
  
  globals_expr <- codetools::findGlobals(fun = expr)
  globals_lst <- classify_globals(globals_expr, args_vec)
  
  round_i <- 1L
  
  repeat {
    
    get_globals_exprs <- function(globals_lst) {
      globals_exprs <- names(unlist(Filter(function(x) !is.null(x), 
        unname(globals_lst[c("globalenv_fun", "env_fun")]))))
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
      lapply(x,  function(x) unlist(unname(x)))
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
    globs_other <- vec_envs_check[!names(vec_envs_check) %in% 
                                    names(c(globs_pkg, globs_globalenv, globs_empty, globs_base))]
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


# wrapper to serialize expressions of all global objects found
#' @noRd
serialize_globals <- function(globals_expr,
                              temp_dir,
                              message_type = c("simple", "quiet", "verbose")) {
  message_type <- match.arg(message_type,
    choices = c("simple", "quiet", "verbose"))
  funs <- globals_expr$globalenv_fun
  if (!is.null(funs)) {
    if (message_type == "verbose") {
      cat("==> serializing global functions under `<function-name>.Rds` in
      temporary folder at",
          paste0(normalizePath(temp_dir), "...\n"), paste(names(funs)), "\n")
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
      cat("==> serializing non-function object(s), e.g., other environments",
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
    cat("==> Serializing function(s) from other environment(s):",
        paste(names(env_funs)), "\n")
    env_funs <- lapply(
      names(env_funs),
      function(x) get(x = x)
    )
    names(env_funs) <- names(globals_expr$env_fun)
    serialize_lobjs(lobjs = env_funs, temp_dir)
  }
  env_others <- globals_expr$env_other
  if (!is.null(env_others)) {
    cat("==> Serializing non-function object(s) from custom environment(s)::",
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


#' @noRd
serialize_pkgs <- function(globals_expr, temp_dir) {
  pkgs <- globals_expr$pkgs
  if (!is.null(pkgs)) {
    cat("=> Serializing package(s) required to run `expr`:\n",
        paste(pkgs), "\n"
    )
  }
  saveRDS(
    object = pkgs,
    file = file.path(temp_dir, "_pkgs.Rds")
  )
  return(pkgs)
}

# build deparsed script via language objects;
# reads like R code, and avoids code injection
quote_rnix <- function(expr,
                       program,
                       message_type,
                       args_vec,
                       globals,
                       pkgs,
                       temp_dir,
                       rnix_file) {
  expr_quoted <- bquote( {
    message_type <- .(message_type)
    is_quiet <- message_type == "quiet"
    if (isFALSE(is_quiet)) {
      cat("\n### start evaluating `expr` in `nix-shell` ###")
    }
    if (message_type == "verbose") {
      cat("\n\n* wrote R script evaluated via `Rscript` in `nix-shell`:",
          .(rnix_file))
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
          paste0("  ==> reading file ", "'", obj, ".Rds", "'",
                 " for argument named `", obj, "` ...\n")
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
          paste0("  ==> reading file ", "'", obj, ".Rds", "'",
                 " for global object named `", obj, "`\n")
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
      cat("\n* The type of the output object returned by `expr` is",
          paste0(typeof(rnix_out), ".\n"))
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
  } ) # end of `bquote()`
  
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

#' @noRd
with_assign_vec_call <- function(vec) {
  cl <- call("c")
  for (i in seq_along(vec)) {
    cl[[i + 1L]] <- vec[i]
  }
  return(cl)
}

# this is what `deparse1()` does, however, it is only since 4.0.0
#' @noRd
deparse_chr1 <- function(expr, width.cutoff = 500L, collapse = " ", ...) {
  paste(deparse(expr, width.cutoff, ...), collapse = collapse)
}

#' @noRd
with_expr_deparse <- function(expr) {
  sprintf(
    'run_expr <- %s\n',
    deparse_chr1(expr = expr, collapse = "\n")
  )
}

#' @noRd
nix_shell_available <- function() {
  which_nix_shell <- Sys.which("nix-shell")
  if (nzchar(which_nix_shell)) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

#' @noRd
create_shell_nix <- function(path = file.path("inst", "extdata", 
                                              "with_nix", "default.nix")) {
  if (!dir.exists(dirname(path))) {
    dir.create(dirname(path), recursive = TRUE)
  }
  
  rix(
    r_ver = "latest",
    r_pkgs = NULL,
    system_pkgs = NULL,
    git_pkgs = NULL,
    ide = "other",
    project_path = dirname(path),
    overwrite = TRUE,
    shell_hook = NULL
  )
}
