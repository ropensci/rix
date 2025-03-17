testthat::test_that("rix() with Python packages", {
  os_type <- Sys.info()["sysname"]
  skip_if_not(nix_shell_available())
  skip_if(os_type == "Darwin" || os_type == "Windows")

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir,
    paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(ide, path_default_nix) {
    rix(
      date = "2025-03-10",
      r_pkgs = c("dplyr", "janitor"),
      tex_pkgs = c("amsmath"),
      py_pkgs = list(
        py_version = "3.12",
        py_pkgs = c("polars", "plotnine")
      ),
      ide = ide,
      project_path = path_default_nix,
      overwrite = TRUE,
      message_type = "quiet",
      shell_hook = NULL
    )

    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(ide = "positron", path_default_nix),
    name = "python_default.nix",
  )
})
