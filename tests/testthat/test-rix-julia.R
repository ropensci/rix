testthat::test_that("rix() with Julia packages", {
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
      date = "2025-09-04",
      r_pkgs = c("dplyr", "janitor", "reticulate"),
      tex_pkgs = c("amsmath"),
      jl_conf = list(
        jl_version = "1.10",
        jl_pkgs = c("TidierData", "RDatasets")
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
    path = save_default_nix_test(ide = "none", path_default_nix),
    name = "julia_default.nix",
  )
})

testthat::test_that("rix() with Julia packages, older date", {
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

  testthat::expect_warning(
    rix(
      date = "2025-04-04",
      r_pkgs = c("dplyr", "janitor", "reticulate"),
      tex_pkgs = c("amsmath"),
      jl_conf = list(
        jl_version = "1.10",
        jl_pkgs = c("TidierData", "RDatasets")
      ),
      ide = ide,
      project_path = path_default_nix,
      overwrite = TRUE,
      message_type = "quiet",
      shell_hook = NULL
    ),
    "Julia support is only guaranteed from 2025-09-04 onward.",
  )
})


testthat::test_that("rix() with lts julia version", {
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
      date = "2025-09-04",
      r_pkgs = c("dplyr", "janitor", "reticulate"),
      tex_pkgs = c("amsmath"),
      jl_conf = list(
        jl_version = "lts",
        jl_pkgs = c("TidierData", "RDatasets")
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
    path = save_default_nix_test(ide = "none", path_default_nix),
    name = "julia_default_lts_version.nix",
  )
})


testthat::test_that("rix() with empty julia version", {
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
      date = "2025-09-04",
      r_pkgs = c("dplyr", "janitor", "reticulate"),
      tex_pkgs = c("amsmath"),
      jl_conf = list(
        jl_pkgs = c("TidierData", "RDatasets")
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
    path = save_default_nix_test(ide = "none", path_default_nix),
    name = "julia_default_empty_version.nix",
  )
})
