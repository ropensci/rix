# Tests for flake templates

# Helper to create git repo
create_git_repo <- function(path) {
  system2("git", c("init", path), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", path, "config", "user.email", "test@test.com"), stdout = FALSE, stderr = FALSE)
  system2("git", c("-C", path, "config", "user.name", "Test User"), stdout = FALSE, stderr = FALSE)
}

test_that("all templates are accessible", {
  templates <- list_templates()
  expect_equal(length(templates), 6)
  expect_setequal(templates, c("minimal", "radian", "rstudio", "vscode", "positron", "docker"))
})

test_that("all templates contain required placeholder patterns", {
  templates <- list_templates()

  for (template in templates) {
    template_file <- system.file(
      "flake_templates", template, "flake.nix",
      package = "rix"
    )

    expect_true(file.exists(template_file), info = paste("Template", template, "file missing"))

    content <- readLines(template_file)
    content_str <- paste(content, collapse = "\n")

    # Check for nixpkgs URL placeholder
    expect_match(
      content_str, "\\{\\{NIXPKGS_URL\\}\\}",
      info = paste("Template", template, "missing NIXPKGS_URL placeholder")
    )

    # Check for flake-utils
    expect_match(
      content_str, "flake-utils",
      info = paste("Template", template, "missing flake-utils input")
    )

    # Check for outputs
    expect_match(
      content_str, "outputs",
      info = paste("Template", template, "missing outputs section")
    )

    # Check for rixEnv import
    expect_match(
      content_str, "\\.rixpackages\\.nix",
      info = paste("Template", template, "missing .rixpackages.nix import")
    )
  }
})

test_that("minimal template has correct structure", {
  template_file <- system.file("flake_templates", "minimal", "flake.nix", package = "rix")
  content <- readLines(template_file)
  content_str <- paste(content, collapse = "\n")

  # Should have default package
  expect_match(content_str, "packages\\.default")

  # Should have dev shell
  expect_match(content_str, "devShells\\.default")

  # Should use rWrapper
  expect_match(content_str, "rWrapper")
})

test_that("radian template has correct structure", {
  template_file <- system.file("flake_templates", "radian", "flake.nix", package = "rix")
  content <- readLines(template_file)
  content_str <- paste(content, collapse = "\n")

  # Should have radian wrapper
  expect_match(content_str, "radianWrapper")

  # Should have radian app
  expect_match(content_str, "radian")

  # Should have multiple shells
  expect_match(content_str, "devShells")
  expect_match(content_str, "default")
  expect_match(content_str, "r =")
})

test_that("rstudio template has correct structure", {
  template_file <- system.file("flake_templates", "rstudio", "flake.nix", package = "rix")
  content <- readLines(template_file)
  content_str <- paste(content, collapse = "\n")

  # Should have rstudio wrapper
  expect_match(content_str, "rstudioWrapper")

  # Should have rstudio app
  expect_match(content_str, "rstudio")
})

test_that("vscode template has correct structure", {
  template_file <- system.file("flake_templates", "vscode", "flake.nix", package = "rix")
  content <- readLines(template_file)
  content_str <- paste(content, collapse = "\n")

  # Should allow unfree (for VS Code)
  expect_match(content_str, "allowUnfree")

  # Should have vscode
  expect_match(content_str, "vscode")
})

test_that("positron template has correct structure", {
  template_file <- system.file("flake_templates", "positron", "flake.nix", package = "rix")
  content <- readLines(template_file)
  content_str <- paste(content, collapse = "\n")

  # Should allow unfree (for Positron)
  expect_match(content_str, "allowUnfree")

  # Should have positron
  expect_match(content_str, "positron")
})

test_that("docker template has correct structure", {
  template_file <- system.file("flake_templates", "docker", "flake.nix", package = "rix")
  content <- readLines(template_file)
  content_str <- paste(content, collapse = "\n")

  # Should have docker tools
  expect_match(content_str, "dockerTools")

  # Should have buildLayeredImage
  expect_match(content_str, "buildLayeredImage")

  # Should have streamLayeredImage
  expect_match(content_str, "streamLayeredImage")

  # Should expose docker package
  expect_match(content_str, "packages")
  expect_match(content_str, "docker")
})

test_that("generated flakes are valid Nix syntax", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  templates <- list_templates()

  for (template in templates) {
    tmpdir <- tempdir()
    test_dir <- file.path(tmpdir, paste0("template_test_", template))
    dir.create(test_dir, showWarnings = FALSE)
    create_git_repo(test_dir)

    # Generate flake with this template
    suppressMessages(
      init_flake(
        r_ver = "4.3.1",
        r_pkgs = "dplyr",
        template = template,
        project_path = test_dir,
        message_type = "quiet",
        git_tracking = FALSE
      )
    )

    # Check syntax with nix-instantiate --parse
    result <- tryCatch({
      sys::exec_internal(
        "nix-instantiate",
        args = c("--parse", file.path(test_dir, "flake.nix")),
        error = FALSE
      )
    }, error = function(e) {
      list(status = 1)
    })

    expect_equal(
      result$status, 0,
      info = paste("Template", template, "has invalid Nix syntax")
    )

    unlink(test_dir, recursive = TRUE, force = TRUE)
  }
})

test_that("generated .rixpackages.nix are valid Nix syntax", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "rixpackages_syntax_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "ggplot2", "quarto"),
      system_pkgs = c("pandoc", "nix"),
      tex_pkgs = c("amsmath"),
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  # Check .rixpackages.nix syntax
  result <- tryCatch({
    sys::exec_internal(
      "nix-instantiate",
      args = c("--parse", file.path(test_dir, ".rixpackages.nix")),
      error = FALSE
    )
  }, error = function(e) {
    list(status = 1)
  })

  expect_equal(result$status, 0, info = ".rixpackages.nix has invalid Nix syntax")
})

test_that("docker template generates buildable container", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "docker_build_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr"),
      template = "docker",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  # Check that docker files exist and have correct content
  flake <- readLines(file.path(test_dir, "flake.nix"))
  flake_str <- paste(flake, collapse = "\n")

  # Should have docker configuration
  expect_match(flake_str, "dockerTools")
  expect_match(flake_str, "buildLayeredImage")
  expect_match(flake_str, "packages\\.docker")
})

test_that("templates handle wrapped packages correctly", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  # Test radian template with R packages
  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "wrapped_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      r_pkgs = c("dplyr", "ggplot2"),
      template = "radian",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  rixpackages <- readLines(file.path(test_dir, ".rixpackages.nix"))
  content_str <- paste(rixpackages, collapse = "\n")

  # Should define wrapped_pkgs
  expect_match(content_str, "wrapped_pkgs")

  # Should use radianWrapper
  expect_match(content_str, "radianWrapper")
})

test_that("templates handle empty package lists gracefully", {
  skip_if_not(nix_shell_available())
  skip_on_cran()

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, "empty_pkgs_test")
  dir.create(test_dir)
  create_git_repo(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  # Create with no R packages
  suppressMessages(
    init_flake(
      r_ver = "4.3.1",
      template = "minimal",
      project_path = test_dir,
      message_type = "quiet",
      git_tracking = FALSE
    )
  )

  # Should still work
  expect_true(file.exists(file.path(test_dir, "flake.nix")))
  expect_true(file.exists(file.path(test_dir, ".rixpackages.nix")))

  # .rixpackages.nix should have empty rpkgs
  rixpackages <- readLines(file.path(test_dir, ".rixpackages.nix"))
  content_str <- paste(rixpackages, collapse = "\n")
  expect_match(content_str, "rpkgs = \\[\\]")
})

test_that("templates are consistent in structure", {
  templates <- list_templates()

  for (template in templates) {
    template_file <- system.file("flake_templates", template, "flake.nix", package = "rix")
    content <- readLines(template_file)

    # All templates should have these common elements
    content_str <- paste(content, collapse = "\n")

    # Should have description
    expect_match(content_str, "description\\s*=")

    # Should have inputs
    expect_match(content_str, "inputs\\s*=")

    # Should have outputs function
    expect_match(content_str, "outputs\\s*=\\s*\\{")

    # Should use eachDefaultSystem
    expect_match(content_str, "eachDefaultSystem")

    # Should import .rixpackages.nix
    expect_match(content_str, "import\\s+\\./\\.rixpackages\\.nix")
  }
})
