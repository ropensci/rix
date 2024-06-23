library(rix)

latest_commit <- sys::as_text(sys::exec_internal("git", c("rev-parse", "master"))$stdout)


rix(r_ver = "bleeding_edge",
    r_pkgs = c("devtools", "diffviewer", "fledge", "styler", "precommit",
               "codetools", "jsonlite",  "httr", "sys", "testthat", "knitr",
               "rmarkdown", "renv", "digest"),
    system_pkgs = c("R", "glibcLocalesUtf8", "pandoc", "nix", "pre-commit"),
    tex_pkgs = "scheme-small",
    ide = "other",
    project_path = ".",
    overwrite = TRUE,
    print = FALSE,
    shell_hook = NULL)
