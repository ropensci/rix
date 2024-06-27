#' Return the sri hash of a path using `nix hash path --sri path` if Nix is
#' available locally
#' @param repo_url URL to Github repository
#' @param branch_name Branch to checkout
#' @param commit Commit hash
nix_hash <- function(repo_url, branch_name, commit) {
  if (grepl("github", repo_url)) {
    hash_git(repo_url, branch_name, commit)
  } else if (grepl("cran.*Archive.*", repo_url)) {
    hash_cran(repo_url)
  } else {
    stop(
      "repo_url argument is wrong. Please provide an url to a Github repo",
      "to install a package from Github, or to the CRAN Archive to install a",
      "package from the CRAN archive."
    )
  }
}


#' Return the SRI hash of an URL with tar.gz
#' @param url
#' @importFrom git2r clone checkout
hash_url <- function(url) {
  path_to_folder <- paste0(
    tempdir(), "repo",
    paste0(sample(letters, 5), collapse = "")
  )

  path_to_tarfile <- paste0(path_to_folder, "/package_tar_gz")
  path_to_src <- paste0(path_to_folder, "/package_src")

  dir.create(path_to_src, recursive = TRUE)
  path_to_src <- normalizePath(path_to_src)
  dir.create(path_to_tarfile, recursive = TRUE)
  path_to_tarfile <- normalizePath(path_to_tarfile)

  h <- curl::new_handle(failonerror = TRUE, followlocation = TRUE)

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a Github repo, check the url, branch name and commit.\n",
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

  cmd <- "nix-hash"
  args_1 <- c("--type", "sha256", path_to_source_root)
  proc_1 <- sys::exec_internal(
    cmd = cmd, args = args_1
  )

  poll_sys_proc_blocking(
    cmd = paste(cmd, paste(args_1, collapse = " ")),
    proc = proc_1,
    what = cmd,
    message_type = "quiet"
  )

  base16_hash <- sys::as_text(proc_1$stdout)

  args_2 <- c("--type", "sha256", "--to-sri", base16_hash)
  proc_2 <- sys::exec_internal(
    cmd = cmd, args = args_2
  )

  poll_sys_proc_blocking(
    cmd = paste(cmd, paste(args_2, collapse = " ")),
    proc = proc_2,
    what = cmd,
    message_type = "quiet"
  )

  sri_hash <- sys::as_text(proc_2$stdout)

  paths <- list.files(path_to_src, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

  # unlink(path_to_folder, recursive = TRUE, force = TRUE)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps
    )
  )
}


#' Return the sri hash of a CRAN package source using `nix hash path --sri path`
#' @param repo_url URL to CRAN package source
hash_cran <- function(repo_url) {
  path_to_folder <- paste0(
    tempdir(), "repo",
    paste0(sample(letters, 5), collapse = "")
  )

  dir.create(path_to_folder, recursive = TRUE)

  path_to_tarfile <- file.path(path_to_folder, "package_tar")

  path_to_src <- file.path(path_to_folder, "package_src")

  dir.create(path_to_tarfile, recursive = TRUE)
  dir.create(path_to_src, recursive = TRUE)

  try_download(
    url = url,
    file = file.path(path_to_tarfile, "package.tar.gz")
  )

  untar(path_to_tarfile, exdir = path_to_src)

  # Compute hash of subfolder
  command <- paste0("nix hash path --sri ", path_to_src, "/*/")

  sri_hash <- system(command, intern = TRUE)

  paths <- list.files(path_to_src, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

  unlink(path_to_folder, recursive = TRUE, force = TRUE)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps
    )
  )
}

#' Return the sri hash of a Github repository
#' @param repo_url URL to Github repository
#' @param branch_name Branch to checkout
#' @param commit Commit hash
#' @importFrom git2r clone checkout
hash_git <- function(repo_url, branch_name, commit) {
  path_to_repo <- paste0(
    tempdir(), "repo",
    paste0(sample(letters, 5), collapse = "")
  )

  git2r::clone(
    url = repo_url,
    local_path = path_to_repo,
    branch = branch_name,
    progress = FALSE
  )

  git2r::checkout(path_to_repo, branch = commit)

  unlink(paste0(path_to_repo, "/.git"), recursive = TRUE, force = TRUE)

  command <- paste0("nix hash path --sri ", path_to_repo)

  sri_hash <- system(command, intern = TRUE)

  paths <- list.files(path_to_repo, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  deps <- get_imports(desc_path)

  unlink(path_to_repo, recursive = TRUE, force = TRUE)

  return(
    list(
      "sri_hash" = sri_hash,
      "deps" = deps
    )
  )
}


#' Get the SRI hash of the NAR serialization of a Github repo, if nix is not available locally
#' @param repo_url A character. The URL to the package's Github repository or to the `.tar.gz` package hosted on CRAN.
#' @param branch_name A character. The branch of interest, NULL for archived CRAN packages.
#' @param commit A character. The commit hash of interest, for reproducibility's sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
nix_hash_online <- function(repo_url, branch_name, commit) {
  # handle to get error for status code 404
  h <- curl::new_handle(failonerror = TRUE)

  url <- paste0(
    "http://git2nixsha.dev:1506/hash?repo_url=",
    repo_url, "&branchName=", branch_name, "&commit=", commit
  )

  # extra diagnostics
  extra_diagnostics <-
    c(
      "\nIf it's a Github repo, check the url, branch name and commit.\n",
      "Are these correct? If it's an archived CRAN package, check the name\n",
      "of the package and the version number."
    )

  req <- try_get_request(
    url = url, handle = h,
    extra_diagnostics = extra_diagnostics
  )

  # plumber endpoint delivers list with
  # - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
  # - `deps`: string with R package dependencies separated by `" "`
  sri_hash_deps_list <- jsonlite::fromJSON(rawToChar(req$content))

  return(sri_hash_deps_list)
}

#' Return the sri hash of a path using `nix hash path --sri path` either with local Nix, or using an online service if Nix is not available
#' @param repo_url A character. The URL to the package's Github repository or to the `.tar.gz` package hosted on CRAN.
#' @param branch_name A character. The branch of interest, NULL for archived CRAN packages.
#' @param commit A character. The commit hash of interest, for reproducibility's sake, NULL for archived CRAN packages.
#' @return list with following elements:
#' - `sri_hash`: string with SRI hash of the NAR serialization of a Github repo
#' - `deps`: string with R package dependencies separarated by space.
#' @noRd
get_sri_hash_deps <- function(repo_url, branch_name, commit) {
  if (nix_shell_available()) {
    nix_hash(repo_url, branch_name, commit)
  } else {
    nix_hash_online(repo_url, branch_name, commit)
  }
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
