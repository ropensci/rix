testthat::test_that("rix(), ide is 'rstudio', Linux", {

  skip_if(Sys.info()["sysname"] == "Darwin")

  path_default_nix <- tempdir()

  save_default_nix_test <- function(ide, path_default_nix) {

    rix(r_ver = "4.3.1",
        r_pkgs = c("dplyr", "janitor", "AER@1.2-8", "quarto"),
        tex_pkgs = c("amsmath"),
        git_pkgs = list(
          list(package_name = "housing",
               repo_url = "https://github.com/rap4all/housing/",
               branch_name = "fusen",
               commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"),
          list(package_name = "fusen",
               repo_url = "https://github.com/ThinkR-open/fusen",
               branch_name = "main",
               commit = "d617172447d2947efb20ad6a4463742b8a5d79dc")
        ),
        ide = ide,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL)

    paste0(path_default_nix, "/default.nix")

  }

  testthat::announce_snapshot_file("rix/rstudio_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(ide = "rstudio", path_default_nix),
    name = "rstudio_default.nix",
  )


})


testthat::test_that("rix(), ide is 'other' or 'code'", {

  path_default_nix <- normalizePath(tempdir())

  save_default_nix_test <- function(ide, path_default_nix) {

    rix(r_ver = "4.3.1",
        r_pkgs = c("data.table", "janitor", "AER@1.2-8", "quarto"),
        tex_pkgs = c("amsmath"),
        git_pkgs = list(
          list(package_name = "housing",
               repo_url = "https://github.com/rap4all/housing/",
               branch_name = "fusen",
               commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"),
          list(package_name = "fusen",
               repo_url = "https://github.com/ThinkR-open/fusen",
               branch_name = "main",
               commit = "d617172447d2947efb20ad6a4463742b8a5d79dc")
        ),
        ide = ide,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL)

    file.path(path_default_nix, "default.nix")

  }


  testthat::announce_snapshot_file("rix/other_default.nix")

  testthat::expect_snapshot_file(
              path = save_default_nix_test(ide = "other",
                                           path_default_nix),
              name = "other_default.nix"
            )

  testthat::announce_snapshot_file("rix/code_default.nix")

  testthat::expect_snapshot_file(
              path = save_default_nix_test(ide = "code",
                                           path_default_nix),
              name = "code_default.nix"
              )

})


testthat::test_that("Quarto gets added to sys packages", {

  path_default_nix <- normalizePath(tempdir())

  save_default_nix_test <- function(pkgs, interface, path_default_nix) {

      rix(r_ver = "4.3.1",
          r_pkgs = pkgs,
          ide = interface,
          project_path = path_default_nix,
          overwrite = TRUE,
          shell_hook = NULL
          )

      file.path(path_default_nix, "default.nix")

  }

  testthat::announce_snapshot_file("rix/no_quarto_default.nix")

  testthat::expect_snapshot_file(
              path = save_default_nix_test(pkgs = "dplyr",
                                           interface = "other",
                                           path_default_nix),
              name = "no_quarto_default.nix",
              )

  testthat::announce_snapshot_file("rix/yes_quarto_default.nix")

  testthat::expect_snapshot_file(
              path = save_default_nix_test(pkgs = c("dplyr", "quarto", "data.table"),
                                           interface = "other",
                                           path_default_nix),
              name = "yes_quarto_default.nix"
            )
})


testthat::test_that("r_pkgs = NULL and ide = 'rstudio' work together", {

  skip_if(Sys.info()["sysname"] == "Darwin")

  path_default_nix <- tempdir()

  save_default_nix_test <- function(pkgs, interface, path_default_nix) {

    rix(r_ver = "4.3.1",
        r_pkgs = pkgs,
        ide = interface,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
        )

    file.path(path_default_nix, "default.nix")

  }

  testthat::announce_snapshot_file("rix/null_pkgs_rstudio.nix")

  testthat::expect_snapshot_file(
   path = save_default_nix_test(pkgs = NULL,
     interface = "rstudio",
     path_default_nix),
   name = "null_pkgs_rstudio.nix"
  )

})


testthat::test_that("If on darwin and ide = rstudio, raise warning", {

  skip_if(Sys.info()["sysname"] != "Darwin")

  path_default_nix <- normalizePath(tempdir())

  save_default_nix_test <- function(path_default_nix) {

    rix(r_ver = "4.3.1",
        ide = "rstudio",
        r_pkgs = NULL,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )

    file.path(path_default_nix, "default.nix")

  }

  testthat::expect_warning(
    save_default_nix_test(path_default_nix),
    regexp = "refer to the macOS"
  )

})

testthat::test_that("If R version is 4.4.0, raise warning", {

  path_default_nix <- tempdir()

  save_default_nix_test <- function(path_default_nix) {

    rix(r_ver = "4.4.0",
        ide = "other",
        r_pkgs = NULL,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )

    file.path(path_default_nix, "default.nix")

  }

  testthat::expect_warning(
    save_default_nix_test(path_default_nix),
    regexp = "version is not available"
  )

})

testthat::test_that("If R version is <= 4.1.1, raise warning", {

  path_default_nix <- tempdir()

  save_default_nix_test <- function(path_default_nix) {

    rix(r_ver = "4.1.1",
        ide = "other",
        r_pkgs = NULL,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )

    paste0(path_default_nix, "/default.nix")

  }

  testthat::expect_warning(
    save_default_nix_test(path_default_nix),
    regexp = "older version of R"
  )

})

testthat::test_that("If R version is == 3.5.3, raise warning", {

  path_default_nix <- tempdir()

  save_default_nix_test <- function(path_default_nix) {

    rix(r_ver = "3.5.3",
        ide = "other",
        r_pkgs = NULL,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )

    paste0(path_default_nix, "/default.nix")

  }

  testthat::expect_warning(
    save_default_nix_test(path_default_nix),
    regexp = "older version of R"
  )

})

testthat::test_that("rix(), bleeding_edge", {

  path_default_nix <- normalizePath(tempdir())

  save_default_nix_test <- function(ide, path_default_nix) {

    # This will generate the warning to read the vignette for bleeding_edge 
    suppressWarnings(
      rix(r_ver = "bleeding_edge",
          r_pkgs = c("dplyr", "janitor", "AER@1.2-8", "quarto"),
          tex_pkgs = c("amsmath"),
          git_pkgs = list(
            list(package_name = "housing",
                 repo_url = "https://github.com/rap4all/housing/",
                 branch_name = "fusen",
                 commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"),
            list(package_name = "fusen",
                 repo_url = "https://github.com/ThinkR-open/fusen",
                 branch_name = "main",
                 commit = "d617172447d2947efb20ad6a4463742b8a5d79dc")
          ),
          ide = ide,
          project_path = path_default_nix,
          overwrite = TRUE,
          shell_hook = NULL)
    )

    file.path(path_default_nix, "default.nix")

  }

  testthat::announce_snapshot_file("rix/bleeding_edge_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(ide = "other", path_default_nix),
    name = "bleeding_edge_default.nix",
  )


})

testthat::test_that("rix(), frozen_edge", {

  # because of the sed command, this will only work on Linux
  skip_if(Sys.info()["sysname"] != "Linux")

  path_default_nix <- normalizePath(tempdir())

  save_default_nix_test <- function(ide, path_default_nix) {

    # This will generate the warning to read the vignette for bleeding_edge 
    suppressWarnings(
      rix(r_ver = "frozen_edge",
          r_pkgs = c("dplyr", "janitor", "AER@1.2-8", "quarto"),
          tex_pkgs = c("amsmath"),
          git_pkgs = list(
            list(package_name = "housing",
                 repo_url = "https://github.com/rap4all/housing/",
                 branch_name = "fusen",
                 commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"),
            list(package_name = "fusen",
                 repo_url = "https://github.com/ThinkR-open/fusen",
                 branch_name = "main",
                 commit = "d617172447d2947efb20ad6a4463742b8a5d79dc")
          ),
          ide = ide,
          project_path = path_default_nix,
          overwrite = TRUE,
          shell_hook = NULL)
    )

    paste0(path_default_nix, "/default.nix")

  }

  testthat::announce_snapshot_file("rix/frozen_edge_default.nix")

  frozen_edge_commit <- get_right_commit("frozen_edge")

  system(
    paste0("sed -i 's/REVISION/", frozen_edge_commit, "/' _snaps/rix/frozen_edge_default.nix")
  )

  testthat::expect_snapshot_file(
    path = save_default_nix_test(ide = "other", path_default_nix),
    name = "frozen_edge_default.nix",
  )


  on.exit(
    system(
      paste0("sed -i 's/", frozen_edge_commit, "/REVISION/' _snaps/rix/frozen_edge_default.nix")
    )
  )

})
