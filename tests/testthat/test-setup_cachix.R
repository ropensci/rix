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
     name = "testdata/nix_conf_samples/nix_not_yet/nix.conf"
  )
})
