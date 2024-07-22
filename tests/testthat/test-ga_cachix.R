testthat::test_that("Snapshot test of ga_cachix()", {
  skip_if(Sys.info()["sysname"] != "Linux")

  testthat::announce_snapshot_file("ga_cachix/cachix_dev_env.yaml")

  testthat::expect_snapshot_file(
    path = ga_cachix(cache_name = "rstats-on-nix", path = "default.nix"),
    name = "cachix_dev_env.yaml"
  )
})
