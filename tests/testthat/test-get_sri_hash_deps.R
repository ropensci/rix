testthat::test_that("nix_hash returns correct sri hash and dependencies of R packages", {
  testthat::skip_on_cran()

  testthat::expect_equal(
    nix_hash(
      "https://github.com/rap4all/housing/",
      "1c860959310b80e67c41f7bbdc3e84cef00df18e"
    ),
    list(
      "sri_hash" = "sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=",
      "deps" = list(
        "package" = "housing",
        "imports" = c(
          "dplyr",
          "ggplot2",
          "janitor",
          "purrr",
          "readxl",
          "rlang",
          "rvest",
          "stringr",
          "tidyr"
        ),
        "remotes" = list()
      )
    )
  )
})
