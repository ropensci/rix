testthat::expect_equal(
  detect_versions(c("dplyr", "tidyr")),
  list(
    "cran_packages" = c("dplyr", "tidyr"),
    "archive_packages" = NULL
  )
)

testthat::expect_equal(
  detect_versions(c("dplyr@0.80", "tidyr")),
  list(
    "cran_packages" = "tidyr",
    "archive_packages" = "dplyr@0.80"
  )
)
