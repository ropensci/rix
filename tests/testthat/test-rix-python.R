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
      r_pkgs = c("dplyr", "janitor", "reticulate"),
      tex_pkgs = c("amsmath"),
      py_conf = list(
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


testthat::test_that("rix() with Python packages warning if no reticulate", {
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
      date = "2025-03-10",
      r_pkgs = c("dplyr", "janitor"),
      tex_pkgs = c("amsmath"),
      py_conf = list(
        py_version = "3.12",
        py_pkgs = c("polars", "plotnine")
      ),
      ide = "none",
      project_path = path_default_nix,
      overwrite = TRUE,
      message_type = "quiet",
      shell_hook = NULL
    ),
    "Python packages have been requested.*reticulate.*"
  )
})


testthat::test_that("rix() with uv adds LD_LIBRARY_PATH to shellHook", {
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

  save_default_nix_test <- function(path_default_nix) {
    suppressWarnings(
      rix(
        date = "2025-03-10",
        system_pkgs = c("uv"),
        py_conf = list(
          py_version = "3.12",
          py_pkgs = c("numpy")
        ),
        ide = "none",
        project_path = path_default_nix,
        overwrite = TRUE,
        message_type = "quiet"
      )
    )
    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "python_uv_default.nix"
  )
})


testthat::test_that("rix() with py_src_dir adds PYTHONPATH to shellHook", {
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

  save_default_nix_test <- function(path_default_nix) {
    suppressWarnings(
      rix(
        date = "2025-03-10",
        py_conf = list(
          py_version = "3.12",
          py_pkgs = c("numpy"),
          py_src_dir = "mypackage/src"
        ),
        ide = "none",
        project_path = path_default_nix,
        overwrite = TRUE,
        message_type = "quiet"
      )
    )
    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "python_src_default.nix"
  )
})


testthat::test_that("rix() with uv and py_src_dir combines all hooks", {
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

  save_default_nix_test <- function(path_default_nix) {
    suppressWarnings(
      rix(
        date = "2025-03-10",
        system_pkgs = c("uv"),
        py_conf = list(
          py_version = "3.12",
          py_pkgs = c("numpy"),
          py_src_dir = "src"
        ),
        ide = "none",
        project_path = path_default_nix,
        overwrite = TRUE,
        message_type = "quiet",
        shell_hook = "echo Hello"
      )
    )
    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "python_combined_default.nix"
  )
})


testthat::test_that("rix() without uv or py_src_dir has no extra shellHook", {
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

  save_default_nix_test <- function(path_default_nix) {
    suppressWarnings(
      rix(
        date = "2025-03-10",
        py_conf = list(
          py_version = "3.12",
          py_pkgs = c("numpy")
        ),
        ide = "none",
        project_path = path_default_nix,
        overwrite = TRUE,
        message_type = "quiet"
      )
    )
    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "python_simple_default.nix"
  )
})

testthat::test_that("rix() with pypi package", {
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

  save_default_nix_test <- function(path_default_nix) {
    suppressWarnings(
      rix(
        date = "2025-03-10",
        py_conf = list(
          py_version = "3.12",
          pypi_pkgs = c("ryxpress@0.1.1")
        ),
        ide = "none",
        project_path = path_default_nix,
        overwrite = TRUE,
        message_type = "quiet"
      )
    )
    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "python_pypi_default.nix"
  )
})

testthat::test_that("rix() with python git package", {
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

  save_default_nix_test <- function(path_default_nix) {
    suppressWarnings(
      rix(
        date = "2025-03-10",
        py_conf = list(
          py_version = "3.12",
          git_pkgs = list(
            list(
              package_name = "pyclean",
              repo_url = "https://github.com/b-rodrigues/pyclean",
              commit = "174d4d482d400536bb0d987a3e25ae80cd81ef3c"
            )
          )
        ),
        ide = "none",
        project_path = path_default_nix,
        overwrite = TRUE,
        message_type = "quiet"
      )
    )
    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "python_git_default.nix"
  )
})
