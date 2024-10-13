testthat::test_that("Testing `read_renv_lock()`", {
    testthat::expect_error(read_renv_lock("nosuchfile"), "nosuchfile does not exist")
    tmpf <- tempfile()
    cat("not json", file = tmpf)
    testthat::expect_error(read_renv_lock(tmpf), "Error reading renv\\.lock file")
    unlink(tmpf)
})

