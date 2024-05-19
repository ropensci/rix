testthat::test_that("find_rev returns correct nixpkgs hash", {
  testthat::expect_equal(
              find_rev("4.2.2"),
              "8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8"
            )

  testthat::expect_equal(
              find_rev("8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8"),
              "8ad5e8132c5dcf977e308e7bf5517cc6cc0bf7d8"
            )
})
