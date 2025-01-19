#' fetchgit Downloads and installs a package hosted of Git
#' @param git_pkg A list of three elements: "package_name", the name of the
#'   package, "repo_url", the repository's url, "commit", the commit hash of
#'   interest.
#' @return A character. The Nix definition to download and build the R package
#'   from GitHub.
#' @noRd
fetchgit <- function(git_pkg) {
  package_name <- git_pkg$package_name
  repo_url <- git_pkg$repo_url
  commit <- git_pkg$commit
  repo_url_short <- paste(unlist(strsplit(repo_url, "/"))[4:5], collapse = "/")

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

  if (is.list(remotes) & length(remotes) == 0) {
    # if no remote dependencies

    output <- main_package_expression
  } else { # if there are remote dependencies, start over
    # don't include remote dependencies twice
    # this can happen if a remote dependency of a remote dependency
    # is already present as a remote dependency
    remotes_remotes <- unique(unlist(lapply(remotes, get_remote)))
    remotes <- remotes[!sapply(remotes, function(pkg) {
      pkg$package_name %in% remotes_remotes
    })]

    remote_packages_expressions <- fetchgits(remotes)

    output <- paste0(remote_packages_expressions,
      main_package_expression,
      collapse = "\n"
    )
  }

  output
}

#' generate_git_nix_expression Generate Nix expression for fetchgit()
#' @param package_name A character, Git package name.
#' @param repo_url A character, Git repo url.
#' @param commit A character, Git commit.
#' @param sri_hash A character, hash of Git repo.
#' @param imports A list of pcakages, can be empty list
#' @param remotes A list of remotes dependencies, can be empty list
#' @return A character. Part of the Nix definition to download and build the R package
#' from the CRAN archives.
#' @noRd
generate_git_nix_expression <- function(package_name,
                                        repo_url,
                                        commit,
                                        sri_hash,
                                        imports,
                                        remotes = NULL) {
  # If there are remote dependencies, pass this string
  flag_remote_deps <- if (is.list(remotes) & length(remotes) == 0) {
    ""
  } else {
    # Extract package names
    remote_pkgs_names <- sapply(remotes, function(x) x$package_name)
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
    });
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
#' @param commit_date date of commit
#' @importFrom utils untar
#' @return Atomic vector of packages
#' @noRd
get_imports <- function(path, commit_date = NULL) {
  tmpdir <- tempdir()

  tmp_dir <- tempfile(pattern = "file", tmpdir = tmpdir, fileext = "")
  if (!dir.exists(tmp_dir)) {
    dir.create(tmp_dir, recursive = TRUE)
  }

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
    # Get user names
    remote_pkgs_usernames <- sapply(strsplit(remotes, "/"), function(x) x[[1]])

    # Now remove user name and
    # split at "@" or "#" character to get name and commit or PR separated
    remote_pkgs_names_and_refs <- sub(".*?/", "", remotes)
    remote_pkgs_names_and_refs <- strsplit(remote_pkgs_names_and_refs, "(@|#)")

    remote_pkgs_names <- sapply(remote_pkgs_names_and_refs, function(x) x[[1]])

    # try to get commit hash for each package if not already provided
    remote_pkgs_refs <- lapply(remote_pkgs_names_and_refs, function(x) {
      resolve_package_commit(x, commit_date, remotes)
    })

    urls <- paste0(
      "https://github.com/",
      remote_pkgs_usernames, "/",
      remote_pkgs_names
    )

    remote_pkgs <- lapply(seq_along(remote_pkgs_names), function(i) {
      list(
        "package_name" = remote_pkgs_names[i],
        "repo_url" = urls[i],
        "commit" = remote_pkgs_refs[i]
      )
    })
  } else {
    remote_pkgs_names <- character(0)
    remote_pkgs <- list()
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

  # Get imports from NAMESPACE
  namespace_path <- gsub("DESCRIPTION", "NAMESPACE", desc_path)
  namespace_raw <- readLines(namespace_path)
  namespace_imports <- namespace_raw[grepl("importFrom", namespace_raw)]

  if (length(namespace_imports) > 0) {
    # Get package names from `importFrom` statements
    namespace_imports_pkgs <- gsub("importFrom\\(([^,]+).*", "\\1", namespace_imports)
    # Remove quotes, which is sometimes necessary
    # example: https://github.com/cran/AER/blob/master/NAMESPACE
    namespace_imports_pkgs <- gsub("[\"']", "", namespace_imports_pkgs)
    namespace_imports_pkgs <- unique(namespace_imports_pkgs)
    # combine imports from DESCRIPTION and NAMESPACE
    output <- union(output, namespace_imports_pkgs)
  }

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
  its_imports <- get_imports(local_pkg)$imports

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
#' from GitHub.
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

#' fetchpkgs Downloads and installs packages from CRAN archives or GitHub
#' @param git_pkgs List of Git packages with name, url and commit
#' @param archive_pkgs Vector of CRAN archive package names
#' @return Nix definition string for building the packages
#' @noRd
fetchpkgs <- function(git_pkgs, archive_pkgs) {
  # Only include git packages that aren't already remote dependencies
  if (all(sapply(git_pkgs, is.list))) {
    all_remotes <- unique(unlist(lapply(git_pkgs, get_remote)))
    git_pkgs <- git_pkgs[!sapply(git_pkgs, function(pkg) {
      pkg$package_name %in% all_remotes
    })]
  }

  # Combine git and archive package definitions
  paste(
    fetchgits(git_pkgs),
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

#' get_commit_date Retrieves the date of a commit from a Git repository
#' @param repo The GitHub repository (e.g. "r-lib/usethis")
#' @param  commit_sha The commit hash of interest
#' @return A character. The date of the commit.
#' @importFrom jsonlite fromJSON
#' @noRd
get_commit_date <- function(repo, commit_sha) {
  url <- paste0("https://api.github.com/repos/", repo, "/commits/", commit_sha)
  commit_data <- fromJSON(url)
  return(commit_data$commit$committer$date)
}

#' download_all_commits Downloads up to 300 most recent commits from a GitHub repository
#' @param repo The GitHub repository (e.g. "r-lib/usethis")
#' @return A data frame with commit SHAs and dates
#' @importFrom jsonlite fromJSON
#' @noRd
download_all_commits <- function(repo) {
  base_url <- paste0("https://api.github.com/repos/", repo, "/commits")
  per_page <- 100
  max_pages <- 3  # Limit to 3 pages of 100 commits each
  all_commits <- list()

  for (page in 1:max_pages) {
    url <- paste0(base_url, "?per_page=", per_page, "&page=", page)
    commits <- fromJSON(url, simplifyVector = FALSE)
    
    if (length(commits) == 0) break
    all_commits <- c(all_commits, commits)
  }

  commits_df <- data.frame(
    sha = sapply(all_commits, function(x) x$sha),
    date = as.POSIXct(sapply(all_commits, function(x) x$commit$committer$date), 
                      format = "%Y-%m-%dT%H:%M:%OSZ")
  )
  return(commits_df)
}

#' get_closest_commit Finds the closest commit to a specific date
#' @param commits_df A data frame with commit SHAs and dates
#' @param target_date The target date to find the closest commit
#' @return A data frame with the closest commit SHA and date
#' @noRd
get_closest_commit <- function(commits_df, target_date) {
  # Convert target_date to POSIXct format
  target_date <- as.POSIXct(target_date, format = "%Y-%m-%dT%H:%M:%OSZ")
  
  # Filter commits before or on the target date
  filtered_commits <- commits_df[commits_df$date <= target_date, ]
  
  # If no commits found, raise an error
  if (nrow(filtered_commits) == 0) {
    stop("No commits found before or on the target date.")
  }

  # Find the closest commit by selecting the maximum date
  closest_commit <- filtered_commits[which.max(filtered_commits$date), ]
  return(closest_commit)
}

#' resolve_package_commit Resolves the commit SHA for a package based on a date
#' @param remote_pkg_name_and_ref A list containing the package name and optionally a ref
#' @param date The target date to find the closest commit
#' @param remotes A character vector of remotes
#' @return A character. The commit SHA of the closest commit to the target date or "HEAD" if API fails
#' @noRd
resolve_package_commit <- function(remote_pkg_name_and_ref, date, remotes) {
  # Check if remote is a list with a package name and a ref
  if (is.list(remote_pkg_name_and_ref)) {
    # Keep existing ref if present
    return(remote_pkg_name_and_ref[[2]])
  } else {
    # For packages without ref, try to find closest one by date
    # fallback to HEAD if API fails
    result <- tryCatch({
      remotes_fetch <- remotes[grepl(remote_pkg_name_and_ref, remotes)]
      all_commits <- download_all_commits(remotes_fetch)
      closest_commit <- get_closest_commit(all_commits, date)
      closest_commit$sha
    },
    error = function(e) {
      warning(paste0("Failed to get commit for ", remote_pkg_name_and_ref, 
            ": ", e$message, "\nFalling back to HEAD"))
      return("HEAD")
    })
    return(result)
  }
}
