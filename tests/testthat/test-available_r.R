testthat::test_that("available_r lists all available r versions", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    available_r(),
    c(
      "bleeding-edge",
      "frozen-edge",
      "r-devel",
      "bioc-devel",
      "r-devel-bioc-devel",
      "latest-upstream",
      "3.5.3",
      "3.6.0",
      "3.6.1",
      "3.6.2",
      "3.6.3",
      "4.0.0",
      "4.0.1",
      "4.0.2",
      "4.0.3",
      "4.0.4",
      "4.0.5",
      "4.1.0",
      "4.1.1",
      "4.1.2",
      "4.1.3",
      "4.2.0",
      "4.2.1",
      "4.2.2",
      "4.2.3",
      "4.3.0",
      "4.3.1",
      "4.3.2",
      "4.3.3",
      "4.4.0",
      "4.4.1",
      "4.4.2",
      "4.4.3",
      "4.5.0",
      "4.5.1",
      "4.5.2",
      "4.5.3",
      "4.6.0"
    )
  )
})

testthat::test_that("available_df() caches results across calls", {
  testthat::skip_on_cran()

  old_cache <- getOption("rix.available_df_cache", NULL)
  on.exit(options(rix.available_df_cache = old_cache), add = TRUE)
  options(rix.available_df_cache = NULL)

  result_first <- available_df()
  result_second <- available_df()

  testthat::expect_true(!is.null(result_second))
  testthat::expect_s3_class(result_second, "data.frame")
  testthat::expect_equal(result_first, result_second)
})


