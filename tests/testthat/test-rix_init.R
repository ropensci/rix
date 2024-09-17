testthat::test_that("Snapshot test of rix_init()", {
  path_env_nix <- tempdir()

  save_rix_init_test <- function(path_env_nix) {
    rix_init(
      project_path = path_env_nix,
      rprofile_action = "overwrite",
      message_type = "simple"
    )

    paste0(path_env_nix, "/.Rprofile")
  }

  testthat::announce_snapshot_file("find_rev/golden_Rprofile.txt")

  testthat::expect_snapshot_file(
    path = save_rix_init_test(path_env_nix),
    name = "golden_Rprofile.txt",
  )

  on.exit(
    unlink(path_env_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})
