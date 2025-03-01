library(rix)

rix(
  date = "2025-01-14",
  r_pkgs = c(
    "devtools",
    "diffviewer",
    "fledge",
    "lintr",
    "styler",
    "codetools",
    "jsonlite",
    "httr",
    "sys",
    "testthat",
    "knitr",
    "rmarkdown",
    "rhub"
  ),
  system_pkgs = c("R", "glibcLocalesUtf8", "pandoc", "nix"),
  tex_pkgs = c("inconsolata"),
  ide = "none",
  project_path = ".",
  overwrite = TRUE,
  print = FALSE,
  shell_hook = NULL
)
