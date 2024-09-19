testthat::test_that("rix(), ide is 'rstudio', Linux", {
  os_type <- Sys.info()["sysname"]
  skip_if(os_type == "Darwin" || os_type == "Windows")

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(ide, path_default_nix) {
    rix(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "janitor", "AER@1.2-8", "quarto"),
      tex_pkgs = c("amsmath"),
      git_pkgs = list(
        list(
          package_name = "housing",
          repo_url = "https://github.com/rap4all/housing/",
          commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
        ),
        list(
          package_name = "fusen",
          repo_url = "https://github.com/ThinkR-open/fusen",
          commit = "d617172447d2947efb20ad6a4463742b8a5d79dc"
        )
      ),
      ide = ide,
      project_path = path_default_nix,
      overwrite = TRUE,
      shell_hook = NULL
    )

    file.path(path_default_nix, "default.nix")
  }

  testthat::announce_snapshot_file("rix/rstudio_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(ide = "rstudio", path_default_nix),
    name = "rstudio_default.nix",
  )
})


testthat::test_that("rix(), ide is 'other' or 'code'", {
  os_type <- Sys.info()["sysname"]
  skip_if(os_type == "Windows")

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(ide, path_default_nix) {
    # We need to add this because this function gets called
    # twice, so the generated .Rprofile is there already and
    # calling the function again raises the warning.
    suppressWarnings(
      rix(
        r_ver = "4.3.1",
        r_pkgs = c("data.table", "janitor", "AER@1.2-8", "quarto"),
        tex_pkgs = c("amsmath"),
        git_pkgs = list(
          list(
            package_name = "housing",
            repo_url = "https://github.com/rap4all/housing/",
            commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
          ),
          list(
            package_name = "fusen",
            repo_url = "https://github.com/ThinkR-open/fusen",
            commit = "d617172447d2947efb20ad6a4463742b8a5d79dc"
          )
        ),
        ide = ide,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )
    )

    file.path(path_default_nix, "default.nix")
  }


  testthat::announce_snapshot_file("rix/other_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(
      ide = "other",
      path_default_nix
    ),
    name = "other_default.nix"
  )

  testthat::announce_snapshot_file("rix/code_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(
      ide = "code",
      path_default_nix
    ),
    name = "code_default.nix"
  )

  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})


testthat::test_that("Quarto gets added to sys packages", {
  os_type <- Sys.info()["sysname"]
  skip_if(os_type == "Windows")

  path_default_nix <- normalizePath(tempdir())
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(pkgs, interface, path_default_nix) {
    # Because of rix_init, see above
    suppressWarnings(
      rix(
        r_ver = "4.3.1",
        r_pkgs = pkgs,
        ide = interface,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )
    )

    file.path(path_default_nix, "default.nix")
  }

  testthat::announce_snapshot_file("rix/no_quarto_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(
      pkgs = "dplyr",
      interface = "other",
      path_default_nix
    ),
    name = "no_quarto_default.nix",
  )

  testthat::announce_snapshot_file("rix/yes_quarto_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(
      pkgs = c("dplyr", "quarto", "data.table"),
      interface = "other",
      path_default_nix
    ),
    name = "yes_quarto_default.nix"
  )

  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})

testthat::test_that("If on darwin and ide = rstudio, raise warning", {
  os_type <- Sys.info()["sysname"]
  skip_if(os_type != "Darwin" || os_type == "Windows")

  path_default_nix <- normalizePath(tempdir())
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.3.1",
      ide = "rstudio",
      r_pkgs = "dplyr",
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
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.4.0",
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
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.1.1",
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

testthat::test_that("If on ide = rstudio, but no R packages, raise error", {
  path_default_nix <- tempdir()
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.3.1",
      ide = "rstudio",
      r_pkgs = NULL,
      project_path = path_default_nix,
      overwrite = TRUE,
      shell_hook = NULL
    )

    paste0(path_default_nix, "/default.nix")
  }

  testthat::expect_error(
    save_default_nix_test(path_default_nix),
    regexp = "didn't add any R packages"
  )
})

testthat::test_that("If R version is == 3.5.3, raise warning", {
  path_default_nix <- tempdir()
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "3.5.3",
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
  os_type <- Sys.info()["sysname"]
  skip_if(os_type == "Windows")

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(ide, path_default_nix) {
    # This will generate the warning to read the vignette for bleeding_edge
    suppressWarnings(
      rix(
        r_ver = "bleeding_edge",
        r_pkgs = c("dplyr", "janitor", "AER@1.2-8", "quarto"),
        tex_pkgs = c("zmsmath", "amsmath"),
        git_pkgs = list(
          list(
            package_name = "housing",
            repo_url = "https://github.com/rap4all/housing/",
            commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
          ),
          list(
            package_name = "fusen",
            repo_url = "https://github.com/ThinkR-open/fusen",
            commit = "d617172447d2947efb20ad6a4463742b8a5d79dc"
          )
        ),
        ide = ide,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )
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

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    {
      system(
        paste0("sed -i 's/", frozen_edge_commit, "/REVISION/' _snaps/rix/frozen_edge_default.nix")
      )
      unlink(path_default_nix, recursive = TRUE, force = FALSE)
      unlink(tmpdir, recursive = TRUE, force = FALSE)
    },
    add = TRUE
  )

  save_default_nix_test <- function(ide, path_default_nix) {
    # This will generate the warning to read the vignette for bleeding_edge
    suppressWarnings(
      rix(
        r_ver = "frozen_edge",
        r_pkgs = c("dplyr", "janitor", "AER@1.2-8", "quarto"),
        tex_pkgs = c("amsmath"),
        git_pkgs = list(
          list(
            package_name = "housing",
            repo_url = "https://github.com/rap4all/housing/",
            commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
          ),
          list(
            package_name = "fusen",
            repo_url = "https://github.com/ThinkR-open/fusen",
            commit = "d617172447d2947efb20ad6a4463742b8a5d79dc"
          )
        ),
        ide = ide,
        project_path = path_default_nix,
        overwrite = TRUE,
        shell_hook = NULL
      )
    )

    file.path(path_default_nix, "/default.nix")
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
    {
      system(
        paste0("sed -i 's/", frozen_edge_commit, "/REVISION/' _snaps/rix/frozen_edge_default.nix")
      )
      unlink(path_default_nix, recursive = TRUE, force = FALSE)
    },
    add = TRUE
  )
})


testthat::test_that("rix(), only one Github package", {
  os_type <- Sys.info()["sysname"]
  skip_if(os_type == "Windows")

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.3.1",
      r_pkgs = NULL,
      system_pkgs = NULL,
      git_pkgs = list(
        package_name = "lookup",
        repo_url = "https://github.com/jimhester/lookup/",
        commit = "eba63db477dd2f20153b75e2949eb333a36cccfc"
      ),
      ide = "other",
      project_path = path_default_nix,
      overwrite = TRUE
    )

    file.path(path_default_nix, "default.nix")
  }

  testthat::announce_snapshot_file("rix/one_git_default.nix")

  testthat::expect_snapshot_file(
    path = save_default_nix_test(path_default_nix),
    name = "one_git_default.nix",
  )
})


testthat::test_that("rix(), conclusion message", {
  tmpdir <- tempdir()
  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.3.1",
      ide = "other",
      project_path = path_default_nix,
      message_type = "simple",
      overwrite = TRUE
    )

    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_message(
    save_default_nix_test(path_default_nix),
    regexp = "Successfully"
  )
})


testthat::test_that("rix(), warning message if rix_init() already called", {
  testthat::skip_on_os(os = c("windows", "mac"))

  tmpdir <- tempdir()

  path_default_nix <- paste0(
    tmpdir, paste0(sample(letters, 5), collapse = "")
  )
  dir.create(path_default_nix)
  path_default_nix <- normalizePath(path_default_nix)
  on.exit(
    unlink(path_default_nix, recursive = TRUE, force = TRUE),
    add = TRUE
  )
  on.exit(
    unlink(tmpdir, recursive = TRUE, force = TRUE),
    add = TRUE
  )

  rix_init(
    project_path = path_default_nix,
    rprofile_action = "overwrite",
    message_type = "simple"
  )

  # Remove lines starting with # so rix() thinks the
  # .Rprofile file was not generated by rix_init()
  system(
    paste0(
      "sed -i '/^#/d' ",
      file.path(path_default_nix, ".Rprofile")
    )
  )

  save_default_nix_test <- function(path_default_nix) {
    rix(
      r_ver = "4.3.1",
      ide = "other",
      project_path = path_default_nix,
      message_type = "simple",
      overwrite = TRUE
    )

    file.path(path_default_nix, "default.nix")
  }

  testthat::expect_warning(
    save_default_nix_test(path_default_nix),
    regexp = "You may"
  )
})
