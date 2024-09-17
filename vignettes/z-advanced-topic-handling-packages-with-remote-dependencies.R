## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----include=FALSE------------------------------------------------------------
library(rix)

## ----eval = F-----------------------------------------------------------------
#  path_default_nix <- tempdir()
#  
#  rix(
#    r_ver = "latest",
#    r_pkgs = NULL,
#    system_pkgs = NULL,
#    git_pkgs = list(
#      package_name = "lookup",
#      repo_url = "https://github.com/jimhester/lookup/",
#      commit = "eba63db477dd2f20153b75e2949eb333a36cccfc"
#    ),
#    ide = "other",
#    project_path = path_default_nix,
#    overwrite = TRUE,
#    print = TRUE
#  )

## ----eval = F-----------------------------------------------------------------
#  path_default_nix <- tempdir()
#  
#  rix(
#    r_ver = "latest",
#    r_pkgs = NULL,
#    system_pkgs = NULL,
#    git_pkgs = list(
#      package_name = "highlite",
#      repo_url = "https://github.com/jimhester/highlite/",
#      commit = "767b122ef47a60a01e1707e4093cf3635a99c86b"
#    ),
#    ide = "other",
#    project_path = path_default_nix,
#    overwrite = FALSE,
#    print = TRUE
#  )

