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

  nix_content <- readLines(file.path(path_default_nix, "default.nix"))
  nix_text <- paste(nix_content, collapse = "\n")

  testthat::expect_true(grepl("LD_LIBRARY_PATH", nix_text))
  testthat::expect_true(grepl("shellHook", nix_text))
  testthat::expect_true(grepl("makeLibraryPath", nix_text))
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

  nix_content <- readLines(file.path(path_default_nix, "default.nix"))
  nix_text <- paste(nix_content, collapse = "\n")

  testthat::expect_true(grepl("PYTHONPATH", nix_text))
  testthat::expect_true(grepl("shellHook", nix_text))
  testthat::expect_true(grepl("mypackage/src", nix_text))
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

  nix_content <- readLines(file.path(path_default_nix, "default.nix"))
  nix_text <- paste(nix_content, collapse = "\n")

  # All three hooks should be present
  testthat::expect_true(grepl("LD_LIBRARY_PATH", nix_text))
  testthat::expect_true(grepl("PYTHONPATH", nix_text))
  testthat::expect_true(grepl("echo Hello", nix_text))
  testthat::expect_true(grepl("shellHook", nix_text))
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

  nix_content <- readLines(file.path(path_default_nix, "default.nix"))
  nix_text <- paste(nix_content, collapse = "\n")

  # No LD_LIBRARY_PATH or PYTHONPATH without uv or py_src_dir
  testthat::expect_false(grepl("LD_LIBRARY_PATH", nix_text))
  testthat::expect_false(grepl("PYTHONPATH", nix_text))
  testthat::expect_false(grepl("shellHook", nix_text))
})

