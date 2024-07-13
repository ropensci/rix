testthat::test_that("Snapshot test of tar_nix_ga()", {
  testthat::announce_snapshot_file("tar_nix_ga/run-pipeline.yaml")

  testthat::expect_snapshot_file(
    path = tar_nix_ga(),
    name = "run-pipeline.yaml"
  )
})
