## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup, include = FALSE---------------------------------------------------
library(chronicler)
library(testthat)

## -----------------------------------------------------------------------------
my_sqrt <- function(x){

  sqrt(x)

}


## -----------------------------------------------------------------------------
my_sqrt <- function(x, log = ""){

  list(sqrt(x),
       c(log,
         paste0("Running sqrt with input ", x)))

}


## -----------------------------------------------------------------------------
my_log <- function(x, log = ""){

  list(log(x),
       c(log,
         paste0("Running log with input ", x)))

}


## -----------------------------------------------------------------------------
10 |>
  sqrt() |>
  log()


## ---- eval = FALSE------------------------------------------------------------
#  10 |>
#    my_sqrt() |>
#    my_log()
#  

## -----------------------------------------------------------------------------
log_it <- function(.f, ..., log = NULL){

  fstring <- deparse(substitute(.f))

  function(..., .log = log){

    list(result = .f(...),
         log = c(.log,
                 paste0("Running ", fstring, " with argument ", ...)))
  }
}


## -----------------------------------------------------------------------------
l_sqrt <- log_it(sqrt)

l_sqrt(10)

l_log <- log_it(log)

l_log(10)


## -----------------------------------------------------------------------------
bind <- function(.l, .f, ...){

  .f(.l$result, ..., .log = .l$log)

}

## -----------------------------------------------------------------------------
10 |>
  l_sqrt() |>
  bind(l_log)


## -----------------------------------------------------------------------------
log(sqrt(10))

## -----------------------------------------------------------------------------
unit <- log_it(identity)

## -----------------------------------------------------------------------------
fmap <- function(m, f, ...){

  fstring <- deparse(substitute(f))

  list(result = f(m$result, ...),
       log = c(m$log,
               paste0("fmapping ", fstring, " with arguments ", paste0(m$result, ..., collapse = ","))))
}


## -----------------------------------------------------------------------------
# Let’s use unit(), which we defined above, for this.

(m <- unit(10))

## -----------------------------------------------------------------------------
fmap(m, log)

## -----------------------------------------------------------------------------
fmap(m, l_log)

## -----------------------------------------------------------------------------
flatten <- function(m){

  list(result = m$result$result,
       log = c(m$log))

}


## -----------------------------------------------------------------------------
flatten(fmap(m, l_log))

## -----------------------------------------------------------------------------
# I first define a composition operator for functions
`%.%` <- \(f,g)(function(...)(f(g(...))))

# I now compose flatten() and fmap()
# flatten %.% fmap is read as "flatten after fmap"
flatmap <- flatten %.% fmap


## -----------------------------------------------------------------------------
10 |>
  l_sqrt() |>
  bind(l_log)


## -----------------------------------------------------------------------------
10 |>
  l_sqrt() |>
  flatmap(l_log)


## -----------------------------------------------------------------------------
# Since I'm using `{purrr}`, might as well use purrr::compose() instead of my own implementation
flatmap_list <- purrr::compose(purrr::flatten, purrr::map)

# Functions that return lists: they don't compose!
# no worries, we implemented `flatmap_list()`
list_sqrt <- \(x)(as.list(sqrt(x)))
list_log <- \(x)(as.list(log(x)))

10 |>
  list_sqrt() |>
  flatmap_list(list_log)


## -----------------------------------------------------------------------------
a <- as_chronicle(10)
r_sqrt <- record(sqrt)

test_that("first monadic law", {
  expect_equal(bind_record(a, r_sqrt)$value, r_sqrt(10)$value)
})


## -----------------------------------------------------------------------------
test_that("second monadic law", {
  expect_equal(bind_record(a, as_chronicle)$value, a$value)
})


## -----------------------------------------------------------------------------
a <- as_chronicle(10)

r_sqrt <- record(sqrt)
r_exp <- record(exp)
r_mean <- record(mean)

test_that("third monadic law", {
  expect_equal(
  (
    (bind_record(a, r_sqrt)) |>
   bind_record(r_exp)
  )$value,
  (
    a |>
    (\(x) bind_record(x, r_sqrt) |> bind_record(r_exp))()
  )$value
  )
})


## -----------------------------------------------------------------------------

r_sqrt <- record(sqrt)
r_exp <- record(exp)
r_mean <- record(mean)

a <- 1:10 |>
  r_sqrt() |>
  bind_record(r_exp) |>
  bind_record(r_mean)

flatmap_record <- purrr::compose(flatten_record, fmap_record)

b <- 1:10 |>
  r_sqrt() |>
  flatmap_record(r_exp) |>
  flatmap_record(r_mean)

identical(a$value, b$value)


