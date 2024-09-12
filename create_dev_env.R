library(rix)

rix(r_ver = "bleeding_edge",
    r_pkgs = c("devtools", "diffviewer", "fledge", "lintr", "styler",
               "codetools", "jsonlite",  "httr", "sys", "testthat", "knitr",
               "rmarkdown", "rhub"),
    system_pkgs = c("R", "glibcLocalesUtf8", "pandoc", "nix"),
    tex_pkgs = "scheme-small",
    ide = "other",
    project_path = ".",
    overwrite = TRUE,
    print = FALSE,
    shell_hook = NULL)
