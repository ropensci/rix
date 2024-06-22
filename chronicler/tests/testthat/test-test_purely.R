test_that("purely decorated function provides correct result", {
  expect_equal((purely(log)(10))$value, maybe::just(log(10)))
})


test_that("purely decorated function provides right result", {
  expect_equal((purely(log)(seq(1, 10)))$value, maybe::just(log(seq(1, 10))))
})

test_that("purely decorated function provides NA if problem", {
  expect_equal((purely(log)(-10))$value, maybe::nothing())
})

test_that("purely decorated function log", {
  expect_type((purely(log)(-10))$log_df, "character")
})

test_that("compose purely decorated functions", {

  pure_sqrt <- purely(sqrt)
  pure_mean <- purely(mean)
  pure_exp <- purely(exp)

  result_pipe <- 1:10 |>
    pure_sqrt() %>=%
    pure_exp() %>=%
    pure_mean()

  expect_equal(result_pipe$value, maybe::just(mean(exp(sqrt(1:10)))))

})


test_that("compose purely decorated dplyr functions on data.frame", {

  pure_select <- purely(dplyr::select)
  pure_filter <- purely(dplyr::filter)
  pure_summarise <- purely(dplyr::summarise)

  result_pure <- mtcars |>
    pure_select(am, starts_with("c")) %>=%
    pure_filter(am == 1) %>=%
    pure_summarise(mean_cyl = mean(cyl))

  result_impure <- mtcars |>
    dplyr::select(am, starts_with("c")) |>
    dplyr::filter(am == 1) |>
    dplyr::summarise(mean_cyl = mean(cyl))

  expect_equal(result_pure$value, maybe::just(result_impure))

})


test_that("compose purely decorated dplyr functions on tibbles", {

  pure_select <- purely(dplyr::select)
  pure_filter <- purely(dplyr::filter)
  pure_summarise <- purely(dplyr::summarise)

  result_pure <- mtcars |>
    tibble::as_tibble() |>
    pure_select(am, starts_with("c")) %>=%
    pure_filter(am == 1) %>=%
    pure_summarise(mean_cyl = mean(cyl))

  result_impure <- mtcars |>
    tibble::as_tibble() |>
    dplyr::select(am, starts_with("c")) |>
    dplyr::filter(am == 1) |>
    dplyr::summarise(mean_cyl = mean(cyl))

  expect_equal(result_pure$value, maybe::just(result_impure))

})


test_that("test group_by", {

  pure_group_by <- purely(dplyr::group_by)

  expect_equal(maybe::just(dplyr::group_by(mtcars, carb)), pure_group_by(mtcars, carb)$value)

})
