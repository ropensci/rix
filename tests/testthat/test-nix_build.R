testthat::test_that("Testing that `nix_build()` builds derivation", {

  if (isFALSE(is_nix_r_session())) {
    # needed for the GitHub test runners with system's R
    set_nix_path()
  }

  skip_if_not(nix_shell_available())

  skip_on_covr()

  path_subshell <- tempdir()

  rix_init(
    project_path = path_subshell,
    rprofile_action = "overwrite",
    message_type = "simple"
  )

  rix(
    r_ver = "latest",
    overwrite = TRUE,
    project_path = path_subshell,
    shell_hook = NULL
  )

  out <- nix_build(
    project_path = path_subshell,
    exec_mode = "blocking"
  )

  # exit status 0L is success
  testthat::expect_true(
    out$status == 0L
  )
})
