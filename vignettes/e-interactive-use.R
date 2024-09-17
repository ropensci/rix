## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----include=FALSE------------------------------------------------------------
library(rix)

## ----parsermd-chunk-2, eval = FALSE-------------------------------------------
#  library(rix)
#  
#  path_to_project <- "~/Documents/kmeans"
#  
#  rix(
#    r_ver = "latest",
#    r_pkgs = c("dplyr", "ggplot2"),
#    system_pkgs = NULL,
#    git_pkgs = NULL,
#    ide = "rstudio",
#    project_path = path_to_project,
#    overwrite = TRUE,
#    print = TRUE
#  )

## ----eval = FALSE-------------------------------------------------------------
#  rix(
#    r_ver = "latest",
#    r_pkgs = c("dplyr", "ggplot2"),
#    system_pkgs = NULL,
#    git_pkgs = NULL,
#    ide = "code",
#    project_path = ".",
#    overwrite = TRUE
#  )

