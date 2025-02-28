testthat::test_that("Snapshot test of tar_nix_ga()", {
  testthat::expect_snapshot_file(
    path = tar_nix_ga(),
    name = "run-pipeline.yaml"
  )
})
