#' Return the sri hash of a path using `nix hash path --sri path` if Nix is
#' available locally
#' @param repo_url URL to Git repository
#' @param commit Commit hash (SHA-1)
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
nix_hash <- function(repo_url, commit) {
  if (grepl("(github)|(gitlab)", repo_url)) {
    hash_git(repo_url = repo_url, commit)
  } else if (grepl("cran.*Archive.*", repo_url)) {
    hash_cran(repo_url = repo_url)
  } else {
    stop(
      "repo_url argument is wrong. Please provide an url to a Github repo",
      "to install a package from Github, or to the CRAN Archive to install a",
      "package from the CRAN archive."
    )
  }
}


#' Return the SRI hash of an URL with .tar.gz
#' @param url String with URL ending with `.tar.gz`
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
hash_url <- function(url) {
  tdir <- tempdir()
  on.exit(unlink(tdir, recursive = TRUE, force = TRUE), add = TRUE)
  tmpdir <- paste0(
    tdir, "_repo_hash_url_",
    paste0(sample(letters, 5), collapse = "")
  )
  on.exit(unlink(tmpdir, recursive = TRUE, force = TRUE), add = TRUE)

  path_to_folder <- tempfile(pattern = "file", tmpdir = tmpdir, fileext = "")
  dir.create(path_to_folder, recursive = TRUE)
  on.exit(
    unlink(path_to_folder, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  path_to_tarfile <- paste0(path_to_folder, "/package_tar_gz")
  path_to_src <- paste0(path_to_folder, "/package_src")

  dir.create(path_to_src, recursive = TRUE)
  path_to_src <- normalizePath(path_to_src)
  on.exit(
    unlink(path_to_src, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  dir.create(path_to_tarfile, recursive = TRUE)
  on.exit(
    unlink(path_to_tarfile, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  path_to_tarfile <- normalizePath(path_to_tarfile)

  h <- curl::new_handle(failonerror = TRUE, followlocation = TRUE)

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a Github repo, check the url and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number."
    )

  tar_file <- file.path(path_to_tarfile, "package.tar.gz")

  try_download(
    url = url, file = tar_file, handle = h,
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

  paths <- list.files(path_to_src, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

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
    cmd = cmd, args = args
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

  sri_hash <- sys::as_text(proc$stdout)
  return(sri_hash)
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
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
hash_git <- function(repo_url, commit) {
  trailing_slash <- grepl("/$", repo_url)
  if (isTRUE(trailing_slash)) {
    slash <- ""
  } else {
    slash <- "/"
  }

  if (grepl("github", repo_url)) {
    url <- paste0(repo_url, slash, "archive/", commit, ".tar.gz")
  } else if (grepl("gitlab", repo_url)) {
    url <- paste0(repo_url, slash, "-/archive/", commit, ".tar.gz")
  }

  # list contains `sri_hash` and `deps` elements
  list_sri_hash_deps <- hash_url(url)

  return(list_sri_hash_deps)
}


#' Get the SRI hash of the NAR serialization of a Github repo, if nix is not
#' available locally
#' @param repo_url A character. The URL to the package's Github repository or to
#' the `.tar.gz` package hosted on CRAN.
#' @param commit A character. The commit hash of interest, for reproducibility's
#' sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
nix_hash_online <- function(repo_url, commit) {
  # handle to get error for status code 404
  h <- curl::new_handle(failonerror = TRUE)

  url <- paste0(
    "https://git2nixsha.dev/hash?repo_url=",
    repo_url, "&commit=", commit
  )

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a Github repo, check the url and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number."
    )

  req <- try_get_request(
    url = url, handle = h,
    extra_diagnostics = extra_diagnostics
  )

  # plumber endpoint delivers list with
  # - `sri_hash`: string with SHA256 hash in base-64 and SRI format of a
  # GitHub repository at a given commit ID
  # - `deps`: string with R package dependencies separated by `" "`
  sri_hash_deps_list <- jsonlite::fromJSON(rawToChar(req$content))

  return(sri_hash_deps_list)
}

#' Return the sri hash of a path using `nix-hash --type sha256 --sri <path>`
#' with local Nix, or using an online API service (equivalent
#' `nix hash path --sri <path>`) if Nix is not available
#' @param repo_url A character. The URL to the package's Github repository or to
#' the `.tar.gz` package hosted on CRAN.
#' @param commit A character. The commit hash of interest, for reproducibility's
#' sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#'      at a given deterministic git commit ID (SHA-1)
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
get_sri_hash_deps <- function(repo_url, commit) {
  # if no `options(rix.sri_hash=)` is set, default is `"check_nix"`
  sri_hash_option <- get_sri_hash_option()
  has_nix_shell <- nix_shell_available()
  if (isTRUE(has_nix_shell)) {
    switch(sri_hash_option,
      "check_nix" = nix_hash(repo_url, commit),
      "locally" = nix_hash(repo_url, commit),
      "api_server" = nix_hash_online(repo_url, commit)
    )
  } else {
    switch(sri_hash_option,
      "check_nix" = nix_hash_online(repo_url, commit),
      "locally" = {
        if (isFALSE(has_nix_shell)) {
          stop(
            'You set `options(rix.sri_hash="locally")`, but Nix seems not',
            "installed.\n", "Either switch to",
            '`options(rix.sri_hash="api_server")`', "to compute the SRI hashes",
            "through the http://git2nixsha.dev API server, or install Nix.\n",
            no_nix_shell_msg,
            call. = FALSE
          )
        }
      },
      "api_server" = nix_hash_online(repo_url, commit)
    )
  }
}

#' Retrieve validated value for options(rix.sri_hash=)
#' @return validated `rix.sri_hash` option. Currently, either `"check_nix"`
#' if option is not set, `"locally"` or `"api_server"` if the option is set.
#' @noRd
get_sri_hash_option <- function() {
  sri_hash_options <- c(
    "check_nix",
    "locally",
    "api_server"
  )
  sri_hash <- getOption(
    "rix.sri_hash",
    default = "check_nix"
  )

  valid_vars <- all(sri_hash %in% sri_hash_options)

  if (!isTRUE(valid_vars)) {
    stop("`options(rix.sri_hash=)` ",
      "only allows the following values:\n",
      paste(sri_hash_options, collapse = "; "),
      call. = FALSE
    )
  }

  return(sri_hash)
}

#' Try download contents of an URL onto file on disk
#'
#' Fetch if available and stop with propagating the curl error. Also show URL
#' for context
#' @noRd
try_download <- function(url,
                         file,
                         handle = curl::new_handle(failonerror = TRUE),
                         extra_diagnostics = NULL) {
  tryCatch(
    {
      req <- curl::curl_fetch_disk(url, path = file, handle = handle)
    },
    error = function(e) {
      stop("Request `curl::curl_fetch_disk()` failed:\n",
        e$message[1], extra_diagnostics,
        call. = FALSE
      )
    }
  )
}
