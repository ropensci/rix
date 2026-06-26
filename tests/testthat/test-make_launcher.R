testthat::test_that("Snapshot test of make_launcher()", {
  skip_if(Sys.info()["sysname"] != "Linux")

  tmpdir <- tempfile("rix-test-launcher-")
  dir.create(tmpdir)

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

testthat::test_that("make_launcher() creates an executable script", {
  skip_if(Sys.info()["sysname"] != "Linux")

  tmpdir <- tempfile("rix-test-launcher-")
  dir.create(tmpdir)

  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  path <- make_launcher(editor = "rstudio", project_path = tmpdir)

  testthat::expect_true(file.access(path, mode = 1) == 0)
})
