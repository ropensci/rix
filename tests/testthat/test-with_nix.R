testthat::test_that("Testing `with_nix()` if Nix is installed", {
  skip_on_covr()

  if (isFALSE(is_nix_r_session())) {
    # needed for the GitHub test runners with system's R
    set_nix_path()
  }

  skip_if_not(nix_shell_available())
  # R version 3.5.3 on Nixpkgs does not build for aarch64-darwin (ARM macOS)
  skip_if(Sys.info()["sysname"] == "Darwin")


  path_subshell <- tempdir()

  # Suppress the warning related to generating an expression
  # for an old version of R
  suppressWarnings(
    rix(
      r_ver = "3.5.3",
      overwrite = TRUE,
      project_path = path_subshell,
      shell_hook = NULL
    )
  )

  out_subshell <- with_nix(
    expr = function() {
      set.seed(1234)
      a <- sample(seq_len(10), 5)
      set.seed(NULL)
      return(a)
    },
    program = "R",
    project_path = path_subshell,
    message_type = "simple"
  )

  # On a recent version of R, set.seed(1234);sample(seq(1,10), 5)
  # returns c(10, 6, 5, 4, 1)
  # but not on versions prior to 3.6
  testthat::expect_true(
    all(c(2, 6, 5, 8, 9) == out_subshell)
  )

  on.exit(
    unlink(path_subshell, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})

testthat::test_that("Test `with_nix()` if Nix is installed on R 4.2.0", {
  skip_on_covr()

  if (isFALSE(is_nix_r_session())) {
    # needed for the GitHub test runners with system's R
    set_nix_path()
  }

  skip_if_not(nix_shell_available())

  path_subshell <- tempdir()

  rix(
    r_ver = "4.2.0",
    overwrite = TRUE,
    project_path = path_subshell,
    shell_hook = NULL
  )

  df <- data.frame(a = 1:3, b = 4:6)

  out_subshell <- with_nix(
    expr = function() {
      as.vector(x = data.frame(a = 1:3, b = 4:6), mode = "list")
    },
    program = "R",
    project_path = path_subshell,
    message_type = "verbose"
  )

  testthat::expect_false(
    inherits(out_subshell, "data.frame")
  )


  on.exit(
    unlink(path_subshell, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})


testthat::test_that("Test `with_nix()` correct .libPaths()", {
  skip_on_covr()

  if (isFALSE(is_nix_r_session())) {
    # needed for the GitHub test runners with system's R
    set_nix_path()
  }

  skip_if_not(nix_shell_available())

  path_subshell <- tempdir()

  rix(
    r_ver = "4.3.1",
    overwrite = TRUE,
    project_path = path_subshell,
    shell_hook = NULL
  )

  out_subshell <- with_nix(
    expr = function() {
      .libPaths()
    },
    program = "R",
    project_path = path_subshell,
    message_type = "verbose"
  )

  testthat::expect_true(
    is.character(out_subshell)
  )

  on.exit(
    unlink(path_subshell, recursive = TRUE, force = TRUE),
    add = TRUE
  )
})
