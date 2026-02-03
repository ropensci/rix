# Integration tests for init_flake()

# Helper function to create git repo
create_git_repo <- function(path) {
  system2("git", c("init", path), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", path, "config", "user.email", "test@test.com"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", path, "config", "user.name", "Test User"), stdout = FALSE, stderr = FALSE)
}

test_that("init_flake creates correct files with minimal template", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0(sample(letters, 10), collapse = ""))
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  result <- init_flake(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr", "ggplot2"),
    template = "minimal",
    project_path = test_dir,
    message_type = "quiet",
    git_tracking = FALSE
  )

  # Check files created
  expect_true(file.exists(file.path(test_dir, "flake.nix")))
  expect_true(file.exists(file.path(test_dir, ".rixpackages.nix")))

  # Check result is path
  expect_equal(result, file.path(test_dir, "flake.nix"))

  # Check content
  flake_content <- readLines(file.path(test_dir, "flake.nix"))
  expect_true(any(grepl("flake-utils", flake_content)))
})

test_that("init_flake minimal template snapshot", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "minimal_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "ggplot2", "quarto"),
      system_pkgs = c("pandoc"),
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      overwrite = TRUE,
      git_tracking = FALSE
    )
  )

  # Snapshot both files
  expect_snapshot_file(
    file.path(test_dir, "flake.nix"),
    name = "minimal_flake.nix"
  )

  expect_snapshot_file(
    file.path(test_dir, ".rixpackages.nix"),
    name = "minimal_rixpackages.nix"
  )
})

test_that("init_flake radian template snapshot", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "radian_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("data.table", "janitor"),
      template = "radian",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  expect_snapshot_file(
    file.path(test_dir, "flake.nix"),
    name = "radian_flake.nix"
  )
})

test_that("init_flake docker template snapshot", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "docker_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("plumber", "dplyr"),
      template = "docker",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  expect_snapshot_file(
    file.path(test_dir, "flake.nix"),
    name = "docker_flake.nix"
  )
})

test_that("init_flake rstudio template snapshot", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "rstudio_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "shiny"),
      template = "rstudio",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  expect_snapshot_file(
    file.path(test_dir, "flake.nix"),
    name = "rstudio_flake.nix"
  )
})

test_that("init_flake vscode template snapshot", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "vscode_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "devtools"),
      template = "vscode",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  expect_snapshot_file(
    file.path(test_dir, "flake.nix"),
    name = "vscode_flake.nix"
  )
})

test_that("init_flake positron template snapshot", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "positron_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "tidyverse"),
      template = "positron",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  expect_snapshot_file(
    file.path(test_dir, "flake.nix"),
    name = "positron_flake.nix"
  )
})

test_that("init_flake errors on invalid template", {
  expect_error(
    init_flake(template = "invalid"),
    regexp = "Invalid template"
  )

  expect_error(
    init_flake(template = "notexist"),
    regexp = "Invalid template"
  )
})

test_that("init_flake respects overwrite parameter", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "overwrite_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # First call succeeds
  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  # Second call without overwrite fails
  expect_error(
    suppressMessages(
      init_flake(
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
  expect_no_error(
    suppressMessages(
      init_flake(
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

test_that("init_flake warns about git repository", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "no_git_test")
  dir.create(test_dir)
  # No git init

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  expect_message(
    init_flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      git_tracking = TRUE
    ),
    regexp = "not a git repository"
  )
})

test_that("init_flake warns when Nix not installed", {
  skip_if(nix_shell_available())  # Only run if Nix NOT available

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "no_nix_test")
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  expect_message(
    init_flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      git_tracking = FALSE
    ),
    regexp = "Nix does not appear to be installed"
  )
})

test_that("init_flake creates project directory if needed", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "new_dir", "subdir")
  # Directory doesn't exist yet

  on.exit(unlink(file.path(tmpdir, "new_dir"), recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  expect_true(dir.exists(test_dir))
  expect_true(file.exists(file.path(test_dir, "flake.nix")))
})

test_that("init_flake handles complex package configurations", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "complex_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
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

  expect_match(rixpackages_str, "dplyr")
  expect_match(rixpackages_str, "ggplot2")
  expect_match(rixpackages_str, "tex")
  expect_match(rixpackages_str, "system_packages")
})

test_that("init_flake handles Python configuration", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "python_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressWarnings(
    suppressMessages(
      init_flake(
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
  expect_true(any(grepl("pyconf", rixpackages)))
})

test_that("init_flake handles date parameter", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "date_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
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
  expect_true(grepl("rstats-on-nix", flake_str))
})

test_that("init_flake includes cachix config for rstats-on-nix", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "cachix_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
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
  expect_match(flake_str, "extra-substituters")
  expect_match(flake_str, "rstats-on-nix.cachix.org")
})

test_that("init_flake does not include cachix for upstream nixpkgs", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "no_cachix_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
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
  expect_false(grepl("rstats-on-nix.cachix.org", flake_str))
})

test_that("init_flake handles shell_hook", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "hook_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
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

  expect_match(rixpackages_str, "Welcome!")
})
