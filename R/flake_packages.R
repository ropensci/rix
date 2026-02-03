# Generate packages data for reuse between default.nix and flake.nix
# This internal function separates package generation from file writing

#' generate_packages_data Internal function to generate structured package data
#' that can be used by both rix() and init_flake()
#' @param r_ver Character. R version or special value like "bleeding-edge"
#' @param date Character. Date string for nixpkgs snapshot
#' @param r_pkgs Character vector. R packages to install
#' @param system_pkgs Character vector. System packages to install
#' @param git_pkgs List. Git packages with package_name, repo_url, commit
#' @param local_r_pkgs Character vector. Local R package paths
#' @param tex_pkgs Character vector. LaTeX packages
#' @param py_conf List. Python configuration
#' @param jl_conf List. Julia configuration
#' @param ide Character. IDE to use
#' @param ignore_remotes_cache Logical. Whether to ignore remote cache
#' @noRd
generate_packages_data <- function(
  r_ver = NULL,
  date = NULL,
  r_pkgs = NULL,
  system_pkgs = NULL,
  git_pkgs = NULL,
  local_r_pkgs = NULL,
  tex_pkgs = NULL,
  py_conf = NULL,
  jl_conf = NULL,
  ide = "none",
  ignore_remotes_cache = FALSE
) {
  # Get nixpkgs URL info
  nix_repo <- make_nixpkgs_url(r_ver, date)

  # Get R packages (separates CRAN from archive)
  cran_pkgs <- get_rpkgs(r_pkgs, ide)

  # Build flags for different package types
  flag_rpkgs <- if (is.null(cran_pkgs$rPackages) || cran_pkgs$rPackages == "") {
    ""
  } else {
    "rpkgs"
  }

  flag_tex_pkgs <- if (is.null(tex_pkgs)) "" else "tex"

  flag_git_archive <- if (!is.null(git_pkgs) || !is.null(cran_pkgs$archive_pkgs)) {
    git_pkgs_names <- if (!is.null(git_pkgs)) {
      tryCatch(
        vapply(git_pkgs, function(x) x$package_name, character(1)),
        error = function(e) git_pkgs$package_name
      )
    }
    cran_archive_names <- if (!is.null(cran_pkgs$archive_pkgs)) {
      pkgs <- strsplit(cran_pkgs$archive_pkgs, split = "@")
      vapply(pkgs, function(x) x[[1]], character(1))
    }
    paste0(c(git_pkgs_names, cran_archive_names), collapse = " ")
  } else {
    ""
  }

  flag_local_r_pkgs <- if (is.null(local_r_pkgs)) "" else "local_r_pkgs"

  flag_py_conf <- if (!is.null(py_conf)) "pyconf" else ""

  flag_jl_conf <- if (!is.null(jl_conf)) "jlconf" else ""

  # Wrapper attributes
  attrib <- c(
    radian = "radianWrapper",
    rstudio = "rstudioWrapper",
    rserver = "rstudioServerWrapper"
  )

  flag_wrapper <- if (ide %in% names(attrib) && flag_rpkgs != "") {
    "wrapped_pkgs"
  } else {
    ""
  }

  # System packages
  system_pkgs_list <- get_system_pkgs(system_pkgs, r_pkgs, py_conf, ide)

  # Git/Archive package definitions (this fetches hashes if needed)
  git_archive_defs <- if (flag_git_archive != "") {
    fetchpkgs(git_pkgs, cran_pkgs$archive_pkgs, ignore_remotes_cache = ignore_remotes_cache)
  } else {
    NULL
  }

  # Return structured data
  list(
    nix_repo = nix_repo,
    r_ver = r_ver,
    date = date,
    ide = ide,
    # Package lists
    cran_pkgs = cran_pkgs,
    git_pkgs = git_pkgs,
    local_r_pkgs = local_r_pkgs,
    tex_pkgs = tex_pkgs,
    py_conf = py_conf,
    jl_conf = jl_conf,
    system_pkgs = system_pkgs,
    # Flags for buildInputs
    flags = list(
      rpkgs = flag_rpkgs,
      tex = flag_tex_pkgs,
      git_archive = flag_git_archive,
      local = flag_local_r_pkgs,
      py = flag_py_conf,
      jl = flag_jl_conf,
      wrapper = flag_wrapper
    ),
    # Pre-generated Nix expressions for special packages
    git_archive_defs = git_archive_defs,
    # System packages string
    system_pkgs_string = system_pkgs_list,
    # Wrapper attribute
    wrapper_attrib = if (ide %in% names(attrib)) attrib[ide] else NULL
  )
}


#' generate_packages_nix Internal function to generate importable Nix expression
#' for use in flakes. This generates a function that takes pkgs as argument.
#' @param pkg_data List. Output from generate_packages_data()
#' @param shell_hook Character. Custom shell hook commands
#' @noRd
generate_packages_nix <- function(pkg_data, shell_hook = NULL) {
  flags <- pkg_data$flags

  # Build R packages expression
  rpkgs_expr <- if (flags$rpkgs != "" && !is.null(pkg_data$cran_pkgs$rPackages)) {
    sprintf(
      "rpkgs = with pkgs.rPackages; [%s];",
      pkg_data$cran_pkgs$rPackages
    )
  } else {
    "rpkgs = [];"
  }

  # Build git/archive packages expression
  git_archive_expr <- if (flags$git_archive != "" && !is.null(pkg_data$git_archive_defs)) {
    # Extract package names and definitions
    sprintf(
      "git_archive_pkgs = [%s];",
      pkg_data$flags$git_archive
    )
  } else {
    "git_archive_pkgs = [];"
  }

  # Build LaTeX expression
  tex_expr <- if (flags$tex != "" && !is.null(pkg_data$tex_pkgs)) {
    tex_pkgs <- unique(c("scheme-small", sort(pkg_data$tex_pkgs)))
    tex_pkgs_str <- paste(c("", tex_pkgs), collapse = "\n      ")
    sprintf(
      "tex = (pkgs.texlive.combine {\n    inherit (pkgs.texlive)%s;\n  });",
      tex_pkgs_str
    )
  } else {
    "tex = null;"
  }

  # Build local packages expression
  local_expr <- if (flags$local != "" && !is.null(pkg_data$local_r_pkgs)) {
    sprintf(
      "local_r_pkgs = [%s];",
      fetchlocals(pkg_data$local_r_pkgs)
    )
  } else {
    "local_r_pkgs = [];"
  }

  # Build Python expression
  py_expr <- if (flags$py != "" && !is.null(pkg_data$py_conf)) {
    py_version <- paste0(
      "python",
      gsub("\\.", "", pkg_data$py_conf$py_version),
      "Packages"
    )

    py_pkgs_str <- paste(
      c("", "pip", "ipykernel", sort(pkg_data$py_conf$py_pkgs)),
      collapse = "\n      "
    )

    # Handle git and pypi packages
    py_git_str <- if (!is.null(pkg_data$py_conf$git_pkgs)) {
      fetch_py_gits(pkg_data$py_conf$git_pkgs, py_version)
    } else {
      ""
    }

    py_pypi_str <- if (!is.null(pkg_data$py_conf$pypi_pkgs)) {
      fetch_pypis(pkg_data$py_conf$pypi_pkgs, py_version)
    } else {
      ""
    }

    extra_defs <- paste(py_git_str, py_pypi_str, collapse = "\n")
    extra_pkgs <- if (nzchar(extra_defs)) {
      pkgs <- unlist(regmatches(
        extra_defs,
        gregexpr(
          "(?<=\\s)[a-zA-Z0-9_]+(?=\\s*=\\s*\\()",
          extra_defs,
          perl = TRUE
        )
      ))
      if (length(pkgs) > 0) {
        paste0(" ++ [ ", paste(pkgs, collapse = " "), " ]")
      } else {
        ""
      }
    } else {
      ""
    }

    sprintf(
      "%spyconf = builtins.attrValues {\n    inherit (pkgs.%s)%s;\n  }%s;",
      if (nzchar(extra_defs)) paste0(extra_defs, "\n  ") else "",
      py_version,
      py_pkgs_str,
      extra_pkgs
    )
  } else {
    "pyconf = [];"
  }

  # Build Julia expression
  jl_expr <- if (flags$jl != "" && !is.null(pkg_data$jl_conf)) {
    if (pkg_data$jl_conf$jl_version == "" || is.null(pkg_data$jl_conf$jl_version)) {
      jl_version <- "julia"
    } else if (pkg_data$jl_conf$jl_version == "lts") {
      jl_version <- "julia-lts"
    } else {
      jl_version <- paste0(
        "julia_",
        gsub("\\.", "", pkg_data$jl_conf$jl_version)
      )
    }
    jl_pkgs <- paste(
      c("", sprintf('"%s"', sort(pkg_data$jl_conf$jl_pkgs))),
      collapse = "\n      "
    )
    sprintf(
      "jlconf = pkgs.%s.withPackages [%s\n  ];",
      jl_version,
      jl_pkgs
    )
  } else {
    "jlconf = null;"
  }

  # Build system packages expression
  system_expr <- sprintf(
    "system_packages = with pkgs; [%s];",
    pkg_data$system_pkgs_string
  )

  # Build wrapped packages expression
  wrapper_expr <- if (flags$wrapper != "" && !is.null(pkg_data$wrapper_attrib)) {
    sprintf(
      "wrapped_pkgs = pkgs.%s.override {\n    packages = [ rpkgs git_archive_pkgs local_r_pkgs ];\n  };",
      pkg_data$wrapper_attrib
    )
  } else {
    "wrapped_pkgs = null;"
  }

  # Build shell hook
  shell_hook_str <- if (!is.null(shell_hook) && nzchar(shell_hook)) {
    shell_hook
  } else {
    ""
  }

  # Python-specific hooks
  py_shell_hook <- generate_py_shell_hook(pkg_data$py_conf, pkg_data$system_pkgs)

  all_hooks <- c(py_shell_hook, shell_hook_str)
  all_hooks <- all_hooks[nzchar(all_hooks)]

  hook_expr <- if (length(all_hooks) > 0) {
    paste0(
      "shellHook = ''\n    ",
      paste(all_hooks, collapse = "\n    "),
      "\n  '';"
    )
  } else {
    ""
  }

  # Build locale variables
  locale_vars <- generate_locale_variables()

  # Combine into final expression that returns an attrset
  # Using 'rec' so attributes can reference each other (e.g., shell references rpkgs)
  sprintf(
    "pkgs:\n\nrec {\n  %s\n\n  %s\n\n  %s\n\n  %s\n\n  %s\n\n  %s\n\n  %s\n\n  %s\n\n  shell = pkgs.mkShell {\n    %s\n    %s\n    %s\n    buildInputs = [ rpkgs git_archive_pkgs tex pyconf jlconf local_r_pkgs system_packages wrapped_pkgs ];\n    %s\n  };\n}",
    rpkgs_expr,
    git_archive_expr,
    tex_expr,
    local_expr,
    py_expr,
    jl_expr,
    system_expr,
    wrapper_expr,
    generate_locale_archive(detect_os()),
    locale_vars,
    if (flags$py != "") generate_set_reticulate(pkg_data$py_conf, flags$py) else "",
    hook_expr
  )
}
