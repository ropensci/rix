#' Return the sri hash of a path using `nix hash path --sri path` if Nix is
#' available locally
#' @param repo_url URL to Git repository
#' @param commit Commit hash (SHA-1)
#' @param ref Ref to release or branch
#' @param ... Further arguments passed down to methods.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a GitHub repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: list with three elements: 'package', its 'imports' and its 'remotes'
#' @noRd
nix_hash <- function(repo_url, commit, ref, ...) {
  if (grepl("(github)|(gitlab)", repo_url)) {
    hash_git(repo_url = repo_url, commit, ref, ...)
  } else if (grepl("cran.*Archive.*", repo_url)) {
    hash_cran(repo_url = repo_url)
  } else {
    stop(
      "repo_url argument is wrong. Please provide an url to a GitHub repo",
      "to install a package from GitHub, or to the CRAN Archive to install a",
      "package from the CRAN archive."
    )
  }
}

#' Generate regex patterns for Git hosting platforms
#'
#' @param platform Either "github" or "gitlab"
#' @return A list with regex patterns for the given platform:
#' - `has_subdir_pattern`: Pattern to check if a URL has a subdirectory
#' - `extract_subdir_pattern`: Pattern to extract the subdirectory from a URL
#' - `archive_path`: Path segment used for archive URLs
#' - `repo_url_short_pattern`: Pattern to extract username/repo from archive URLs
#' - `base_url`: Base URL prefix for constructing repository archive URLs
#' @noRd
get_git_regex <- function(platform) {
  # Define platform-specific parameters
  platforms <- list(
    github = list(
      name = "github",
      domain = "github\\.com",
      archive_path = "archive/"
    ),
    gitlab = list(
      name = "gitlab",
      domain = "gitlab\\.com",
      archive_path = "-/archive/"
    )
  )

  # Get platform configuration or error if invalid
  if (!platform %in% names(platforms)) {
    stop("Platform must be 'github' or 'gitlab'", call. = FALSE)
  }

  cfg <- platforms[[platform]]

  # Build base patterns for reuse
  domain <- cfg$domain
  domain_prefix <- paste0("https://", domain)
  repo_path <- paste0(domain_prefix, "/[^/]+/[^/]+")

  # Generate patterns dynamically based on the config
  list(
    has_subdir_pattern = paste0(repo_path, "/.+/", cfg$archive_path),
    extract_subdir_pattern = paste0(
      repo_path,
      "/(.+)/",
      cfg$archive_path,
      ".*"
    ),
    archive_path = cfg$archive_path,
    repo_url_short_pattern = paste0(
      domain_prefix,
      "/([^/]+/[^/]+).*"
    ),
    base_url = paste0("https://", cfg$name, ".com")
  )
}

#' Return the SRI hash of an URL with .tar.gz
#' @param url String with URL ending with `.tar.gz`
#' @param repo_url URL to GitHub repository, NULL if CRAN archive
#' @param commit Commit hash, NULL if CRAN archive
#' @param ... Further arguments passed down to methods.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a GitHub repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: list with three elements: 'package', its 'imports' and its 'remotes'
#' @noRd
hash_url <- function(url, repo_url = NULL, commit = NULL, ...) {
  tdir <- tempdir()

  tmpdir <- paste0(
    tdir,
    "_repo_hash_url_",
    paste0(sample(letters, 5), collapse = "")
  )

  path_to_folder <- tempfile(pattern = "file", tmpdir = tmpdir, fileext = "")
  dir.create(path_to_folder, recursive = TRUE)

  path_to_tarfile <- paste0(path_to_folder, "/package_tar_gz")
  path_to_src <- paste0(path_to_folder, "/package_src")

  dir.create(path_to_src, recursive = TRUE)
  path_to_src <- normalizePath(path_to_src)

  dir.create(path_to_tarfile, recursive = TRUE)

  path_to_tarfile <- normalizePath(path_to_tarfile)

  h <- curl::new_handle(failonerror = TRUE, followlocation = TRUE)
  token <- Sys.getenv("GITHUB_PAT")
  token_pattern <- "^(gh[ps]_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59})$"
  if (grepl(token_pattern, token)) {
    handle_setheaders(h, Authorization = paste("token", token))
  }

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a GitHub repo, check the url and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number.\n",
      paste0("Failing repo: ", url)
    )

  tar_file <- file.path(path_to_tarfile, "package.tar.gz")

  # Determine platform: github, gitlab,
  if (grepl("github", url)) {
    platform <- "github"
  } else if (grepl("gitlab", url)) {
    platform <- "gitlab"
  } else if (grepl("cran", url)) {
    platform <- "cran"
  } else {
    stop(
      "repo_url argument should be a URL to a GitHub/GitLab repo or a CRAN archive.\n"
    )
  }

  # set the root URL for the download
  root_url <- url

  # if GitHub or GitLab URL with a subdirectory, we need to adjust the root_url
  # because only entire repos can be downloaded)
  if (platform %in% c("github", "gitlab")) {
    # Get regex patterns for the platform
    patterns <- get_git_regex(platform)
    username_repo <- sub(patterns$repo_url_short_pattern, "\\1", url)
    has_subdir <- grepl(patterns$has_subdir_pattern, url)
    if (has_subdir) {
      base_repo_url <- paste0(patterns$base_url, "/", username_repo)
      root_url <- paste0(
        base_repo_url,
        "/",
        patterns$archive_path,
        commit,
        ".tar.gz"
      )
    }
  }

  try_download(
    url = root_url,
    file = tar_file,
    handle = h,
    extra_diagnostics = extra_diagnostics
  )

  untar(tar_file, exdir = path_to_src)

  # when fetching from GitHub archive; e.g.,
  # https://github.com/rap4all/housing/archive/1c860959310b80e67c41f7bbdc3e84cef00df18e.tar.gz")
  # package_src will uncompressed contents in
  # subfolder "housing-1c860959310b80e67c41f7bbdc3e84cef00df18e"
  path_to_source_root <- file.path(
    path_to_src,
    list.files(path_to_src)
  )

  sri_hash <- nix_sri_hash(path = path_to_source_root)

  # set the path to the r folder containing the DESCRIPTION file
  path_to_r <- path_to_source_root

  # if GitHub or GitLab URL with a subdirectory, we need to adjust the path
  if (platform %in% c("github", "gitlab") && has_subdir) {
    url_subdir <- sub(patterns$extract_subdir_pattern, "\\1", url)
    path_to_r <- file.path(path_to_source_root, url_subdir)
  }

  paths <- list.files(
    path_to_r,
    full.names = TRUE,
    recursive = TRUE
  )

  desc_path <- grep(
    file.path(path_to_r, "DESCRIPTION"),
    paths,
    value = TRUE
  )

  if (platform == "github") {
    commit_date <- get_commit_date(username_repo, commit)
  }

  deps <- get_imports(desc_path, commit_date, ...)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps
    )
  )
}

#' Obtain Nix SHA-256 hash of a directory in SRI format (base64)
#'
#' @param path Path to directory to hash
#' @return string with SRI hash specification
#' @noRd
nix_sri_hash <- function(path) {
  if (!dir.exists(path)) {
    stop("Directory", path, "does not exist", call. = FALSE)
  }
  has_nix_shell <- nix_shell_available()
  if (isFALSE(has_nix_shell)) {
    stop_no_nix_shell()
  }

  # not needed for Nix R sessions, workaround on Debian and Debian-based
  # systems with nix installed
  # nolint start: object_name_linter
  LD_LIBRARY_PATH_default <- Sys.getenv("LD_LIBRARY_PATH")
  needs_ld_fix <- isFALSE(nzchar(Sys.getenv("NIX_STORE"))) &&
    nzchar(LD_LIBRARY_PATH_default)
  # nolint end

  if (isTRUE(needs_ld_fix)) {
    # On Debian and Debian-based systems, like Ubuntu 22.04, we found that a
    # preset `LD_LIBRARY_PATH` environment variable in the system's R session
    # leads to errors like
    # nix-hash: /usr/lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.38'
    # not found (required by nix-hash)
    # nix-hash: /usr/lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.38'
    # not found (required by # nolint next: line_length_linter
    # /nix/store/4z754a0vzl98asv0pa95i5d9szw5jqbs-lowdown-1.0.2-lib/lib/liblowdown.so.3)
    # etc...
    # for both `nix-hash`; it occurs via
    # `sys::exec_internal`, `base::system()` or `base::system2()` from R.
    # Therefore, we set it to `""` and set  back the default (old)
    # `LD_LIBRARY_PATH` when `with_nix()` exits.
    fix_ld_library_path()
  }

  cmd <- "nix-hash"
  args <- c("--type", "sha256", "--sri", path)
  proc <- sys::exec_internal(
    cmd = cmd,
    args = args
  )

  poll_sys_proc_blocking(
    cmd = paste(cmd, paste(args, collapse = " ")),
    proc = proc,
    what = cmd,
    message_type = "quiet"
  )

  if (isTRUE(needs_ld_fix)) {
    # set old LD_LIBRARY_PATH (only if non-Nix R session, and if it wasn't
    # `""`)
    on.exit(
      Sys.setenv(LD_LIBRARY_PATH = LD_LIBRARY_PATH_default),
      add = TRUE
    )
  }

  sys::as_text(proc$stdout)
}


#' Return the SRI hash of a CRAN package source using `nix hash path --sri path`
#' @param repo_url URL to CRAN package source
#' @noRd
hash_cran <- function(repo_url) {
  # list contains `sri_hash` and `deps` elements
  list_sri_hash_deps <- hash_url(url = repo_url)

  return(list_sri_hash_deps)
}

#' Return the SRI hash of a GitHub repository at a given unique commmit ID
#'
#' @details `hash_git` will retrieve an archive of the repository URL
#' <https://github.com/<user>/<repo> at a given commit ID. It will fetch
#' a .tar.gz file from
#' <https://github.com/<user>/<repo>/archive/<commit-id>.tar.gz. Then, it will
#' ungzip and unarchive the downloaded `tar.gz` file. Then, on the extracted
#' directory, it will run `nix-hash`
#' (NAR) hash
#' NAR
#' @param repo_url URL to GitHub repository
#' @param commit Commit hash
#' @param ref Release or branch reference
#' @param ... Further arguments passed down to methods.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a GitHub repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: list with three elements: 'package', its 'imports' and its 'remotes'
#' @noRd
hash_git <- function(repo_url, commit, ref, ...) {
  trailing_slash <- grepl("/$", repo_url)
  if (isTRUE(trailing_slash)) {
    slash <- ""
  } else {
    slash <- "/"
  }

  if(!is.null(ref)) {
    url_extension <- sprintf("tree/%s",
                             ref)
  } else if(!is.null(commit)) {
    url_extension <- commit
  }
  if (grepl("github", repo_url)) {
    url <- paste0(repo_url, slash, "archive/", url_extension, ".tar.gz")
  } else if (grepl("gitlab", repo_url)) {
    url <- paste0(repo_url, slash, "-/archive/", url_extension, ".tar.gz")
  }
  # list contains `sri_hash` and `deps` elements
  hash_url(url, repo_url, commit, ...)
}


#' Try download contents of an URL onto file on disk
#'
#' Fetch if available and stop with propagating the curl error. Also show URL
#' for context
#' @noRd
try_download <- function(
  url,
  file,
  handle = curl::new_handle(failonerror = TRUE),
  extra_diagnostics = NULL
) {
  tryCatch(
    {
      req <- curl::curl_fetch_disk(url, path = file, handle = handle)
    },
    error = function(e) {
      stop(
        "Request `curl::curl_fetch_disk()` failed:\n",
        e$message[1],
        extra_diagnostics,
        call. = FALSE
      )
    }
  )
}
