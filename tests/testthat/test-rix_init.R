testthat::test_that("Snapshot test of rix_init(), overwrite", {
  path_env_nix <- tempdir()

  # Create an empty file, and overwrite it
  rprofile_file <- paste0(path_env_nix, "/.Rprofile")

  save_rix_init_test <- function(path_env_nix) {
    rix_init(
      project_path = path_env_nix,
      rprofile_action = "overwrite",
      message_type = "simple"
    )

    paste0(path_env_nix, "/.Rprofile")
  }

  rprofile_con <- file(rprofile_file, open = "wb", encoding = "native.enc")
  on.exit(close(rprofile_con), add = TRUE)

  testthat::expect_snapshot_file(
    path = save_rix_init_test(path_env_nix),
    name = "golden_Rprofile.txt",
  )

  on.exit(
    unlink(path_env_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})


testthat::test_that("Snapshot test of rix_init(), create_missing, no file", {
  path_env_nix <- tempdir()

  save_rix_init_test <- function(path_env_nix) {
    rix_init(
      project_path = path_env_nix,
      rprofile_action = "create_missing",
      message_type = "simple"
    )

    paste0(path_env_nix, "/.Rprofile")
  }

  testthat::expect_snapshot_file(
    path = save_rix_init_test(path_env_nix),
    name = "golden_Rprofile.txt",
  )

  on.exit(
    unlink(path_env_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})

testthat::test_that("Snapshot test of rix_init(), create_missing, empty file", {
  # Empty should be considered as missing
  # We're creating an empty .Rprofile by opening a file connection
  # and then rix_init() should consider it missing and write

  path_env_nix <- tempdir()

  rprofile_file <- paste0(path_env_nix, "/.Rprofile")

  save_rix_init_test <- function(path_env_nix) {
    rix_init(
      project_path = path_env_nix,
      rprofile_action = "create_missing",
      message_type = "simple"
    )

    rprofile_file
  }

  testthat::announce_snapshot_file("find_rev/golden_Rprofile.txt")

  rprofile_con <- file(rprofile_file, open = "wb", encoding = "native.enc")
  on.exit(close(rprofile_con), add = TRUE)

  testthat::expect_snapshot_file(
    path = save_rix_init_test(path_env_nix),
    name = "golden_Rprofile.txt",
  )

  on.exit(
    unlink(path_env_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})


testthat::test_that("Snapshot test of rix_init(), append", {
  path_env_nix <- tempdir()

  save_rix_init_test <- function(path_env_nix) {
    rix_init(
      project_path = path_env_nix,
      rprofile_action = "append",
      message_type = "simple"
    )

    paste0(path_env_nix, "/.Rprofile")
  }

  rprofile_file <- paste0(path_env_nix, "/.Rprofile")
  rprofile_con <- file(rprofile_file, open = "a+", encoding = "native.enc")

  writeLines(enc2utf8("This is in the original Rprofile"),
    rprofile_con,
    useBytes = TRUE
  )

  close(rprofile_con)

  testthat::expect_snapshot_file(
    path = save_rix_init_test(path_env_nix),
    name = "append_Rprofile.txt",
  )

  on.exit(
    unlink(path_env_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})
