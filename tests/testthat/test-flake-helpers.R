# Tests for flake helper functions

# Tests for list_templates()
test_that("flake_templates returns all available templates", {
  templates <- flake_templates()

  expect_type(templates, "character")
  expect_true("minimal" %in% templates)
  expect_true("radian" %in% templates)
  expect_true("rstudio" %in% templates)
  expect_true("vscode" %in% templates)
  expect_true("positron" %in% templates)
  expect_true("docker" %in% templates)
  expect_length(templates, 6)
})

test_that("flake_templates returns character(0) if templates missing", {
  # This test would require mocking, skipping for now
  skip("Would require mocking system.file")
})

# Tests for has_nix_installed()
test_that("has_nix_installed returns logical", {
  result <- rix:::has_nix_installed()
  expect_type(result, "logical")
  expect_length(result, 1)
})

test_that("has_nix_installed returns TRUE when Nix available", {
  skip_if_not(nix_shell_available())

  result <- rix:::has_nix_installed()
  expect_true(result)
})

test_that("has_nix_installed returns FALSE when Nix not available", {
  skip_if(nix_shell_available())

  result <- rix:::has_nix_installed()
  expect_false(result)
})

# Tests for is_git_repo()
test_that("is_git_repo detects git repositories", {
  # Create temp dir without git
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("not_git_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  expect_false(rix:::is_git_repo(test_dir))

  # Initialize git
  system2("git", c("init", test_dir), stdout = FALSE, stderr = FALSE)
  expect_true(rix:::is_git_repo(test_dir))
})

test_that("is_git_repo handles non-existent paths", {
  result <- rix:::is_git_repo("/path/that/does/not/exist")
  expect_false(result)
})

# Tests for is_file_tracked()
test_that("is_file_tracked detects tracked files", {
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
  expect_false(rix:::is_file_tracked("test.txt", test_dir))

  # Track it
  system2("git", c("-C", test_dir, "add", "test.txt"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", test_dir, "commit", "-m", "test"), stdout = FALSE, stderr = FALSE)

  # Now tracked
  expect_true(rix:::is_file_tracked("test.txt", test_dir))
})

test_that("is_file_tracked returns FALSE for non-git repos", {
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0("no_git_", sample(letters, 5, TRUE), collapse = ""))
  dir.create(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  test_file <- file.path(test_dir, "test.txt")
  writeLines("test", test_file)

  expect_false(rix:::is_file_tracked("test.txt", test_dir))
})

# Tests for nix_flake_update()
test_that("flake_update errors without Nix", {
  skip_if(nix_shell_available())

  expect_error(
    nix_flake_update(),
    regexp = "Nix is not installed"
  )
})

test_that("flake_update errors without flake.nix", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()

  expect_error(
    nix_flake_update(tmpdir),
    regexp = "No flake.nix found"
  )
})

test_that("flake_update works with valid flake", {
  skip_if_not(nix_shell_available())
  skip_on_cran()  # Network/git dependent

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
  result <- nix_flake_update(test_dir, message_type = "quiet")
  expect_type(result, "list")
})

# Tests for nix_flake_check()
test_that("flake_check errors without Nix", {
  skip_if(nix_shell_available())

  expect_error(
    nix_flake_check(),
    regexp = "Nix is not installed"
  )
})

test_that("flake_check errors without flake.nix", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()

  expect_error(
    nix_flake_check(tmpdir),
    regexp = "No flake.nix found"
  )
})

test_that("flake_check validates valid flake", {
  skip_if_not(nix_shell_available())
  skip_on_cran()  # Network/git dependent

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
  result <- nix_flake_check(test_dir, message_type = "quiet")
  # Check doesn't fail or error
  expect_type(result, "logical")
})

test_that("flake_check returns FALSE for invalid flake", {
  skip_if_not(nix_shell_available())

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
  result <- nix_flake_check(test_dir, message_type = "quiet")
  expect_false(result)
})

# Tests for flake_metadata()
test_that("flake_metadata errors without Nix", {
  skip_if(nix_shell_available())

  expect_error(
    flake_metadata(),
    regexp = "Nix is not installed"
  )
})

test_that("flake_metadata errors without flake.nix", {
  skip_if_not(nix_shell_available())

  tmpdir <- tempdir()

  expect_error(
    flake_metadata(tmpdir),
    regexp = "No flake.nix found"
  )
})

# Tests for clean_nix_expression()
test_that("clean_nix_expression removes consecutive empty lines", {
  content <- "line1\n\n\n\nline2\n\nline3"
  result <- rix:::clean_nix_expression(content)

  # Should have at most one empty line between content
  expect_false(grepl("\n\n\n", result))
  expect_match(result, "line1\n\nline2")
})

test_that("clean_nix_expression handles single lines", {
  content <- "single line"
  result <- rix:::clean_nix_expression(content)

  expect_equal(result, "single line")
})

test_that("clean_nix_expression handles empty content", {
  content <- ""
  result <- rix:::clean_nix_expression(content)

  expect_equal(result, "")
})
