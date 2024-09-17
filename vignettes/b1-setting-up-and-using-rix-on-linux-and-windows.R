## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----include=FALSE------------------------------------------------------------
library(rix)

## ----eval = F-----------------------------------------------------------------
#  rix(
#    r_ver = "latest",
#    r_pkgs = c("dplyr", "ggplot2"),
#    system_pkgs = NULL,
#    git_pkgs = NULL,
#    ide = "other",
#    project_path = ".",
#    overwrite = TRUE
#  )

## ----eval = F-----------------------------------------------------------------
#  rix(
#    r_ver = "latest",
#    r_pkgs = NULL,
#    git_pkgs = list(
#      package_name = "rix",
#      repo_url = "https://github.com/ropensci/rix",
#      commit = "76d1bdd03d78589d399b4b9d473ecde616920a82"
#    ),
#    ide = "other",
#    project_path = ".",
#    overwrite = TRUE
#  )

## ----parsermd-chunk-2, eval = FALSE-------------------------------------------
#  install.packages("rix", repos = c(
#    "https://ropensci.r-universe.dev",
#    "https://cloud.r-project.org"
#  ))

