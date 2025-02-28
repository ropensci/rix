testthat::test_that("Snapshot test of ga_cachix()", {
  skip_if(Sys.info()["sysname"] != "Linux")

  testthat::expect_snapshot_file(
    path = ga_cachix(cache_name = "rstats-on-nix", path = "default.nix"),
    name = "cachix_dev_env.yaml"
  )
})
