#' Initialize a Nix Flake for the project
#'
#' @description
#' This function generates a Nix flake configuration for the project,
#' providing a modern interface to Nix with lock file support for exact
#' reproducibility. Flakes allow declarative specification of dependencies,
#' multiple development shells, and easy sharing of development environments.
#'
#' This function is **experimental** and complements the existing `rix()`
#' function. While `rix()` generates a `default.nix` file compatible with
#' traditional Nix workflows, `flake()` generates a `flake.nix` that
#' provides additional features like lock files, multiple shells, and
#' integration with the modern Nix ecosystem.
#'
#' @inheritParams rix
  #' @param template Character, the flake template to use. One of:
  #'   - `"minimal"`: Basic R environment (default)
  #'   - `"docker"`: OCI container generation
  #' 
  #' Additional templates (radian, rstudio, vscode, positron) are planned for
  #' future releases.
#' @param git_tracking Logical, defaults to `TRUE`. If `TRUE`, warn if
#'   the generated `.rixpackages.nix` is not tracked by git (required for flakes).
#' @return Invisibly returns the path to the generated `flake.nix` file.
#'   Side effects: Creates `flake.nix`, `.rixpackages.nix`, and optionally
#'   `flake.lock` if Nix is available.
#' @export
#' @family core functions
#' @examples
#' \dontrun{
#' # Initialize a minimal flake
#' flake(
#'   r_ver = "4.3.1",
#'   r_pkgs = c("dplyr", "ggplot2"),
#'   project_path = "."
#' )
#'
#' # Initialize a flake with Docker support
#' flake(
#'   r_ver = "4.3.1",
#'   r_pkgs = c("dplyr", "ggplot2", "plumber"),
#'   template = "docker",
#'   project_path = "."
#' )
#' }
flake <- function(
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
  template = "minimal",
  project_path = ".",
  overwrite = FALSE,
  git_tracking = TRUE,
  message_type = "simple",
  shell_hook = NULL,
  ignore_remotes_cache = FALSE
) {
  message_type <- match.arg(message_type, choices = c("quiet", "simple", "verbose"))

  # Validate template
  valid_templates <- c("minimal", "docker")
  if (!(template %in% valid_templates)) {
    stop(
      "Invalid template '", template, "'. Choose one of: ",
      paste(valid_templates, collapse = ", ")
    )
  }

  # Check if Nix is installed (optional, but warn if not)
  has_nix <- has_nix_installed()
  if (!has_nix && message_type != "quiet") {
    message(
      "Note: Nix does not appear to be installed. ",
      "You can still generate the flake files, but won't be able to use them until Nix is installed.\n",
      "Install Nix: https://determinate.systems/nix"
    )
  }

  # Check if project_path is a git repository (flakes require git)
  if (git_tracking && !is_git_repo(project_path)) {
    if (message_type != "quiet") {
      message(
        "Note: '", project_path, "' is not a git repository. ",
        "Flakes require files to be tracked by git.\n",
        "Run: git init && git add ."
      )
    }
  }

  # Generate structured package data
  pkg_data <- generate_packages_data(
    r_ver = r_ver,
    date = date,
    r_pkgs = r_pkgs,
    system_pkgs = system_pkgs,
    git_pkgs = git_pkgs,
    local_r_pkgs = local_r_pkgs,
    tex_pkgs = tex_pkgs,
    py_conf = py_conf,
    jl_conf = jl_conf,
    ide = ide,
    ignore_remotes_cache = ignore_remotes_cache
  )

  # Create project directory if needed
  if (isFALSE(dir.exists(project_path))) {
    dir.create(path = project_path, recursive = TRUE)
  }
  project_path <- normalizePath(path = project_path)

  # Define file paths
  flake_path <- file.path(project_path, "flake.nix")
  packages_path <- file.path(project_path, ".rixpackages.nix")

  # Check overwrite
  if (file.exists(flake_path) && !overwrite) {
    stop(
      "flake.nix already exists in ", project_path,
      ". Set overwrite = TRUE to overwrite."
    )
  }

  # Generate .rixpackages.nix (importable package definitions)
  packages_nix <- generate_packages_nix(pkg_data, shell_hook)
  packages_nix <- clean_nix_expression(packages_nix)

  # Write .rixpackages.nix
  con_packages <- file(packages_path, open = "wb", encoding = "native.enc")
  writeLines(enc2utf8(packages_nix), con = con_packages, useBytes = TRUE)
  close(con_packages)

  # Copy flake template
  template_path <- system.file(
    "flake_templates",
    template,
    "flake.nix",
    package = "rix"
  )

  if (!file.exists(template_path)) {
    stop(
      "Template file not found: ", template_path,
      "\nPackage installation may be incomplete."
    )
  }

  # Read template
  flake_template <- readLines(template_path)

  # Customize template based on pkg_data
  flake_content <- customize_flake_template(
    flake_template,
    pkg_data,
    template
  )

  # Write flake.nix
  con_flake <- file(flake_path, open = "wb", encoding = "native.enc")
  writeLines(enc2utf8(flake_content), con = con_flake, useBytes = TRUE)
  close(con_flake)

  # Check git tracking
  if (git_tracking && is_git_repo(project_path)) {
    tracked <- is_file_tracked(packages_path, project_path)
    if (!tracked && message_type != "quiet") {
      message(
        "\n⚠ .rixpackages.nix is not tracked by git.\n",
        "Flakes require all files to be tracked. Run:\n",
        "  git add .rixpackages.nix flake.nix\n",
        "  git commit -m 'Add Nix flake'"
      )
    }
  }

  # Generate flake.lock if Nix is available
  if (has_nix) {
    if (message_type == "verbose") {
      message("\nGenerating flake.lock (this may take a moment)...")
    }

    result <- tryCatch({
      sys::exec_internal(
        "nix",
        args = c("flake", "update", project_path),
        error = FALSE
      )
    }, error = function(e) {
      list(status = 1, stderr = as.character(e))
    })

    if (result$status != 0 && message_type != "quiet") {
      message(
        "\n⚠ Failed to generate flake.lock. Run manually:\n",
        "  nix flake update"
      )
    }
  }

  # Success message
  if (message_type != "quiet") {
    message(
      "\n✓ Successfully generated flake.nix in ", project_path, "\n",
      "\nNext steps:\n",
      "  1. Review flake.nix and customize if needed\n",
      "  2. Run: git add .rixpackages.nix flake.nix flake.lock\n",
      "  3. Enter the environment: nix develop\n",
      "\nAvailable shells:\n",
      "  nix develop          # Default shell\n",
      if (template == "docker") "  nix build .#docker   # Build container\n",
      "\nLearn more: ?flake"
    )
  }

  invisible(flake_path)
}

#' Check if Nix is installed
#' @noRd
has_nix_installed <- function() {
  tryCatch({
    result <- sys::exec_internal("which", args = "nix", error = FALSE)
    result$status == 0
  }, error = function(e) {
    FALSE
  })
}

#' Check if directory is a git repository
#' @noRd
is_git_repo <- function(path) {
  git_dir <- file.path(path, ".git")
  file.exists(git_dir) && dir.exists(git_dir)
}

#' Check if file is tracked by git
#' @noRd
is_file_tracked <- function(file_path, repo_path) {
  tryCatch({
    result <- sys::exec_internal(
      "git",
      args = c("-C", repo_path, "ls-files", "--error-unmatch", file_path),
      error = FALSE
    )
    result$status == 0
  }, error = function(e) {
    FALSE
  })
}

#' Clean up Nix expression (remove consecutive empty lines)
#' @noRd
clean_nix_expression <- function(content) {
  lines <- strsplit(content, "\n")[[1]]
  # Remove consecutive empty lines
  keep <- !(lines == "" & c(FALSE, head(lines, -1) == ""))
  paste(lines[keep], collapse = "\n")
}

#' Customize flake template based on package data
#' @noRd
customize_flake_template <- function(template_lines, pkg_data, template) {
  # Get nixpkgs URL
  nix_repo <- pkg_data$nix_repo

  # Replace {{NIXPKGS_URL}} with actual URL
  template_lines <- gsub(
    "\\{\\{NIXPKGS_URL\\}\\}",
    nix_repo$url,
    template_lines
  )

  # Replace {{NIXPKGS_REV}} with revision (for inputs)
  template_lines <- gsub(
    "\\{\\{NIXPKGS_REV\\}\\}",
    nix_repo$latest_commit,
    template_lines
  )

  # Replace {{R_VERSION}} with R version for documentation
  r_ver_text <- if (!is.null(pkg_data$r_ver) && nchar(pkg_data$r_ver) > 20) {
    substr(pkg_data$r_ver, 1, 7)
  } else if (is.null(pkg_data$r_ver)) {
    pkg_data$date
  } else {
    pkg_data$r_ver
  }
  template_lines <- gsub("\\{\\{R_VERSION\\}\\}", r_ver_text, template_lines)

  # Replace {{TEMPLATE}} with template name
  template_lines <- gsub("\\{\\{TEMPLATE\\}\\}", template, template_lines)

  # Add cachix substituters for rstats-on-nix if using rstats-on-nix
  if (grepl("rstats-on-nix", nix_repo$url)) {
    # Add nixConfig section after description
    nix_config <- c(
      "",
      "  nixConfig = {",
      "    extra-substituters = [",
      '      "https://rstats-on-nix.cachix.org"',
      "    ];",
      "    extra-trusted-public-keys = [",
      '      "rstats-on-nix.cachix.org-1:ylMXt/GRAA2NJ3PvfHYjbgS7XyXq8kLl3fDbvmqDGE8="',
      "    ];",
      "  };"
    )

    # Find where to insert (after description line)
    desc_idx <- grep('^\\s*description\\s*=', template_lines)
    if (length(desc_idx) > 0) {
      template_lines <- append(template_lines, nix_config, after = desc_idx[1])
    }
  }

  paste(template_lines, collapse = "\n")
}

#' List available flake templates
#'
#' @description
#' Lists all available flake templates that can be used with `flake()`.
#'
#' @return Character vector of available template names.
#' @export
#' @examples
#' flake_templates()
flake_templates <- function() {
  template_dir <- system.file("flake_templates", package = "rix")

  if (!dir.exists(template_dir)) {
    return(character(0))
  }

  templates <- list.dirs(template_dir, full.names = FALSE, recursive = FALSE)
  templates[templates != ""]
}

#' Update Nix Flake Lock File
#'
#' @description
#' Updates the `flake.lock` file by running `nix flake update` in the specified
#' directory. This fetches the latest versions of all flake inputs (including
#' nixpkgs) and updates the lock file accordingly.
#'
#' @param project_path Character, path to the directory containing `flake.nix`.
#'   Defaults to the current directory.
#' @param message_type Character, message verbosity. One of "quiet", "simple",
#'   or "verbose". Defaults to "simple".
#' @return Invisibly returns the result of the nix command.
#' @export
#' @family flake helpers
#' @examples
#' \dontrun{
#' # Update flake.lock in current directory
#' flake_update()
#'
#' # Update in specific project
#' flake_update("~/my-project")
#' }
flake_update <- function(
  project_path = ".",
  message_type = "simple"
) {
  message_type <- match.arg(message_type, choices = c("quiet", "simple", "verbose"))

  # Check if Nix is installed
  if (!has_nix_installed()) {
    stop("Nix is not installed. Install Nix to use flakes.")
  }

  # Check if flake.nix exists
  flake_file <- file.path(project_path, "flake.nix")
  if (!file.exists(flake_file)) {
    stop("No flake.nix found in ", project_path)
  }

  if (message_type != "quiet") {
    message("Updating flake.lock in ", normalizePath(project_path), "...")
  }

  # Run nix flake update
  result <- tryCatch({
    if (message_type == "verbose") {
      sys::exec_wait(
        "nix",
        args = c("flake", "update", project_path)
      )
    } else {
      sys::exec_internal(
        "nix",
        args = c("flake", "update", project_path),
        error = FALSE
      )
    }
  }, error = function(e) {
    stop("Failed to update flake: ", conditionMessage(e))
  })

  if (message_type != "quiet") {
    if (result$status == 0) {
      message("✓ Flake lock file updated successfully")
    } else {
      message("✗ Failed to update flake lock file")
      if (!is.null(result$stderr)) {
        message("Error: ", rawToChar(result$stderr))
      }
    }
  }

  invisible(result)
}

#' Check Nix Flake Configuration
#'
#' @description
#' Validates the `flake.nix` file by running `nix flake check` which verifies
#' that the flake is syntactically correct and all dependencies can be resolved.
#'
#' @param project_path Character, path to the directory containing `flake.nix`.
#'   Defaults to the current directory.
#' @param message_type Character, message verbosity. One of "quiet", "simple",
#'   or "verbose". Defaults to "simple".
#' @return Logical: TRUE if check passed, FALSE otherwise (invisibly).
#' @export
#' @family flake helpers
#' @examples
#' \dontrun{
#' # Check flake in current directory
#' flake_check()
#'
#' # Check with verbose output
#' flake_check("~/my-project", message_type = "verbose")
#' }
flake_check <- function(
  project_path = ".",
  message_type = "simple"
) {
  message_type <- match.arg(message_type, choices = c("quiet", "simple", "verbose"))

  # Check if Nix is installed
  if (!has_nix_installed()) {
    stop("Nix is not installed. Install Nix to use flakes.")
  }

  # Check if flake.nix exists
  flake_file <- file.path(project_path, "flake.nix")
  if (!file.exists(flake_file)) {
    stop("No flake.nix found in ", project_path)
  }

  if (message_type != "quiet") {
    message("Checking flake configuration in ", normalizePath(project_path), "...")
  }

  # Run nix flake check
  result <- tryCatch({
    if (message_type == "verbose") {
      sys::exec_wait(
        "nix",
        args = c("flake", "check", project_path)
      )
    } else {
      sys::exec_internal(
        "nix",
        args = c("flake", "check", project_path),
        error = FALSE
      )
    }
  }, error = function(e) {
    list(status = 1, stderr = charToRaw(conditionMessage(e)))
  })

  success <- result$status == 0

  if (message_type != "quiet") {
    if (success) {
      message("✓ Flake check passed")
    } else {
      message("✗ Flake check failed")
      if (!is.null(result$stderr)) {
        stderr_text <- rawToChar(result$stderr)
        message("Error output:\n", stderr_text)
      }
    }
  }

  invisible(success)
}

#' Show Nix Flake Metadata
#'
#' @description
#' Displays metadata about the flake including inputs, outputs, and descriptions
#' by running `nix flake metadata`.
#'
#' @param project_path Character, path to the directory containing `flake.nix`.
#'   Defaults to the current directory.
#' @return Invisibly returns the result of the nix command.
#' @export
#' @family flake helpers
#' @examples
#' \dontrun{
#' flake_metadata()
#' }
flake_metadata <- function(project_path = ".") {
  # Check if Nix is installed
  if (!has_nix_installed()) {
    stop("Nix is not installed. Install Nix to use flakes.")
  }

  # Check if flake.nix exists
  flake_file <- file.path(project_path, "flake.nix")
  if (!file.exists(flake_file)) {
    stop("No flake.nix found in ", project_path)
  }

  # Run nix flake metadata
  result <- tryCatch({
    sys::exec_wait(
      "nix",
      args = c("flake", "metadata", project_path)
    )
  }, error = function(e) {
    stop("Failed to get flake metadata: ", conditionMessage(e))
  })

  invisible(result)
}
