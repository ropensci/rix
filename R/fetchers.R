#' fetchgit Downloads and installs a package hosted of Git
#' @param git_pkg A list of three elements: "package_name", the name of the
#'   package, "repo_url", the repository's url, "commit", the commit hash of
#'   interest.
#' @return A character. The Nix definition to download and build the R package
#'   from Github.
#' @noRd
fetchgit <- function(git_pkg) {
  package_name <- git_pkg$package_name
  repo_url <- git_pkg$repo_url
  commit <- git_pkg$commit

  output <- get_sri_hash_deps(repo_url, commit)
  sri_hash <- output$sri_hash
  # If package has no remote dependencies

  imports <- output$deps$imports
  imports <- paste(c("", imports), collapse = "\n          ")

  remotes <- output$deps$remotes

  main_package_expression <- generate_git_nix_expression(
    package_name,
    repo_url,
    commit,
    sri_hash,
    imports,
    remotes
  )

  if (is.null(remotes)) { # if no remote dependencies

    output <- main_package_expression
  } else { # if there are remote dependencies, start over
    remote_packages_expressions <- fetchgits(remotes)

    output <- paste0(remote_packages_expressions,
      main_package_expression,
      collapse = "\n"
    )
  }

  output
}


generate_git_nix_expression <- function(package_name,
                                        repo_url,
                                        commit,
                                        sri_hash,
                                        imports,
                                        remote_deps = NULL) {
  # If there are remote dependencies, pass this string
  flag_remote_deps <- if (is.null(remote_deps)) {
    ""
  } else {
    # Extract package names
    remote_pkgs_names <- sapply(remote_deps, function(x) x$package_name)
    paste0(" ++ [ ", paste0(remote_pkgs_names, collapse = " "), " ]")
  }

  sprintf(
    '
    %s = (pkgs.rPackages.buildRPackage {
      name = \"%s\";
      src = pkgs.fetchgit {
        url = \"%s\";
        rev = \"%s\";
        sha256 = \"%s\";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) %s;
      }%s;
    });
',
    package_name,
    package_name,
    repo_url,
    commit,
    sri_hash,
    imports,
    flag_remote_deps
  )
}


#' fetchzip Downloads and installs an archived CRAN package
#' @param archive_pkg A character of the form `"dplyr@0.80"`
#' @return A character. The Nix definition to download and build the R package
#'   from CRAN.
#' @noRd
fetchzip <- function(archive_pkg, sri_hash = NULL) {
  pkgs <- unlist(strsplit(archive_pkg, split = "@"))

  cran_archive_link <- paste0(
    "https://cran.r-project.org/src/contrib/Archive/",
    pkgs[1], "/",
    paste0(pkgs[1], "_", pkgs[2]),
    ".tar.gz"
  )

  package_name <- pkgs[1]
  repo_url <- cran_archive_link

  if (is.null(sri_hash)) {
    output <- get_sri_hash_deps(repo_url, commit = NULL)
    sri_hash <- output$sri_hash
    imports <- output$deps$imports
    imports <- paste(c("", imports), collapse = "\n          ")
  } else {
    sri_hash <- sri_hash
    imports <- NULL
  }

  sprintf(
    '
    %s = (pkgs.rPackages.buildRPackage {
      name = \"%s\";
      src = pkgs.fetchzip {
       url = \"%s\";
       sha256 = \"%s\";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) %s;
      };
    }),
',
    package_name,
    package_name,
    repo_url,
    sri_hash,
    imports
  )
}


#' Removes base packages from list of packages dependencies
#' @param list_imports Atomic vector of packages
#' @importFrom stats na.omit
#' @return Atomic vector of packages without base packages
#' @noRd
remove_base <- function(list_imports) {
  imports_nobase <- gsub(
    paste0(
      "(^base$)|(^compiler$)|(^datasets$)|(^grDevices$)|(^graphics$)|(^grid$)|",
      "(^methods$)|(^parallel$)|(^profile$)|(^splines$)|(^stats$)|",
      "(^stats4$)|(^tcltk$)|(^tools$)|(^translations$)|(^utils$)"
    ),
    NA_character_,
    list_imports
  )

  na.omit(imports_nobase)
}


#' Finds dependencies of a package from the DESCRIPTION file
#' @param path path to package
#' @importFrom utils untar
#' @return Atomic vector of packages
#' @noRd
get_imports <- function(path) {
  tmpdir <- tempdir()
  on.exit(unlink(tmpdir, recursive = TRUE, force = TRUE), add = TRUE)

  tmp_dir <- tempfile(pattern = "file", tmpdir = tmpdir, fileext = "")
  if (!dir.exists(tmp_dir)) {
    dir.create(tmp_dir, recursive = TRUE)
  }
  on.exit(
    unlink(tmp_dir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  # Some packages have a Description file in the testthat folder
  # (see jimhester/lookup) so we need to get rid of that
  path <- Filter(function(x) !grepl("testthat", x), path)

  # Is the path pointing to a tar.gz archive
  # or directly to a DESCRIPTION file?
  if (grepl("\\.tar\\.gz", path)) {
    untar(path, exdir = tmp_dir)
    paths <- list.files(tmp_dir, full.names = TRUE, recursive = TRUE)
    desc_path <- grep("DESCRIPTION", paths, value = TRUE)
  } else if (grepl("DESCRIPTION", path)) {
    desc_path <- path
  } else {
    stop("Path is neither a .tar.gz archive, nor pointing to a DESCRIPTION file directly.")
  }

  columns_of_interest <- c("Depends", "Imports", "LinkingTo")

  imports_df <- as.data.frame(read.dcf(desc_path))

  existing_columns <- intersect(columns_of_interest, colnames(imports_df))

  imports <- imports_df[, existing_columns, drop = FALSE]

  existing_remotes <- intersect("Remotes", colnames(imports_df))

  if (!identical(existing_remotes, character(0))) {
    remotes <- imports_df[, existing_remotes, drop = FALSE]
    # remotes are of the form username/packagename so we need
    # to only keep packagename
    remotes <- gsub("\n", "", x = unlist(strsplit(remotes$Remotes, ",")))
    remote_pkgs_names <- sub(".*?/", "", remotes)
    urls <- paste0("https://github.com/", remotes)
    commits <- rep("HEAD", length(remotes))
    remote_pkgs <- lapply(seq_along(remote_pkgs_names), function(i) {
      list(
        "package_name" = remote_pkgs_names[i],
        "repo_url" = urls[i],
        "commit" = commits[i]
      )
    })
  } else {
    remote_pkgs_names <- character(0)
    remote_pkgs <- NULL
  }

  if (!is.null(imports) && length(imports) > 0) {
    output <- unname(trimws(unlist(strsplit(unlist(imports), split = ","))))
  } else {
    output <- character(0)
  }

  # Remove version of R that may be listed in 'Depends'
  output <- Filter(function(x) !grepl("R \\(.*\\)", x), output)

  # Remove minimum package version for example 'packagename ( > 1.0.0)'
  output <- trimws(gsub("\\(.*?\\)", "", output))

  output <- remove_base(unique(output))

  output <- gsub("\\.", "_", output)

  # Remote packages are included in imports, so we need
  # remove remotes from imports
  output_imports <- setdiff(output, remote_pkgs_names)

  list(
    "package" = imports_df$Package,
    "imports" = output_imports,
    "remotes" = remote_pkgs
  )
}


#' fetchlocal Installs a local R package
#' @param local_pkg A list of local package names ('.tar.gz' archives) to
#' install. These packages need to be in the same folder as the generated
#' `default.nix` file.
#' @importFrom utils tail
#' @return A character. The Nix definition to build the R package from local sources.
#' @noRd
fetchlocal <- function(local_pkg) {
  its_imports <- get_imports(local_pkg) |>
    strsplit(split = " ") |>
    unlist()

  its_imports <- paste(c("", its_imports), collapse = "\n          ")

  # Remove package version from name
  package_name <- unlist(strsplit(local_pkg, split = "_"))

  package_name <- package_name[1]

  # Remove rest of path from name
  package_name <- tail(unlist(strsplit(package_name, split = "/")), 1)

  sprintf(
    '
  (pkgs.rPackages.buildRPackage {
    name = \"%s\";
    src = ./%s;
    propagatedBuildInputs = builtins.attrValues {
     inherit (pkgs.rPackages) %s;
    };
  })
',
    package_name,
    local_pkg,
    its_imports
  )
}

#' fetchlocals Installs a local R package
#' @param local_r_pkgs Either a list of paths to local packages, or a path to a
#' single package
#' @return A character. The Nix definition to build the local R packages from
#' local sources.
#' @noRd
fetchlocals <- function(local_r_pkgs) {
  paths_exist <- file.exists(local_r_pkgs)

  if (!all(paths_exist)) {
    stop(
      paste0(
        "local_r_pkgs: The following paths are incorrect:\n",
        paste(local_r_pkgs[!paths_exist], collapse = "\n")
      )
    )
  } else if (length(local_r_pkgs) == 1) {
    fetchlocal(local_r_pkgs)
  } else {
    paste(lapply(sort(local_r_pkgs), fetchlocal), collapse = "\n")
  }
}



#' fetchgits Downloads and installs packages hosted on Git. Wraps `fetchgit()`
#' to handle multiple packages
#' @param git_pkgs A list of three elements: "package_name", the name of the
#' package, "repo_url", the repository's url and "commit", the commit hash of
#' interest. This argument can also be a list of lists of these three elements.
#' @return A character. The Nix definition to download and build the R package
#' from Github.
#' @noRd
fetchgits <- function(git_pkgs) {
  if (!all(vapply(git_pkgs, is.list, logical(1)))) {
    fetchgit(git_pkgs)
  } else if (all(vapply(git_pkgs, is.list, logical(1)))) {
    # Re-order list of git packages by "package name"
    git_pkgs <- git_pkgs[order(sapply(git_pkgs, "[[", "package_name"))]

    paste(lapply(git_pkgs, fetchgit), collapse = "\n")
  } else {
    stop(
      paste0(
        "There is something wrong with the input. ",
        "Make sure it is either a list of three elements ",
        "'package_name', 'repo_url' and 'commit', or ",
        "a list of lists with these three elements"
      )
    )
  }
}

#' fetchzips Downloads and installs packages hosted in the CRAN archives. Wraps
#' `fetchzip()` to handle multiple packages.
#' @param archive_pkgs A character, or an atomic vector of characters.
#' @return A character. The Nix definition to download and build the R package
#' from the CRAN archives.
#' @noRd
fetchzips <- function(archive_pkgs) {
  if (is.null(archive_pkgs)) {
    "" # Empty character in case the user doesn't need any packages from the CRAN archives.
  } else if (length(archive_pkgs) == 1) {
    fetchzip(archive_pkgs)
  } else if (length(archive_pkgs) > 1) {
    paste(lapply(sort(archive_pkgs), fetchzip), collapse = "\n")
  } else {
    stop(
      "There is something wrong with the input. Make sure it is either",
      "a single package name, or an atomic vector of package names, for",
      "example, `c('dplyr@0.8.0', 'tidyr@1.0.0')`."
    )
  }
}

#' fetchpkgs Downloads and installs packages from CRAN archives or Github
#' @param git_pkgs List of Git packages with name, url and commit
#' @param archive_pkgs Vector of CRAN archive package names
#' @return Nix definition string for building the packages
#' @noRd
fetchpkgs <- function(git_pkgs, archive_pkgs) {
  all_remotes <- unique(unlist(lapply(git_pkgs, get_remote)))
  
  # Only include git packages that aren't already remote dependencies
  needed_git_pkgs <- git_pkgs[!sapply(git_pkgs, function(pkg) {
    pkg$package_name %in% all_remotes
  })]

  # Combine git and archive package definitions
  paste(
    fetchgits(needed_git_pkgs),
    fetchzips(archive_pkgs),
    collapse = "\n"
  )
}

#' get_remote Retrieves the names of remote dependencies for a given Git package
#' @param git_pkg A list of three elements: "package_name", the name of the
#'   package, "repo_url", the repository's URL, and "commit", the commit hash of
#'   interest.
#' @return A character vector containing the names of remote dependencies.
#' @noRd
get_remote <- function(git_pkg) {
  repo_url <- git_pkg$repo_url
  commit <- git_pkg$commit
  output <- get_sri_hash_deps(repo_url, commit)
  remotes <- output$deps$remotes
  remote_package_names <- sapply(remotes, `[[`, "package_name")
  return(remote_package_names)
}