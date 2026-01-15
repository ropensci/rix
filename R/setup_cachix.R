#' setup_cachix Setup up the rstats-on-nix binary repository
#' @param nix_conf_path Character, path to folder containing 'nix.conf' file.
#'   Defaults to "~/.config/nix".
#' @details This function edits `~/.config/nix/nix.conf` to add the
#'   `rstats-on-nix` public cache as a substituter. The `rstats-on-nix` public
#'   cache, hosted on Cachix, contains many prebuild binaries of R and R
#'   packages for x86_64 Linux and macOS (Intel architectures for packages
#'   released before 2021 and Apple Silicon from 2021 onwards). This function
#'   automatically performs a backup of `~/.config/nix/nix.conf`, or creates one
#'   if there is no `nix.conf` file.
#'
#'   This is the recommended approach for configuring the cache, as it works
#'   with both standard Nix installations and Determinate Nix installations.
#'   After running this function, you also need to add yourself to
#'   `trusted-users` so Nix allows you to use the cache. Run one of:
#'
#'   - **Linux**: `echo "trusted-users = root $USER" | sudo tee -a /etc/nix/nix.custom.conf && sudo systemctl restart nix-daemon`
#'   - **macOS**: `echo "trusted-users = root $USER" | sudo tee -a /etc/nix/nix.custom.conf && sudo launchctl kickstart -k system/org.nixos.nix-daemon`
#'
#'   If you see warnings like "ignoring untrusted substituter", this means the
#'   trusted-users configuration is not in place.
#'
#'   **NixOS users**: This function does not work on NixOS because the Nix
#'   configuration is managed declaratively. Instead, configure the cache in
#'   your system configuration. Without Home Manager, add this to your
#'   `configuration.nix`:
#'
#'   ```
#'   nix.settings = {
#'     substituters = [
#'       "https://cache.nixos.org"
#'       "https://rstats-on-nix.cachix.org"
#'     ];
#'     trusted-public-keys = [
#'       "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
#'       "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
#'     ];
#'   };
#'   ```
#'
#'   With Home Manager, add this to your home configuration:
#'
#'   ```
#'   nix.settings = {
#'     substituters = [
#'       "https://rstats-on-nix.cachix.org"
#'     ];
#'     trusted-public-keys = [
#'       "rstats-on-nix.cachix.org-1:vdiiVgocg6WeJrODIqdprZRUrhi1JzhBnXv7aWI6+F0="
#'     ];
#'   };
#'   ```
#'
#'   Other use cases include: if you somehow mess up `~/.config/nix/nix.conf`
#'   and need to generate a new one from scratch, or if you're using Nix inside
#'   Docker, write a `RUN Rscript -e 'rix::setup_cachix()'` statement to
#'   configure the cache there. Because Docker runs using `root` by default no
#'   need to install the `cachix` client to configure the cache, running
#'   `setup_cachix()` is enough. See the 'z - Advanced topic: Using Nix inside
#'   Docker' vignette for more details.
#' @return Nothing; changes a file in the user's home directory.
#' @export
#' @examples
#' \dontrun{
#' setup_cachix()
#' }
setup_cachix <- function(nix_conf_path = "~/.config/nix") {
  nix_conf_file <- file.path(nix_conf_path, "nix.conf")

  if (!nix_build_installed()) {
    stop(
      "Nix is not installed in this system,
there is no need to configure the cache.
Install Nix first."
    )
  }

  if (nix_conf_exists(nix_conf_file)) {
    add_to_existing_nix_conf_file(nix_conf_path)
  } else {
    add_new_nix_conf_file(nix_conf_path)
  }
}

#' @noRd
#' @param nix_conf_path Character, path to folder containing 'nix.conf' file.
#'   Defaults to "~/.config/nix".
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

  if (identical(Sys.getenv("TESTTHAT"), "true")) {
    message("New Nix user config file saved to: ", nix_conf_path)
  }
}

#' @noRd
#' @param nix_conf_path Character, path to folder containing 'nix.conf' file.
#'   Defaults to "~/.config/nix".
add_to_existing_nix_conf_file <- function(nix_conf_path) {
  nix_conf_file <- file.path(nix_conf_path, "nix.conf")

  nix_conf_content <- readLines(con = nix_conf_file)

  if (is_cachix_configured(nix_conf_content)) {
    stop("rstats-on-nix cache already configured!")
  } else {
    if (identical(Sys.getenv("TESTTHAT"), "true")) {
      NULL
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

    writeLines(
      enc2utf8(c(nix_conf_content, "")),
      nix_conf_file,
      useBytes = TRUE
    )
    if (identical(Sys.getenv("TESTTHAT"), "false")) {
      message("Added rstats-on-nix as a substituter to ", nix_conf_file)
    }
    invisible(nix_conf_file)
  }
}


#' @noRd
#' @param nix_conf_path Connection to nix_conf_file
nix_conf_exists <- function(nix_conf_file) {
  # Test for existence and size instead of only existence,
  # as an active file connection makes the file exist, but is empty
  file.exists(nix_conf_file) &&
    `!=`(file.size(nix_conf_file), 0L)
}

#' @noRd
#' @param nix_conf_path Content of 'nix.conf' file
is_cachix_configured <- function(nix_conf_content) {
  substituter_line <- grep("substituters", nix_conf_content)
  any((grepl("rstats-on-nix", nix_conf_content[substituter_line])))
}
