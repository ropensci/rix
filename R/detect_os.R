#' detect_os Detects the current OS
#' @return A character. One of Linux or Darwin (Windows is also Linux)
#'
#' @examples
#' detect_os()
#' @noRd
detect_os <- function() {
  os <- Sys.info()["sysname"]
  if (os == "Windows") {
    "Linux"
  } else {
    os
  }
}

#' generate_locale_archive Adds a line to the shellHook to avoid locale warnings
#' @return A character.
#'
#' @examples
#' generate_locale_archive("Linux")
#' @noRd
generate_locale_archive <- function(os) {
  if (os == "Linux" || os == "Darwin") {
    paste0(
      'LOCALE_ARCHIVE = if pkgs.system == \"x86_64-linux\" then ',
      '\"${pkgs.glibcLocales}/lib/locale/locale-archive\" else \"\";'
    )
  } else {
    stop("Operating System unsupported")
  }
}
