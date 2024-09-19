#' ga_cachix Build an environment on Github Actions and cache it on Cachix
#' @details This function puts a `.yaml` file inside the `.github/workflows/`
#'   folders on the root of your project. This workflow file will use the
#'   projects `default.nix` file to generate the development environment on
#'   Github Actions and will then cache the created binaries in Cachix. Create a
#'   free account on Cachix to use this action. Refer to
#'   `vignette("z-binary_cache")` for detailed instructions. Make sure to give
#'   read and write permissions to the Github Actions bot.
#' @param cache_name String, name of your cache.
#' @param path_default String, relative path (from the root directory of your project)
#'   to the `default.nix` to build.
#' @return Nothing, copies file to a directory.
#' @export
#' @examples
#' \dontrun{
#' ga_cachix("my-cachix", path_default = "default.nix")
#' }
ga_cachix <- function(cache_name, path_default) {
  # is this being tested? If no, set the path to ".github/workflows"
  # if yes, set it to a temporary directory
  if (!identical(Sys.getenv("TESTTHAT"), "true")) {
    # Add an empty .gitignore file if there isn’t any

    if (file.exists(".gitignore")) {
      NULL
    } else {
      file.create(".gitignore")
    }

    path <- ".github/workflows"

    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE)
    }
  } else {
    path <- tempdir()
  }

  source <- system.file(
    file.path("extdata", "cachix_dev_env.yaml"),
    package = "rix",
    mustWork = TRUE
  )

  file.copy(source, path, overwrite = TRUE)
  message("GitHub Actions workflow file saved to: ", path)

  # The sed command for Darwin is of the form "sed -i '' s/foo/bar"
  # while on Linux it's "sed -i s/foo/bar"
  darwin_specific_quotes <- if (Sys.info()["sysname"] == "Darwin") {
    "'' "
  } else {
    ""
  }

  system(
    paste0(
      "sed -i ", darwin_specific_quotes, "'s/CACHE_NAME/", cache_name, "/g' ",
      paste0(path, "/cachix_dev_env.yaml")
    )
  )

  system(
    paste0(
      "sed -i ", darwin_specific_quotes, "'s/PATH_TO_DEFAULT_NIX/",
      path_default, "/g' ", file.path(path, "cachix_dev_env.yaml")
    )
  )

  if (identical(Sys.getenv("TESTTHAT"), "true")) {
    file.path(path, "cachix_dev_env.yaml")
  }
}
