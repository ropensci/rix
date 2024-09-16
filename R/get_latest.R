#' Get the latest R version and packages
#' @param r_version Character. R version to look for, for example, "4.2.0". If a
#' nixpkgs revision is provided instead, this gets returned.
#' @return A character. The commit hash of the latest nixpkgs-unstable revision
#' @importFrom curl new_handle curl_fetch_memory handle_reset
#' @importFrom jsonlite fromJSON
#' @importFrom curl has_internet
#'
#' @noRd
get_latest <- function(r_version) {
  is_online <- has_internet()

  stopifnot("r_version has to be a character." = is.character(r_version))

  # If the use provides a commit, then the commit gets used.
  # User needs to know which repo it belongs to
  if (nchar(r_version) == 40) {
    return(r_version)
  } else if (
    !(r_version %in% c("bleeding_edge", "frozen_edge", available_r()))
  ) {
    stop(
      "The provided R version is likely wrong.\nPlease check that you ",
      "provided a correct R version.\nYou can list available versions using ",
      "`available_r()`.\nYou can also directly provide a commit, but you need ",
      "to make sure it points to the right repo used by `rix()`.\nYou can ",
      "also use 'bleeding_edge' and 'frozen_edge'."
    )
  } else if (!is_online) {
    stop("ERROR! You don't seem to be connected to the internet.")
  } else if (r_version == "bleeding_edge") {
    latest_commit <- "refs/heads/r-daily"
  } else {
    latest_commit <- get_right_commit(r_version)
  }
  latest_commit
}


#' @noRd
get_right_commit <- function(r_version) {
  if (r_version == "frozen_edge") {
    # nolint next: line_length_linter
    api_url <- "https://api.github.com/repos/rstats-on-nix/nixpkgs/commits?sha=r-daily"
  } else if (
    r_version %in% Filter(function(x) `!=`(x, "latest"), available_r())
  ) { # all but latest
    return(sysdata$revision[sysdata$version == r_version])
  } else {
    # nolint next: line_length_linter
    api_url <- "https://api.github.com/repos/NixOS/nixpkgs/commits?sha=nixpkgs-unstable"
  }

  # handle to get error for status code 404
  h <- curl::new_handle(failonerror = TRUE)

  req <- try_get_request(url = api_url, handle = h)

  curl::handle_reset(h)

  commit_data <- jsonlite::fromJSON(rawToChar(req$content))
  latest_commit <- commit_data$sha[1]

  return(latest_commit)
}


#' Fetch contents from an URL into memory
#'
#' Fetch if available and stop with propagating the curl error. Also show URL
#' for context
#' @noRd
try_get_request <- function(url,
                            handle,
                            extra_diagnostics = NULL) {
  tryCatch(
    {
      req <- curl::curl_fetch_memory(url, handle)
    },
    error = function(e) {
      stop("Request `curl::curl_fetch_memory(",
        paste0("url = ", "'", url, "'", ")` "), "failed:\n ",
        e$message[1], extra_diagnostics,
        call. = FALSE
      )
    }
  )

  return(req)
}
