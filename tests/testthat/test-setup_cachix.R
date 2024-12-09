testthat::test_that("setup_cachix(): error if no config file", {

  testthat::expect_error(
              setup_cachix(nix_conf_path = "."), "does not exist")
})

testthat::test_that("setup_cachix(): error if already configured", {

  testthat::expect_error(
              setup_cachix(nix_conf_path = "testdata/nix_conf_samples/nix_already/"), "already configured")
})

testthat::test_that("setup_cachix(): configure if not already", {

  testthat::expect_snapshot_file(
     path = setup_cachix(nix_conf_path = "testdata/nix_conf_samples/nix_not_yet/"),
     name = "nix.conf"
  )

  on.exit(
    unlink("testdata/nix_conf_samples/nix_not_yet/nix.conf"),
    add = TRUE
  )

  on.exit(
    file.copy(
      from = "testdata/nix_conf_samples/nix_not_yet/nix.conf-ground_truth",
      to = "testdata/nix_conf_samples/nix_not_yet/nix.conf",
      ),
    add = TRUE
  )
})
