testthat::test_that("Snapshot test of make_launcher()", {
  skip_if(Sys.info()["sysname"] != "Linux")

  tmpdir <- tempdir()

  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  testthat::expect_snapshot_file(
              path = make_launcher(editor = "rstudio", project_path = tmpdir),
    name = "start-rstudio.sh"
    )

  testthat::expect_snapshot_file(
              path = make_launcher(editor = "positron", project_path = tmpdir),
    name = "start-positron.sh"
  )
})
