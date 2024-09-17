## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----include=FALSE------------------------------------------------------------
library(rix)

## ----parsermd-chunk-3---------------------------------------------------------
library("rix")

path_env_1 <- file.path(".", "_env_1_R-4-1-3")

rix(
  r_ver = "4.1.3",
  overwrite = TRUE,
  project_path = path_env_1
)

## ----parsermd-chunk-4, echo = FALSE-------------------------------------------
cat(readLines(file.path(path_env_1, "default.nix")), sep = "\n")

## ----include = FALSE----------------------------------------------------------
unlink(path_env_1, recursive = TRUE, force = TRUE)

## ----parsermd-chunk-5---------------------------------------------------------
df <- data.frame(a = 1:3, b = 4:6)
as.vector(x = df, mode = "list")

## ----parsermd-chunk-6---------------------------------------------------------
df_as_vector <- function(x) {
  out <- as.vector(x = x, mode = "list")
  return(out)
}
(out_system_1 <- df_as_vector(x = df))

## ----parsermd-chunk-7, eval = FALSE-------------------------------------------
#  # now run it in `nix-shell`; `with_nix()` takes care
#  # of exporting global objects of `df_as_vector` recursively
#  out_nix_1 <- with_nix(
#    expr = function() df_as_vector(x = df), # wrap to avoid evaluation
#    program = "R",
#    project_path = path_env_1,
#    message_type = "simple" # you can do `"verbose"`, too
#  )
#  
#  # compare results of custom codebase with indentical
#  # inputs and different software environments
#  identical(out_system_1, out_nix_1)
#  
#  # should return `FALSE` if your system's R versions in
#  # current interactive R session is R >= 4.2.0

## ----parsermd-chunk-8---------------------------------------------------------
df_as_vector <- function(x = df) {
  out <- as.vector(x = x, mode = "list")
  return(out)
}

## ----parsermd-chunk-9, eval = FALSE-------------------------------------------
#  out_nix_1_b <- with_nix(
#    expr = df_as_vector, # provide name of function
#    program = "R",
#    project_path = path_env_1,
#    message_type = "simple" # you can do `"verbose"`, too
#  )

## ----parsermd-chunk-10, eval = FALSE------------------------------------------
#  Reduce(f = identical, list(out_nix_1, out_nix_1_b))

## ----parsermd-chunk-11--------------------------------------------------------
library("rix")
path_env_1_2 <- file.path(".", "_env_1_2_R-4-2-0")

rix(
  r_ver = "4.2.0",
  overwrite = TRUE,
  project_path = path_env_1_2,
  shell_hook = "R"
)

list.files(path_env_1_2)

## ----parsermd-chunk-13, eval = FALSE------------------------------------------
#  # current Nix-R session with R 4.1.3
#  df_as_vector <- function(x) {
#    out <- as.vector(x = x, mode = "list")
#    return(out)
#  }
#  (out_nix_1 <- df_as_vector(x = df))

## ----parsermd-chunk-14, eval = FALSE------------------------------------------
#  out_nix_1_2 <- with_nix(
#    expr = function() df_as_vector(x = df),
#    program = "R",
#    project_path = path_env_1_2,
#    message_type = "simple" # you can do `"verbose"`, too
#  )

## ----parsermd-chunk-15, eval = FALSE------------------------------------------
#  identical(out_nix_1, out_nix_1_2)
#  # yields FALSE

## ----include = FALSE----------------------------------------------------------
unlink(path_env_1_2, recursive = TRUE, force = TRUE)

## ----parsermd-chunk-16, eval = FALSE------------------------------------------
#  stringr::str_subset(c("", "a"), "")

## ----parsermd-chunk-17, eval = FALSE------------------------------------------
#  out_system_stringr <- tryCatch(
#    expr = {
#      stringr::str_subset(c("", "a"), "")
#    },
#    error = function(e) NULL
#  )

