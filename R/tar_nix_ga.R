#' tar_nix_ga Run a \{targets\}  pipeline on GitHub Actions.
#' @details This function puts a `.yaml` file inside the `.github/workflows/`
#' folders on the root of your project. This workflow file will use the
#' projects `default.nix` file to generate the development environment on
#' GitHub Actions and will then run the projects \{targets\} pipeline. Make
#' sure to give read and write permissions to the GitHub Actions bot.
#' @return Nothing, copies file to a directory.
#' @family CI/CD
#' @export
#' @examples
#' \dontrun{
#' tar_nix_ga()
#' }
tar_nix_ga <- function() {
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

    dir.create(path, recursive = TRUE)
  } else {
    path <- tempdir()
  }

  source <- system.file(
    file.path("extdata", "run-pipeline.yaml"),
    package = "rix",
    mustWork = TRUE
  )

  file.copy(source, path, overwrite = TRUE)

  if (identical(Sys.getenv("TESTTHAT"), "false")) {
    message("GitHub Actions workflow file saved to: ", path)
  }

  if (identical(Sys.getenv("TESTTHAT"), "true")) {
    paste0(path, "/run-pipeline.yaml")
  }
}
