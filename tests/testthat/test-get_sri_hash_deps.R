testthat::test_that("get_sri_hash_deps returns correct sri hash and dependencies of R packages", {
  testthat::expect_equal(
    get_sri_hash_deps(
      "https://github.com/rap4all/housing/",
      "1c860959310b80e67c41f7bbdc3e84cef00df18e"
    ),
    list(
      "sri_hash" = "sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=",
      "deps" = "dplyr ggplot2 janitor purrr readxl rlang rvest stringr tidyr"
    )
  )
})
