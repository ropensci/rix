testthat::test_that("Test that generate_locale_archive fails", {
  testthat::expect_error(
    generate_locale_archive("Plan9"),
    "Operating System unsupported"
  )
})
