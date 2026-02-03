# Unit tests for flake internal functions

# Tests for generate_packages_data()
testthat::test_that("generate_packages_data returns correct structure", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr", "ggplot2"),
    system_pkgs = c("nix", "pandoc"),
    ide = "none"
  )

  testthat::expect_type(pkg_data, "list")
  testthat::expect_named(pkg_data, c("nix_repo", "r_ver", "date", "ide",
                           "cran_pkgs", "git_pkgs", "local_r_pkgs",
                           "tex_pkgs", "py_conf", "jl_conf", "system_pkgs",
                           "flags", "git_archive_defs", "system_pkgs_string",
                           "wrapper_attrib"))

  testthat::expect_equal(pkg_data$flags$rpkgs, "rpkgs")
  testthat::expect_equal(pkg_data$ide, "none")
  testthat::expect_type(pkg_data$nix_repo, "list")
  testthat::expect_type(pkg_data$cran_pkgs, "list")
})

testthat::test_that("generate_packages_data handles edge versions", {
  testthat::skip_if_not(nix_shell_available())

  # Test bleeding-edge (should use rstats-on-nix fork)
  pkg_data <- rix:::generate_packages_data(r_ver = "bleeding-edge")
  testthat::expect_true(grepl("rstats-on-nix", pkg_data$nix_repo$url))

  # Test frozen-edge (should use rstats-on-nix fork)
  pkg_data <- rix:::generate_packages_data(r_ver = "frozen-edge")
  testthat::expect_true(grepl("rstats-on-nix", pkg_data$nix_repo$url))

  # Test r-devel (should use rstats-on-nix fork)
  pkg_data <- rix:::generate_packages_data(r_ver = "r-devel")
  testthat::expect_true(grepl("rstats-on-nix", pkg_data$nix_repo$url))

  # Test latest-upstream (should use NixOS upstream)
  pkg_data <- rix:::generate_packages_data(r_ver = "latest-upstream")
  testthat::expect_true(grepl("NixOS/nixpkgs", pkg_data$nix_repo$url))
  testthat::expect_false(grepl("rstats-on-nix", pkg_data$nix_repo$url))
})

testthat::test_that("generate_packages_data adds languageserver for code IDE", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    ide = "code"
  )

  # Should automatically add languageserver
  testthat::expect_true(any(grepl("languageserver", pkg_data$cran_pkgs$rPackages)))
})

testthat::test_that("generate_packages_data adds languageserver for codium IDE", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    ide = "codium"
  )

  testthat::expect_true(any(grepl("languageserver", pkg_data$cran_pkgs$rPackages)))
})

testthat::test_that("generate_packages_data handles archive packages", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr", "ggplot2@3.4.0"),
    ide = "none"
  )

  # Should have both current and archive packages
  testthat::expect_true(!is.null(pkg_data$cran_pkgs$rPackages))
  testthat::expect_true(!is.null(pkg_data$cran_pkgs$archive_pkgs))
  testthat::expect_match(pkg_data$flags$git_archive, "ggplot2")
})

testthat::test_that("generate_packages_data handles git packages", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    git_pkgs = list(
      list(
        package_name = "housing",
        repo_url = "https://github.com/rap4all/housing/",
        commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
      )
    ),
    ide = "none"
  )

  testthat::expect_match(pkg_data$flags$git_archive, "housing")
})

testthat::test_that("generate_packages_data handles empty inputs", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1"
  )

  testthat::expect_equal(pkg_data$flags$rpkgs, "")
  testthat::expect_equal(pkg_data$flags$tex, "")
  testthat::expect_equal(pkg_data$flags$git_archive, "")
  testthat::expect_equal(pkg_data$flags$local, "")
  testthat::expect_equal(pkg_data$flags$py, "")
  testthat::expect_equal(pkg_data$flags$jl, "")
  testthat::expect_equal(pkg_data$flags$wrapper, "")
})

testthat::test_that("generate_packages_data handles date parameter", {
  testthat::skip_if_not(nix_shell_available())

  pkg_data <- rix:::generate_packages_data(
    date = "2025-01-15",
    r_pkgs = c("dplyr")
  )

  testthat::expect_equal(pkg_data$date, "2025-01-15")
  expect_null(pkg_data$r_ver)
  testthat::expect_true(grepl("rstats-on-nix", pkg_data$nix_repo$url))
})

testthat::test_that("generate_packages_data handles wrapper flags correctly", {
  # radian
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    ide = "radian"
  )
  testthat::expect_equal(pkg_data$flags$wrapper, "wrapped_pkgs")

  # rstudio
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    ide = "rstudio"
  )
  testthat::expect_equal(pkg_data$flags$wrapper, "wrapped_pkgs")

  # rserver
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    ide = "rserver"
  )
  testthat::expect_equal(pkg_data$flags$wrapper, "wrapped_pkgs")

  # none (no wrapper)
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    ide = "none"
  )
  testthat::expect_equal(pkg_data$flags$wrapper, "")
})

# Tests for generate_packages_nix()
testthat::test_that("generate_packages_nix creates importable Nix expression", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr", "ggplot2")
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  # Should start with "pkgs:"
  testthat::expect_match(nix_expr, "^pkgs:", fixed = FALSE)

  # Should contain expected sections
  testthat::expect_match(nix_expr, "rpkgs = ")
  testthat::expect_match(nix_expr, "system_packages = ")
  testthat::expect_match(nix_expr, "shell = pkgs.mkShell")
})

testthat::test_that("generate_packages_nix handles empty packages", {
  pkg_data <- rix:::generate_packages_data(r_ver = "4.3.1")

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  testthat::expect_match(nix_expr, "rpkgs = \\[\\];")
  testthat::expect_match(nix_expr, "system_packages = ")
})

testthat::test_that("generate_packages_nix includes locale variables", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = "dplyr"
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  testthat::expect_match(nix_expr, "LANG = ")
  testthat::expect_match(nix_expr, "LC_ALL = ")
})

testthat::test_that("generate_packages_nix handles LaTeX packages", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = "dplyr",
    tex_pkgs = c("amsmath", "booktabs")
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  testthat::expect_match(nix_expr, "tex = ")
  testthat::expect_match(nix_expr, "amsmath")
  testthat::expect_match(nix_expr, "booktabs")
  testthat::expect_match(nix_expr, "scheme-small")
})

testthat::test_that("generate_packages_nix handles Python configuration", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = "reticulate",
    py_conf = list(
      py_version = "3.12",
      py_pkgs = c("numpy", "pandas")
    )
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  testthat::expect_match(nix_expr, "pyconf = ")
  testthat::expect_match(nix_expr, "python312Packages")
  testthat::expect_match(nix_expr, "numpy")
  testthat::expect_match(nix_expr, "pandas")
})

testthat::test_that("generate_packages_nix handles Julia configuration", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = "dplyr",
    jl_conf = list(
      jl_version = "1.10",
      jl_pkgs = c("DataFrames", "Plots")
    )
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  testthat::expect_match(nix_expr, "jlconf = ")
  testthat::expect_match(nix_expr, "julia_110")
  testthat::expect_match(nix_expr, "DataFrames")
})

testthat::test_that("generate_packages_nix handles shell hook", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = "dplyr"
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data, shell_hook = "echo 'Hello'")

  testthat::expect_match(nix_expr, "echo 'Hello'")
})

testthat::test_that("generate_packages_nix includes git archive packages in expression", {
  pkg_data <- rix:::generate_packages_data(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr"),
    git_pkgs = list(
      list(
        package_name = "housing",
        repo_url = "https://github.com/rap4all/housing/",
        commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
      )
    )
  )

  nix_expr <- rix:::generate_packages_nix(pkg_data)

  testthat::expect_match(nix_expr, "git_archive_pkgs")
})

# Tests for backward compatibility
testthat::test_that("refactored rix still produces same output", {
  testthat::skip_if_not(nix_shell_available())

  tmpdir <- tempdir()
  test_dir <- file.path(tmpdir, paste0(sample(letters, 10), collapse = ""))
  dir.create(test_dir)
  test_dir <- normalizePath(test_dir)

  on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

  rix(
    r_ver = "4.3.1",
    r_pkgs = c("dplyr", "ggplot2"),
    project_path = test_dir,
    overwrite = TRUE,
    message_type = "quiet"
  )

  content <- readLines(file.path(test_dir, "default.nix"))
  content_str <- paste(content, collapse = "\n")

  # Check expected content is present
  testthat::expect_match(content_str, "dplyr")
  testthat::expect_match(content_str, "ggplot2")
  testthat::expect_match(content_str, "pkgs = import")
  testthat::expect_match(content_str, "mkShell")
})
