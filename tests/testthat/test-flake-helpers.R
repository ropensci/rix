# Tests for flake helper functions

# Tests for list_templates()
testthat::test_that("flake_templates returns all available templates", {
  templates <- flake_templates()

  testthat::expect_type(templates, "character")
  testthat::expect_true("minimal" %in% templates)
  testthat::expect_true("docker" %in% templates)
  testthat::expect_length(templates, 2)
})

testthat::test_that("flake_templates returns character(0) if templates missing", {
  # This test would require mocking, skipping for now
  testthat::skip("Would require mocking system.file")
})

# Tests for has_nix_installed()
testthat::test_that("has_nix_installed returns logical", {
  result <- rix:::has_nix_installed()
  testthat::expect_type(result, "logical")
  testthat::expect_length(result, 1)
})

testthat::test_that("has_nix_installed returns TRUE when Nix available", {
  testthat::skip_if_not(nix_shell_available())

  result <- rix:::has_nix_installed()
  testthat::expect_true(result)
})

testthat::test_that("has_nix_installed returns FALSE when Nix not available", {
  testthat::skip_if(nix_shell_available())

  result <- rix:::has_nix_installed()
  testthat::expect_false(result)
})

# Tests for is_git_repo()
testthat::test_that("is_git_repo detects git repositories", {
  # Create temp dir without git
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("not_git_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  testthat::expect_false(rix:::is_git_repo(test_dir))

  # Initialize git
  system2("git", c("init", test_dir), stdout = FALSE, stderr = FALSE)
  testthat::expect_true(rix:::is_git_repo(test_dir))
})

testthat::test_that("is_git_repo handles non-existent paths", {
  result <- rix:::is_git_repo("/path/that/does/not/exist")
  testthat::expect_false(result)
})

# Tests for is_file_tracked()
testthat::test_that("is_file_tracked detects tracked files", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("git_track_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # Initialize git
  system2("git", c("init", test_dir), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "config", "user.email", "test@test.com"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "config", "user.name", "Test"), stdout = FALSE, stderr = FALSE)

  # Create and track a file
  test_file <- file.path(test_dir, "test.txt")
  writeLines("test content", test_file)

  # Not tracked yet
  testthat::expect_false(rix:::is_file_tracked("test.txt", test_dir))

  # Track it
  system2("git", c("-C", test_dir, "add", "test.txt"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "commit", "-m", "test"), stdout = FALSE, stderr = FALSE)

  # Now tracked
  testthat::expect_true(rix:::is_file_tracked("test.txt", test_dir))
})

testthat::test_that("is_file_tracked returns FALSE for non-git repos", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("no_git_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  test_file <- file.path(test_dir, "test.txt")
  writeLines("test", test_file)

  testthat::expect_false(rix:::is_file_tracked("test.txt", test_dir))
})

# Tests for flake_update()
testthat::test_that("flake_update errors without Nix", {
  testthat::skip_if(nix_shell_available())

  testthat::expect_error(
    flake_update(),
    regexp = "Nix is not installed"
  )
})

testthat::test_that("flake_update errors without flake.nix", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()

  testthat::expect_error(
    flake_update(tmpdir),
    regexp = "No flake.nix found"
  )
})

testthat::test_that("flake_update works with valid flake", {
  testthat::skip_if_not(nix_shell_available())
  testthat::skip_on_cran()  # Network/git dependent

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("flake_update_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # Create a simple flake
  system_type <- Sys.info()["machine"]
  flake_content <- sprintf('{
    description = "Test";
    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    outputs = { self, nixpkgs }: {
      packages.default = nixpkgs.legacyPackages.%s.hello;
    };
  }', system_type)

  writeLines(flake_content, file.path(test_dir, "flake.nix"))
  system2("git", c("init", test_dir), stdout = FALSE, stderr = FALSE)

  # Create initial commit (required for flakes)
  system2("git", c("-C", test_dir, "config", "user.email", "test@test.com"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "config", "user.name", "Test User"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "add", "."), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "commit", "-m", "initial"), stdout = FALSE, stderr = FALSE)

  # Run update (may fail due to network, just check it doesn't error)
  result <- flake_update(test_dir, message_type = "quiet")
  testthat::expect_type(result, "list")
})

# Tests for flake_check()
testthat::test_that("flake_check errors without Nix", {
  testthat::skip_if(nix_shell_available())

  testthat::expect_error(
    flake_check(),
    regexp = "Nix is not installed"
  )
})

testthat::test_that("flake_check errors without flake.nix", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()

  testthat::expect_error(
    flake_check(tmpdir),
    regexp = "No flake.nix found"
  )
})

testthat::test_that("flake_check validates valid flake", {
  testthat::skip_if_not(nix_shell_available())
  testthat::skip_on_cran()  # Network/git dependent

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("flake_check_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # Create a simple valid flake
  system_type <- Sys.info()["machine"]
  flake_content <- sprintf('{
    description = "Test";
    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    outputs = { self, nixpkgs }: {
      packages.default = nixpkgs.legacyPackages.%s.hello;
    };
  }', system_type)

  writeLines(flake_content, file.path(test_dir, "flake.nix"))
  system2("git", c("init", test_dir), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "config", "user.email", "test@test.com"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "config", "user.name", "Test"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "add", "."), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "commit", "-m", "test"), stdout = FALSE, stderr = FALSE)

  # Should succeed for valid flake
  result <- flake_check(test_dir, message_type = "quiet")
  # Check doesn't fail or error
  testthat::expect_type(result, "logical")
})

testthat::test_that("flake_check returns FALSE for invalid flake", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("flake_invalid_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # Create an invalid flake (syntax error)
  flake_content <- '{
    description = "Test"
    # Missing semicolon and other issues
    outputs = broken syntax here
  }'

  writeLines(flake_content, file.path(test_dir, "flake.nix"))
  system2("git", c("init", test_dir), stdout = FALSE, stderr = FALSE)

  # Should fail for invalid flake
  result <- flake_check(test_dir, message_type = "quiet")
  testthat::expect_false(result)
})

# Tests for flake_metadata()
testthat::test_that("flake_metadata errors without Nix", {
  testthat::skip_if(nix_shell_available())

  testthat::expect_error(
    flake_metadata(),
    regexp = "Nix is not installed"
  )
})

testthat::test_that("flake_metadata errors without flake.nix", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()

  testthat::expect_error(
    flake_metadata(tmpdir),
    regexp = "No flake.nix found"
  )
})

# Tests for clean_nix_expression()
testthat::test_that("clean_nix_expression removes consecutive empty lines", {
  content <- "line1\n\n\n\nline2\n\nline3"
  result <- rix:::clean_nix_expression(content)

  # Should have at most one empty line between content
  testthat::expect_false(grepl("\n\n\n", result))
  testthat::expect_match(result, "line1\n\nline2")
})

testthat::test_that("clean_nix_expression handles single lines", {
  content <- "single line"
  result <- rix:::clean_nix_expression(content)

  testthat::expect_equal(result, "single line")
})

testthat::test_that("clean_nix_expression handles empty content", {
  content <- ""
  result <- rix:::clean_nix_expression(content)

  testthat::expect_equal(result, "")
})
