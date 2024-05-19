testthat::test_that("Snapshot test of all features of rix", {

  testthat::announce_snapshot_file("cicd/run-pipeline.yaml")

  testthat::expect_snapshot_file(
              path = tar_nix_ga(),
              name = "run-pipeline.yaml"
              )
})
