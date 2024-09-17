testthat::test_that("Testing that `nix_build()` builds derivation", {
  if (isFALSE(is_nix_r_session())) {
    # needed for the GitHub test runners with system's R
    set_nix_path()
  }

  skip_if_not(nix_shell_available())

  skip_on_covr()

  path_subshell <- tempdir()

  rix(
    r_ver = "4.3.1",
    overwrite = TRUE,
    project_path = path_subshell,
    shell_hook = NULL
  )

  expect_no_error(
    nix_build(
      project_path = path_subshell
    )
  )

  on.exit(
    unlink(path_subshell, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})
