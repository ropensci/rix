#' setup_cachix Setup up cachix as a substituter
#' @details This function edits `~/.config/nix/nix.conf` to add
#'   the `rstats-on-nix` public cache as a substituter. The `rstats-on-nix`
#'   public cache, hosted on Cachix, contains many prebuild binaries of R
#'   R packages for x86_64 Linux and macOS (Intel architectures for packages
#'   released before 2021 and Apple Silicon from 2021). This function
#'   automatically performs a backup of `~/.config/nix/nix.conf`.
#' @return Nothing, changes a file in the user's home directory.
#' @export
#' @examples
#' \dontrun{
#'   setup_cachix()
#' }
setup_cachix <- function(nix_conf_path = "~/.config/nix") {

  nix_conf_file <- file.path(nix_conf_path, "nix.conf")

  # Test for existence and size instead of only existence,
  # as an active file connection makes the file exist, but is empty
  nix_conf_exists <- file.exists(nix_conf_file) &&
    `!=`(file.size(nix_conf_file), 0L)

    if(!nix_conf_exists){
      stop("~/.config/nix/nix.conf does not exist, did you install Nix?")
    } else {
      if(identical(Sys.getenv("TESTTHAT"), "false")){
        timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
        nix_conf_backup <- paste0(nix_conf_file, "_backup_", timestamp)
        file.copy(from = nix_conf_file, to = nix_conf_backup)
      } else {
        cat("this is running in a test, no backup performed")
      }

      nix_conf_content <- readLines(con = nix_conf_file)
      if (!(any(grepl("https://rstats-on-nix.cachix.org", nix_conf_content)))) {
      nix_conf_content <- gsub("substituter = .*",
                               "\\1 https://rstats-on-nix.cachix.org",
                               nix_conf_content)

      nix_conf_content <- gsub("trusted-public-keys = .*",
   "\\1 rstats-on-nix.cachix.org-1:mzXrOo5XyDwy6MWSY0v8XYXTeYFSg7QSfv9Vq3Xvwyk=",
                               nix_conf_content)


      writeLines(enc2utf8(nix_conf_content), nix_conf_file, useBytes = TRUE)
      nix_conf_file
    } else {
      stop("rstats-on-nix cache already configured!")
    }
  }
}
