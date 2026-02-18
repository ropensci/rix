#' fetchgit Downloads and installs a package hosted of Git
#' @param git_pkg A list of three elements: "package_name", the name of the
#'   package, "repo_url", the repository's url, "commit", the commit hash of
#'   interest.
#' @param ... Further arguments passed down to methods.
#' @return A character. The Nix definition to download and build the R package
#'   from GitHub.
#' @noRd
fetchgit <- function(git_pkg, ...) {
  package_name <- git_pkg$package_name
  repo_url <- git_pkg$repo_url
  commit <- git_pkg$commit
  output <- nix_hash(repo_url, commit, ...)
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

  if (is.list(remotes) && length(remotes) == 0) {
    # if no remote dependencies

    output <- main_package_expression
  } else {
    # if there are remote dependencies, start over

    remote_packages_expressions <- fetchgits(remotes, ...)

    output <- paste0(
      remote_packages_expressions,
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
generate_git_nix_expression <- function(
  package_name,
  repo_url,
  commit,
  sri_hash,
  imports,
  remotes = NULL
) {
  # If there are remote dependencies, pass this string
  flag_remote_deps <- if (is.list(remotes) && length(remotes) == 0) {
    ""
  } else {
    # Extract package names
    remote_pkgs_names <- vapply(
      remotes,
      function(x) x$package_name,
      character(1)
    )
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
    pkgs[1],
    "/",
    paste0(pkgs[1], "_", pkgs[2]),
    ".tar.gz"
  )

  package_name <- pkgs[1]
  repo_url <- cran_archive_link

  if (is.null(sri_hash)) {
    output <- nix_hash(repo_url, commit = NULL)
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


#' Removes Base Packages from List of Packages Dependencies
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


#' Finds Dependencies of a Package from the DESCRIPTION File
#' @param path path to package
#' @param commit_date date of commit
#' @param ... Further arguments passed down to methods.
#' @importFrom utils untar
#' @return Atomic vector of packages
#' @noRd
get_imports <- function(path, commit_date, ...) {
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
    stop(
      "Path is neither a .tar.gz archive, nor pointing to a DESCRIPTION file directly."
    )
  }

  columns_of_interest <- c("Depends", "Imports", "LinkingTo")

  imports_df <- as.data.frame(read.dcf(desc_path))

  existing_columns <- intersect(columns_of_interest, colnames(imports_df))

  imports <- imports_df[, existing_columns, drop = FALSE]

  existing_remotes <- intersect("Remotes", colnames(imports_df))

  if (!identical(existing_remotes, character(0))) {
    remotes <- imports_df[, existing_remotes, drop = FALSE]
    # remotes are of the form username/packagename
    remotes <- gsub("\n", "", x = unlist(strsplit(remotes$Remotes, ",")))
    # Remove PR if present because this is difficult to handle
    remotes <- sub("#.*$", "", remotes)
    # Remove `github::`, see: https://github.com/microbiome/miaViz/blob/fdb4ded0dbb36aead1be2d5e60b626c9f0c94ae8/DESCRIPTION#L77 for an example
    remotes <- gsub("github::", "", remotes)
    remotes <- gsub("gitlab::", "", remotes)
    # Only keep part after @ if it is a commit sha(7-40 hex chars)
    remotes <- unname(vapply(
      remotes,
      function(x) {
        parts <- strsplit(x, "@")[[1]]
        if (length(parts) == 1) {
          return(parts[1])
        }
        ref <- parts[2]
        if (grepl("^[0-9a-f]{7,40}$", ref)) {
          return(x)
        }
        return(parts[1])
      },
      character(1)
    ))

    # Process remotes - handle both short format (username/repo) and full URLs
    urls <- vapply(
      remotes,
      normalize_git_url,
      character(1)
    )

    # Extract package names and refs from remotes
    remote_pkgs_names_and_refs <- lapply(remotes, function(remote) {
      # Remove URL prefix if present
      if (grepl("^https://", remote)) {
        # Extract username/repo part from URL
        remote <- sub("^https://[^/]+/", "", remote)
      }
      # Now split by / to get the repo name
      parts <- strsplit(remote, "/")[[1]]
      if (length(parts) >= 2) {
        # Get the last part (repo name, potentially with @commit)
        repo_and_ref <- parts[length(parts)]
        # Split by @ to separate name and ref
        name_ref <- strsplit(repo_and_ref, "@")[[1]]
        return(list(name_ref))
      } else {
        return(list(parts))
      }
    })

    # Get package names
    remote_pkgs_names <- vapply(
      remote_pkgs_names_and_refs,
      function(x) x[[1]][1],
      character(1)
    )

    # Check which packages are already in cache to avoid unnecessary warnings
    cache_file <- get_cache_file()
    cache <- readRDS(cache_file)

    # Filter out packages already seen
    packages_to_resolve <- !remote_pkgs_names %in% cache$seen_packages

    # try to get commit hash for each package if not already provided and not in cache
    remote_pkgs_refs <- lapply(
      seq_along(remote_pkgs_names_and_refs),
      function(i) {
        if (packages_to_resolve[i]) {
          resolve_package_commit(
            remote_pkgs_names_and_refs[[i]][[1]],
            commit_date,
            remotes,
            ...
          )
        } else {
          # Package already processed - we still need to include it in remotes
          # so it gets added to propagatedBuildInputs with ++ [ pkg_name ]
          # Use empty string as placeholder since commit isn't used for this purpose
          ""
        }
      }
    )

    # Build remote_pkgs list (keep all packages, including cached ones)
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
  # Keep only lines that start with "import(" or "importFrom("
  namespace_imports <- grep(
    "^(import|importFrom)\\(",
    namespace_raw,
    value = TRUE
  )

  if (length(namespace_imports) > 0) {
    # Extract the package name (first argument inside parentheses)
    namespace_imports_pkgs <- sub(
      # capture word or quoted string before first comma or closing paren
      '^import(?:From)?\\(([^,\\)]+).*',
      '\\1',
      namespace_imports
    )
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
  # Also convert remote package names to underscores to match
  remote_pkgs_names_underscore <- gsub("\\.", "_", remote_pkgs_names)
  output_imports <- setdiff(output, remote_pkgs_names_underscore)

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
#' @param ... Further arguments passed down to methods.
#' @return A character. The Nix definition to download and build the R package
#' from GitHub.
#' @noRd
fetchgits <- function(git_pkgs, ...) {
  # Check if ignore_remotes_cache was passed
  # If not passed, ignore_remotes_cache is FALSE
  args <- list(...)
  ignore_remotes_cache <- if (!is.null(args$ignore_remotes_cache)) {
    args$ignore_remotes_cache
  } else {
    FALSE
  }

  if (!ignore_remotes_cache) {
    cache_file <- get_cache_file()
    cache <- readRDS(cache_file)
    if (!all(vapply(git_pkgs, is.list, logical(1)))) {
      if (git_pkgs$package_name %in% cache$seen_packages) {
        return("")
      }
      cache$seen_packages <- c(cache$seen_packages, git_pkgs$package_name)
      saveRDS(cache, cache_file)
      fetchgit(git_pkgs, ...)
    } else if (all(vapply(git_pkgs, is.list, logical(1)))) {
      # Re-order list of git packages by "package name"
      git_pkgs <- git_pkgs[order(vapply(
        git_pkgs,
        "[[",
        character(1),
        "package_name"
      ))]
      # Filter out already processed packages
      git_pkgs <- git_pkgs[
        !vapply(
          git_pkgs,
          function(x) x$package_name %in% cache$seen_packages,
          logical(1)
        )
      ]

      cache$seen_packages <- c(
        cache$seen_packages,
        vapply(git_pkgs, "[[", character(1), "package_name")
      )

      saveRDS(cache, cache_file)
      paste(lapply(git_pkgs, function(pkg) fetchgit(pkg, ...)), collapse = "\n")
    } else {
      stop(
        "There is something wrong with the input. Make sure it is either a list of three elements ",
        "'package_name', 'repo_url' and 'commit', or a list of lists with these three elements"
      )
    }
  } else {
    # When ignoring cache, process all packages without checking cache
    if (!all(vapply(git_pkgs, is.list, logical(1)))) {
      fetchgit(git_pkgs, ...)
    } else if (all(vapply(git_pkgs, is.list, logical(1)))) {
      git_pkgs <- git_pkgs[order(vapply(
        git_pkgs,
        "[[",
        character(1),
        "package_name"
      ))]
      paste(lapply(git_pkgs, fetchgit, ...), collapse = "\n")
    } else {
      stop(
        "There is something wrong with the input. Make sure it is either a list of three elements ",
        "'package_name', 'repo_url' and 'commit', or a list of lists with these three elements"
      )
    }
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
#' @param ... Further arguments passed down to methods.
#' @return Nix definition string for building the packages
#' @noRd
fetchpkgs <- function(git_pkgs, archive_pkgs, ...) {
  args <- list(...)
  ignore_remotes_cache <- if (!is.null(args$ignore_remotes_cache)) {
    args$ignore_remotes_cache
  } else {
    FALSE
  }

  # Initialize cache if git packages are present and not ignoring cache
  if (!is.null(git_pkgs) && !ignore_remotes_cache) {
    cache_file <- get_cache_file()
    on.exit(unlink(cache_file))
  }

  # Combine git and archive package definitions
  paste(
    fetchgits(git_pkgs, ...),
    fetchzips(archive_pkgs),
    collapse = "\n"
  )
}


#' Fetch a Package from a Git Repository
#' @param repo The repository (e.g. "r-lib/usethis" or "owner/repo")
#' @param commit_sha The commit hash of interest
#' @param platform Platform type: "github", "gitlab", or "git" (Forgejo/Gitea)
#' @param base_url Base URL for the Git platform (only for platform="git")
#' @return A character. The date of the commit.
#' @importFrom curl new_handle handle_setheaders curl_fetch_memory
#' @importFrom jsonlite fromJSON
#' @noRd
get_commit_date <- function(
  repo,
  commit_sha,
  platform = "github",
  base_url = NULL
) {
  # Construct API URL based on platform
  if (platform == "github") {
    url <- paste0(
      "https://api.github.com/repos/",
      repo,
      "/commits/",
      commit_sha
    )
  } else if (platform == "gitlab") {
    # GitLab API uses project ID or URL-encoded path
    url <- paste0(
      "https://gitlab.com/api/v4/projects/",
      utils::URLencode(repo, reserved = TRUE),
      "/repository/commits/",
      commit_sha
    )
  } else if (platform == "git") {
    # Forgejo/Gitea API
    if (is.null(base_url)) {
      stop("base_url is required for platform='git'", call. = FALSE)
    }
    url <- paste0(base_url, "/api/v1/repos/", repo, "/git/commits/", commit_sha)
  } else {
    stop("Unsupported platform: ", platform, call. = FALSE)
  }

  h <- new_handle()

  # Only use GitHub token for GitHub
  if (platform == "github") {
    check_github_pat(h, repo)
  }

  tryCatch(
    {
      response <- curl_fetch_memory(url, handle = h)
      if (response$status_code != 200) {
        stop("API request failed with status code: ", response$status_code)
      }
      commit_data <- fromJSON(rawToChar(response$content))

      # Extract date based on platform-specific response structure
      if (platform == "github") {
        if (is.null(commit_data$commit$committer$date)) {
          stop("Invalid response format: missing commit date")
        }
        commit_data$commit$committer$date
      } else if (platform == "gitlab") {
        if (is.null(commit_data$committed_date)) {
          stop("Invalid response format: missing commit date")
        }
        commit_data$committed_date
      } else if (platform == "git") {
        # Forgejo/Gitea response structure
        if (!is.null(commit_data$committer$date)) {
          commit_data$committer$date
        } else if (!is.null(commit_data$created)) {
          commit_data$created
        } else {
          stop("Invalid response format: missing commit date")
        }
      }
    },
    error = function(e) {
      message(
        paste0(
          "Failed to get commit date from <<< ",
          repo,
          " >>> : ",
          e$message,
          ".\nFalling back to <<< ",
          Sys.Date(),
          " >>>.\n"
        )
      )
      return(Sys.Date())
    }
  )
}

#' download_all_commits Downloads commits (maximum 1000) from a GitHub repository
#' @param repo The GitHub repository (e.g. "r-lib/usethis")
#' @param date The target date to find the closest commit
#' @return A data frame with commit SHAs and dates
#' @importFrom curl handle_setheaders curl_fetch_memory
#' @importFrom jsonlite fromJSON
#' @noRd
download_all_commits <- function(repo, date) {
  base_url <- paste0("https://api.github.com/repos/", repo, "/commits")
  h <- new_handle()

  check_github_pat(h, repo, context = "downloading commits")
  # Limit to 10 pages of 100 commits each, so 1000 commits in total
  per_page <- 100
  max_pages <- 30
  max_commits <- per_page * max_pages

  # Pre-allocate results data frame
  all_commits <- data.frame(
    sha = character(max_commits),
    date = as.POSIXct(rep(NA, max_commits))
  )
  commit_count <- 0

  for (page in 1:max_pages) {
    url <- paste0(base_url, "?per_page=", per_page, "&page=", page)

    tryCatch(
      {
        response <- curl_fetch_memory(url, handle = h)
        if (response$status_code != 200) {
          stop("API request failed with status code: ", response$status_code)
        }

        commits <- fromJSON(rawToChar(response$content))
        if (!is.list(commits) || length(commits) == 0) {
          break
        }

        # if no commits are found, break the loop
        n_commits <- length(commits$sha)
        if (n_commits == 0) {
          break
        }

        idx <- (commit_count + 1):(commit_count + n_commits)
        all_commits$sha[idx] <- commits$sha
        all_commits$date[idx] <- as.POSIXct(
          commits$commit$committer$date,
          format = "%Y-%m-%dT%H:%M:%OSZ"
        )

        commit_count <- commit_count + n_commits

        # if the date of the last commit is before the target date, break the loop
        if (min(all_commits$date, na.rm = TRUE) < date) break
      },
      error = function(e) {
        stop("Failed to download commit data: ", e$message)
      }
    )
  }

  # Return only the rows with actual data
  all_commits[1:commit_count, ]
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
#' @param remote_pkg_name_and_ref A list containing the package name and
#'   optionally a ref
#' @param date The target date to find the closest commit
#' @param remotes A character vector of remotes
#' @param ... Further arguments passed down to methods.
#' @return A character. The commit SHA of the closest commit to the target date
#'   or "HEAD" if API fails
#' @noRd
resolve_package_commit <- function(
  remote_pkg_name_and_ref,
  date,
  remotes,
  ...
) {
  pkg_name <- remote_pkg_name_and_ref[[1]]

  # Check if ignore_remotes_cache was passed, otherwise set to FALSE
  args <- list(...)
  ignore_remotes_cache <- if (!is.null(args$ignore_remotes_cache)) {
    args$ignore_remotes_cache
  } else {
    FALSE
  }

  # Check if package is already in cache
  if (!ignore_remotes_cache) {
    cache_file <- get_cache_file()
    cache <- readRDS(cache_file)
    pkg_matches <- grep(paste0("^", pkg_name, "@"), cache$commit_cache)

    # Return commit from cache if found
    if (length(pkg_matches) > 0) {
      return(cache$commit_cache[pkg_matches[1]])
    }
  }
  # Store package name and ref in cache key if ref (commit-sha) is provided
  # otherwise set to NULL
  # example: package_name@commit_sha, e.g., schex@031320d was earlier split
  # into a list of two elements: `package_name` and `commit_sha, e.g., `schex`, `031320d`
  # and is now stored in `cache_key` as `schex@031320d` for caching
  if (!ignore_remotes_cache) {
    cache_key <- if (length(remote_pkg_name_and_ref) == 2) {
      paste0(pkg_name, "@", remote_pkg_name_and_ref[[2]])
    } else {
      NULL
    }
  }

  # If ref (commit hash, e.g. `031320d`) is provided, use it
  commit <- if (length(remote_pkg_name_and_ref) == 2) {
    remote_pkg_name_and_ref[[2]]
  } else if (length(remote_pkg_name_and_ref) == 1) {
    # For packages without ref, try to find closest one by date
    # fallback to HEAD if API fails
    tryCatch(
      {
        remotes_fetch <- remotes[grepl(remote_pkg_name_and_ref, remotes)]
        all_commits <- download_all_commits(remotes_fetch, date)
        closest_commit <- get_closest_commit(all_commits, date)
        commit <- closest_commit$sha
        cache_key <- paste0(pkg_name, "@", commit)
        commit
      },
      error = function(e) {
        message(paste0(
          "Failed to get closest commit for ",
          remotes_fetch,
          ": ",
          e$message,
          ".\nFalling back to <<< HEAD >>>\n"
        ))
        "HEAD"
      }
    )
  } else {
    stop("remote_pkg_name_and_ref must be a list of length 1 or 2")
  }
  # If not ignoring cache, Update cache with new cache_key (e.g. `schex@031320d`)
  if (!ignore_remotes_cache) {
    cache$commit_cache <- c(cache$commit_cache, cache_key)
    saveRDS(cache, cache_file)
  }

  return(commit)
}

#' Get Shared Cache File Path
#' @return Path to shared cache file
#' @noRd
get_cache_file <- function() {
  cache_file <- file.path(tempdir(), "package_cache.rds")
  if (!file.exists(cache_file)) {
    saveRDS(
      list(
        "seen_packages" = character(0),
        "commit_cache" = character(0)
      ),
      cache_file
    )
  }
  return(cache_file)
}

#' fetch_py_git Downloads and installs a Python package hosted on Git
#' @param git_pkg A list with package_name, repo_url, commit
#' @param py_ver_attr String, e.g. "python312Packages"
#' @noRd
fetch_py_git <- function(git_pkg, py_ver_attr, ...) {
  package_name <- git_pkg$package_name
  repo_url <- git_pkg$repo_url
  commit <- git_pkg$commit
  output <- nix_hash(repo_url, commit, is_python = TRUE, ...)
  sri_hash <- output$sri_hash

  propagated_inputs <- generate_py_propagated_inputs(
    output$deps$imports,
    py_ver_attr
  )

  pkg_attr <- gsub("[^a-zA-Z0-9]", "_", package_name)

  sprintf(
    '
    %s = (pkgs.%s.buildPythonPackage {
      pname = "%s";
      version = "%s-git";
      src = pkgs.fetchgit {
        url = "%s";
        rev = "%s";
        sha256 = "%s";
      };
      pyproject = true;
      build-system = [ pkgs.%s.setuptools ];
      doCheck = false;
      %s
    });
',
    pkg_attr,
    py_ver_attr,
    package_name,
    substring(commit, 1, 7),
    repo_url,
    commit,
    sri_hash,
    py_ver_attr,
    sprintf(propagated_inputs, py_ver_attr)
  )
}

#' fetch_py_gits
#' @noRd
fetch_py_gits <- function(git_pkgs, py_ver_attr, ...) {
  if (is.null(git_pkgs)) {
    return("")
  }

  # normalize to list of lists if needed
  if (!all(vapply(git_pkgs, is.list, logical(1)))) {
    git_pkgs <- list(git_pkgs)
  }

  paste(
    lapply(git_pkgs, function(pkg) fetch_py_git(pkg, py_ver_attr, ...)),
    collapse = "\n"
  )
}

#' fetch_pypi
#' @noRd
fetch_pypi <- function(pkg_descriptor, py_ver_attr, ...) {
  # Parse pkg_descriptor "name" or "name@version"
  pkg_parts <- parse_pkg_name_version(pkg_descriptor)
  pname <- pkg_parts$name
  version <- pkg_parts$version

  # Get metadata from PyPI
  meta <- get_pypi_meta(pname, version)
  real_version <- meta$version
  url <- meta$url

  # We use hash_url from nix_hash.R. It returns SRI (NAR) hash.
  # So we use fetchzip.
  output <- hash_url(url, is_python = TRUE)
  sri_hash <- output$sri_hash

  propagated_inputs <- generate_py_propagated_inputs(
    output$deps$imports,
    py_ver_attr
  )

  pkg_attr <- gsub("[^a-zA-Z0-9]", "_", pname)

  sprintf(
    '
    %s = (pkgs.%s.buildPythonPackage {
      pname = "%s";
      version = "%s";
      src = pkgs.fetchzip {
        url = "%s";
        sha256 = "%s";
      };
      pyproject = true;
      build-system = [ pkgs.%s.setuptools ];
      doCheck = false;
      %s
    });
',
    pkg_attr,
    py_ver_attr,
    pname,
    real_version,
    url,
    sri_hash,
    py_ver_attr,
    sprintf(propagated_inputs, py_ver_attr)
  )
}

#' fetch_pypis
#' @noRd
fetch_pypis <- function(pypi_pkgs, py_ver_attr, ...) {
  if (is.null(pypi_pkgs)) {
    return("")
  }
  paste(
    lapply(pypi_pkgs, function(pkg) fetch_pypi(pkg, py_ver_attr, ...)),
    collapse = "\n"
  )
}

#' get_pypi_meta
#' @importFrom jsonlite fromJSON
#' @noRd
get_pypi_meta <- function(pname, version) {
  base_url <- sprintf("https://pypi.org/pypi/%s/json", pname)
  resp <- tryCatch(
    jsonlite::fromJSON(base_url),
    error = function(e) {
      stop(paste("Failed to fetch metadata for", pname, "from PyPI"))
    }
  )

  if (version == "latest") {
    version <- resp$info$version
  }

  releases <- resp$releases[[version]]
  if (is.null(releases)) {
    stop(paste("Version", version, "not found on PyPI for package", pname))
  }

  # Find sdist
  if (is.data.frame(releases)) {
    sdist <- releases[releases$packagetype == "sdist", ]
    if (nrow(sdist) == 0) {
      stop(paste(
        "No source distribution (sdist) found for",
        pname,
        "version",
        version
      ))
    }
    url <- sdist$url[1]
  } else {
    # Fallback if jsonlite didn't simplify to data frame
    sdist <- Filter(function(x) x$packagetype == "sdist", releases)
    if (length(sdist) == 0) {
      stop(paste(
        "No source distribution (sdist) found for",
        pname,
        "version",
        version
      ))
    }
    url <- sdist[[1]]$url
  }

  list(version = version, url = url)
}

#' Normalize Git URL
#' @param remote A character, short format "username/repo" or full URL
#' @return A character, full URL
#' @noRd
normalize_git_url <- function(remote) {
  # Check if this is already a full URL
  if (grepl("^https://", remote)) {
    # Extract the URL without the @commit part
    url_parts <- strsplit(remote, "@")[[1]]
    return(url_parts[1])
  } else {
    # Short format like "username/repo" - assume GitHub
    parts <- strsplit(remote, "@")[[1]]
    return(paste0("https://github.com/", parts[1]))
  }
}

#' Parse Package Name and Version
#' @param pkg_string A character, "name" or "name@version"
#' @return A list with "name" and "version"
#' @noRd
parse_pkg_name_version <- function(pkg_string) {
  parts <- strsplit(pkg_string, "@")[[1]]
  list(
    name = parts[1],
    version = if (length(parts) > 1) parts[2] else "latest"
  )
}

#' Check for GitHub PAT and set header if available
#' @param h A curl handle
#' @param repo A character, the repository name
#' @param context A character, the context for the message
#' @noRd
check_github_pat <- function(
  h,
  repo,
  context = "fetching the commit date from GitHub"
) {
  token <- Sys.getenv("GITHUB_PAT")
  token_pattern <- "^(gh[ps]_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59})$"

  if (grepl(token_pattern, token)) {
    curl::handle_setheaders(h, Authorization = paste("token", token))
  } else {
    message(
      paste0(
        "When ",
        context,
        " from <<< ",
        repo,
        " >>>, no GitHub Personal Access Token found.\nPlease set GITHUB_PAT in your environment.\nFalling back to unauthenticated API request.\n"
      )
    )
  }
}

#' Generate propagatedBuildInputs for Python packages
#' @param imports A character vector of imports
#' @param py_ver_attr A character, the Python version attribute
#' @return A character, the Nix expression for propagatedBuildInputs
#' @noRd
generate_py_propagated_inputs <- function(imports, py_ver_attr) {
  if (!is.null(imports) && length(imports) > 0 && any(imports != "")) {
    # filter out empty strings
    imports <- imports[imports != ""]
    imports_string <- paste(imports, collapse = " ")
    sprintf(
      "propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.%s) %s;\n      };",
      py_ver_attr,
      imports_string
    )
  } else {
    "propagatedBuildInputs = [ ];"
  }
}
