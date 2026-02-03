# Integration tests for flake()

# Helper function to create git repo
create_git_repo <- function(path) {
  system2("git", c("init", path), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", path, "config", "user.email", "test@test.com"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", path, "config", "user.name", "Test User"), stdout = FALSE, stderr = FALSE)
}

testthat::test_that("flake creates correct files with minimal template", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0(sample(letters, 10), collapse = ""))
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  result <- flake(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr", "ggplot2"),
    template = "minimal",
    project_path = test_dir,
    message_type = "quiet",
    git_tracking = FALSE
  )

  # Check files created
  testthat::expect_true(file.exists(file.path(test_dir, "flake.nix")))
  testthat::expect_true(file.exists(file.path(test_dir, ".rixpackages.nix")))

  # Check result is path
  testthat::expect_equal(result, file.path(test_dir, "flake.nix"))

  # Check content
  flake_content <- readLines(file.path(test_dir, "flake.nix"))
  testthat::expect_true(any(grepl("flake-utils", flake_content)))
})



testthat::test_that("flake errors on invalid template", {
  testthat::expect_error(
    flake(template = "invalid"),
    regexp = "Invalid template"
  )

  testthat::expect_error(
    flake(template = "notexist"),
    regexp = "Invalid template"
  )
})

testthat::test_that("flake respects overwrite parameter", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "overwrite_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # First call succeeds
  suppressMessages(
    flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  # Second call without overwrite fails
  testthat::expect_error(
    suppressMessages(
      flake(
        r_ver = "4.3.1",
        template = "minimal",
        project_path = test_dir,
        message_type = "quiet",
        git_tracking = FALSE
      )
    ),
    regexp = "overwrite"
  )

  # With overwrite succeeds
  testthat::expect_no_error(
    suppressMessages(
      flake(
        r_ver = "4.3.1",
        template = "minimal",
        project_path = test_dir,
        message_type = "quiet",
        overwrite = TRUE,
        git_tracking = FALSE
      )
    )
  )
})

testthat::test_that("flake warns about git repository", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "no_git_test")
  dir.create(test_dir)
  # No git init

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_message(
    flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      git_tracking = TRUE
    ),
    regexp = "not a git repository"
  )
})

testthat::test_that("flake warns when Nix not installed", {
  testthat::skip_if(nix_shell_available())  # Only run if Nix NOT available

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "no_nix_test")
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_message(
    flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      git_tracking = FALSE
    ),
    regexp = "Nix does not appear to be installed"
  )
})

testthat::test_that("flake creates project directory if needed", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "new_dir", "subdir")
  # Directory doesn't exist yet

  on.exit(unlink(file.path(tmpdir, "new_dir"), recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  testthat::expect_true(dir.exists(test_dir))
  testthat::expect_true(file.exists(file.path(test_dir, "flake.nix")))
})

testthat::test_that("flake handles complex package configurations", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "complex_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "ggplot2", "AER@1.2-8"),
      system_pkgs = c("nix", "pandoc", "quarto"),
      tex_pkgs = c("amsmath", "booktabs"),
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  # Check all package types are included
  rixpackages <- readLines(file.path(test_dir, ".rixpackages.nix"))
  rixpackages_str <- paste(rixpackages, collapse = "\n")

  testthat::expect_match(rixpackages_str, "dplyr")
  testthat::expect_match(rixpackages_str, "ggplot2")
  testthat::expect_match(rixpackages_str, "tex")
  testthat::expect_match(rixpackages_str, "system_packages")
})

testthat::test_that("flake handles Python configuration", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "python_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressWarnings(
    suppressMessages(
      flake(
        r_ver = "4.3.1",
        r_pkgs = "reticulate",
        py_conf = list(
          py_version = "3.12",
          py_pkgs = c("numpy", "pandas")
        ),
        template = "minimal",
        project_path = test_dir,
        message_type = "quiet",
        git_tracking = FALSE
      )
    )
  )

  rixpackages <- readLines(file.path(test_dir, ".rixpackages.nix"))
  testthat::expect_true(any(grepl("pyconf", rixpackages)))
})

testthat::test_that("flake handles date parameter", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "date_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    flake(
      date = "2025-01-15",
      r_pkgs = c("dplyr"),
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  flake <- readLines(file.path(test_dir, "flake.nix"))
  flake_str <- paste(flake, collapse = "\n")

  # Should reference the date in nixpkgs
  testthat::expect_true(grepl("rstats-on-nix", flake_str))
})

testthat::test_that("flake includes cachix config for rstats-on-nix", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "cachix_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    flake(
      r_ver = "4.3.1",  # Uses rstats-on-nix
      r_pkgs = c("dplyr"),
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  flake <- readLines(file.path(test_dir, "flake.nix"))
  flake_str <- paste(flake, collapse = "\n")

  # Should include cachix configuration
  testthat::expect_match(flake_str, "extra-substituters")
  testthat::expect_match(flake_str, "rstats-on-nix.cachix.org")
})

testthat::test_that("flake does not include cachix for upstream nixpkgs", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "no_cachix_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    flake(
      r_ver = "latest-upstream",  # Uses NixOS/nixpkgs
      r_pkgs = c("dplyr"),
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  flake <- readLines(file.path(test_dir, "flake.nix"))
  flake_str <- paste(flake, collapse = "\n")

  # Should NOT include rstats-on-nix cachix
  testthat::expect_false(grepl("rstats-on-nix.cachix.org", flake_str))
})

testthat::test_that("flake handles shell_hook", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "hook_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr"),
      template = "minimal",
      project_path = test_dir,
      shell_hook = "echo 'Welcome!'",
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  rixpackages <- readLines(file.path(test_dir, ".rixpackages.nix"))
  rixpackages_str <- paste(rixpackages, collapse = "\n")

  testthat::expect_match(rixpackages_str, "Welcome!")
})
