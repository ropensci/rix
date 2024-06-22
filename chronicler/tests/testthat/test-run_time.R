test_that("test running time", {

  sleeping <- function(x, y = 0){

    Sys.sleep(x)
    x + y

  }

  r_sleep <- record(sleeping)

  result_pipe <- r_sleep(1) %>=%
    r_sleep(2)

  expect_equal(sum(as.integer(result_pipe$log_df$run_time)), 2)
})
