testthat::test_that("get_sri_hash_deps returns correct sri hash and dependencies of R packages, locally", {

  # only run this one locally
  skip_if_not(nix_shell_available())

  testthat::skip_on_cran()

  testthat::expect_equal(
              get_sri_hash_deps(
                "https://github.com/rap4all/housing/",
                "1c860959310b80e67c41f7bbdc3e84cef00df18e"
              ),
              list(
                "sri_hash" = "sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=",
                "deps" = list(
                  "package" = "housing",
                  "imports" = c(
                    "dplyr", "ggplot2", "janitor", "purrr",
                    "readxl", "rlang", "rvest", "stringr", "tidyr"
                  ),
                  "remotes" = NULL
                )
              )
            )
})

testthat::test_that("get_sri_hash_deps returns correct sri hash and dependencies of R packages, online", {

  # only run this one if the shell is not available, running it through the api
  !skip_if_not(nix_shell_available())

  testthat::skip_on_cran()

  testthat::expect_equal(
    get_sri_hash_deps(
      "https://github.com/rap4all/housing/",
      "1c860959310b80e67c41f7bbdc3e84cef00df18e"
    ),
    list(
      "sri_hash" = "sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=",
      "deps" = list(
        "package" = "housing",
        "imports" = c(
          "dplyr", "ggplot2", "janitor", "purrr",
          "readxl", "rlang", "rvest", "stringr", "tidyr"
        ),
        "remotes" = NULL
      )
    )
  )
})
