testthat::test_that("Testing `renv_lock_pkgs()`", {
    expect_error(renv_lock_pkgs(), "renv.lock does not exist")
})
