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
#  
#  rix(
#    r_ver = "4.3.1",
#    r_pkgs = c("quarto"),
#    system_pkgs = "quarto",
#    tex_pkgs = c("amsmath"),
#    ide = "other",
#    shell_hook = "",
#    project_path = path_default_nix,
#    overwrite = TRUE,
#    print = TRUE
#  )

## ----eval = FALSE-------------------------------------------------------------
#  rix(
#    r_ver = "4.3.1",
#    r_pkgs = c("quarto", "MASS"),
#    system_pkgs = "quarto",
#    tex_pkgs = c("amsmath"),
#    ide = "other",
#    shell_hook = "",
#    project_path = path_default_nix,
#    overwrite = TRUE,
#    print = TRUE
#  )

## ----eval = FALSE-------------------------------------------------------------
#  rix(
#    r_ver = "4.3.1",
#    r_pkgs = c("quarto", "MASS"),
#    system_pkgs = "quarto",
#    tex_pkgs = c(
#      "amsmath",
#      "environ",
#      "fontawesome5",
#      "orcidlink",
#      "pdfcol",
#      "tcolorbox",
#      "tikzfill"
#    ),
#    ide = "other",
#    shell_hook = "",
#    project_path = path_default_nix,
#    overwrite = TRUE,
#    print = TRUE
#  )

