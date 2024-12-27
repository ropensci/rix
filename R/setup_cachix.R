#' setup_cachix Setup up the rstats-on-nix binary repository
#' @details This function edits `~/.config/nix/nix.conf` to add the
#'   `rstats-on-nix` public cache as a substituter. The `rstats-on-nix` public
#'   cache, hosted on Cachix, contains many prebuild binaries of R and R packages
#'   for x86_64 Linux and macOS (Intel architectures for packages released
#'   before 2021 and Apple Silicon from 2021 onwards). This function
#'   automatically performs a backup of `~/.config/nix/nix.conf`, or creates
#'   one if there is no `nix.conf` file
#' @return Nothing, changes a file in the user's home directory.
#' @export
#' @examples
#' \dontrun{
#' setup_cachix()
#' }
setup_cachix <- function(nix_conf_path = "~/.config/nix") {
  nix_conf_file <- file.path(nix_conf_path, "nix.conf")

  if (nix_conf_exists(nix_conf_file)) {
    add_to_existing_nix_conf_file(nix_conf_path)
  } else {
    add_new_nix_conf_file(nix_conf_path)
  }
}

#' @noRd
add_new_nix_conf_file <- function(nix_conf_path) {
  if (!dir.exists(nix_conf_path)) {
    dir.create(nix_conf_path, recursive = TRUE)
  }

  source <- system.file(
    file.path("extdata", "nix.conf"),
    package = "rix",
    mustWork = TRUE
  )

  file.copy(source, nix_conf_path)
  message("New Nix user config file saved to: ", nix_conf_path)
}

#' @noRd
add_to_existing_nix_conf_file <- function(nix_conf_path) {
  nix_conf_file <- file.path(nix_conf_path, "nix.conf")

  if (!nix_conf_exists(nix_conf_file)) {
    stop("~/.config/nix/nix.conf does not exist, did you install Nix?")
  }

  nix_conf_content <- readLines(con = nix_conf_file)

  if (is_cachix_configured(nix_conf_content)) {
    stop("rstats-on-nix cache already configured!")
  } else {
    if (identical(Sys.getenv("TESTTHAT"), "true")) {
      cat("this is running in a test, no backup performed")
    } else {
      timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
      nix_conf_backup <- paste0(nix_conf_file, "_backup_", timestamp)
      file.copy(from = nix_conf_file, to = nix_conf_backup)
    }

    substituter_line <- grep("substituters", nix_conf_content)
    nix_conf_content[substituter_line] <- paste0(
      append(
        nix_conf_content[substituter_line],
        "https://rstats-on-nix.cachix.org"
      ),
      collapse = " "
    )

    key_line <- grep("trusted-public-keys", nix_conf_content)
    nix_conf_content[key_line] <- paste0(
      append(
        nix_conf_content[key_line],
        "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
      ),
      collapse = " "
    )

    writeLines(enc2utf8(nix_conf_content), nix_conf_file, useBytes = TRUE)
    message("Added rstats-on-nix as a substituter to ", nix_conf_file)
    invisible(nix_conf_file)
  }
}


#' @noRd
nix_conf_exists <- function(nix_conf_file) {
  # Test for existence and size instead of only existence,
  # as an active file connection makes the file exist, but is empty
  file.exists(nix_conf_file) &&
    `!=`(file.size(nix_conf_file), 0L)
}

#' @noRd
is_cachix_configured <- function(nix_conf_content) {
  substituter_line <- grep("substituters", nix_conf_content)
  (grepl("rstats-on-nix", nix_conf_content[substituter_line]))
}
