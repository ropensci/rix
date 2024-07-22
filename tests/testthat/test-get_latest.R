testthat::test_that("get_latest() fails gracefully if no internet", {
  with_mocked_bindings(
    expect_error(
      get_latest("latest"),
      "You don't seem to be connected"
    ),
    `has_internet` = function(...) FALSE
  )
})
