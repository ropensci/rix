testthat::test_that("testing renv_helpers", {
  testthat::expect_true(exists("renv2nix"))
  # following as nested test pattern based on:
  # https://rpahl.github.io/r-some-blog/posts/2024-10-07-nested-unit-tests-with-testthat/

  # testthat::skip("skipping remaining renv_helpers tests...") # uncomment to skip subsequent tests

  renv_sample_dir <- paste0(testthat::test_path(), "/testdata/renv-samples")
  renv_sample_files <- list.files(renv_sample_dir, pattern = "*.lock", full.names = TRUE)

  testthat::test_that("Testing `read_renv_lock()`", {
    testthat::expect_error(read_renv_lock("nosuchfile"), "nosuchfile does not exist")
    tmpf <- tempfile()
    cat("not json", file = tmpf)
    testthat::expect_error(read_renv_lock(tmpf), "Error reading renv\\.lock file")
    unlink(tmpf)
    for (file in renv_sample_files) {
      testthat::expect_type(read_renv_lock(file), "list")
    }
  })

  synthetic_renv_lock_example <- list(
    R = list(Version = "4.4.1"),
    Packages = list(
      MASS = list(
        Package = "MASS",
        Version = "7.3-56",
        Source = "Repository",
        Repository = "CRAN",
        Hash = "af0e1955cb80bb36b7988cc657db261e",
        Requirements = c()
      ),
      R6 = list(
        Package = "R6",
        Version = "2.5.1",
        Source = "Repository",
        Repository = "RSPM",
        Hash = "470851b6d5d0ac559e9d01bb352b4021",
        Requirements = c()
      ),
      githubpkg = list(
        Package = "githubpkg",
        Source = "GitHub",
        RemoteType = "github",
        RemoteUser = "user",
        RemoteRepo = "repo",
        RemoteSha = "yki8snny7wgpjolz5cq0bwxjshxdd0xv0mcyygoz",
        RemoteHost = "api.github.com"
      ),
      gitlabpkg = list(
        Package = "gitlabpkg",
        Source = "GitLab",
        RemoteType = "gitlab",
        RemoteUser = "user",
        RemoteRepo = "repo",
        RemoteSha = "45p9megdp0i5230rtw1lisy6rquc466zb9yxn7eh",
        RemoteHost = "gitlab.com"
      ),
      unsupported = list(
        Package = "unsupported",
        Source = "unsupported",
        RemoteType = "unsupported",
        RemoteUser = "user",
        RemoteRepo = "repo",
        RemoteSha = "i52gyxn30rtw1l45p9me7ehdp0rquc466isy6zb9",
        RemoteHost = "unsupported.com"
      )
    )
  )

  expected_git_pkg <- list(
    githubpkg = list(
      package_name = "githubpkg",
      repo_url = "https://github.com/user/repo",
      commit = "yki8snny7wgpjolz5cq0bwxjshxdd0xv0mcyygoz"
    ),
    gitlabpkg = list(
      package_name = "gitlabpkg",
      repo_url = "https://gitlab.com/user/repo",
      commit = "45p9megdp0i5230rtw1lisy6rquc466zb9yxn7eh"
    )
  )

  testthat::test_that("Testing `renv_remote_pkg()`", {
    testthat::expect_equal(
      renv_remote_pkgs(synthetic_renv_lock_example$Packages[c("githubpkg", "gitlabpkg")]),
      expected_git_pkg
    )
    testthat::expect_error(
      renv_remote_pkgs(synthetic_renv_lock_example$Packages),
      "Not a package installed from a remote outside of the main package repositories"
    )
    testthat::expect_error(
      renv_remote_pkgs(synthetic_renv_lock_example$Packages[
        c("githubpkg", "gitlabpkg", "unsupported")
      ], host = "unsupported"),
      "Unsupported remote host:"
    )
    testthat::expect_error(
      renv_remote_pkgs(synthetic_renv_lock_example$Packages[
        c("githubpkg", "gitlabpkg", "unsupported")
      ]),
      "has unsupported remote host"
    )
    testthat::expect_error(
      renv_remote_pkgs(synthetic_renv_lock_example$Packages[
        c("githubpkg", "gitlabpkg", "unsupported")
      ], host = "api.github.com"),
      "does not match the provided host"
    )
  })

  testthat::test_that("Testing `renv2nix()`", {
    tmpf <- tempfile()
    path_env_nix <- tempdir()
    jsonlite::write_json(synthetic_renv_lock_example, tmpf, auto_unbox = TRUE)
    expect_error(renv2nix(tmpf, method = "accurate"), "not yet implemented")
    test_call <- call(
      "rix",
      r_ver = "4.4.1",
      r_pkgs = c("MASS", "R6"),
      git_pkgs = expected_git_pkg,
      project_path = path_env_nix,
      message_type = "quiet"
    )

    testthat::expect_warning(
      {
        call <- renv2nix(
          tmpf,
          project_path = path_env_nix,
          return_rix_call = TRUE,
          message_type = "quiet"
        )
      },
      "has the unsupported remote host"
    )
    testthat::expect_equal(call, test_call)

    warns <- testthat::expect_warning(
      {
        call <- renv2nix(
          tmpf,
          project_path = path_env_nix,
          return_rix_call = TRUE,
          message_type = "quiet",
          ide = "rstudio"
        )
      },
      "has the unsupported remote host"
    )
    test_call$ide <- "rstudio"
    testthat::expect_equal(call, test_call)

    on.exit(unlink(tmpf), add = TRUE)
    on.exit(unlink(path_env_nix), add = TRUE)
  })

  testthat::test_that("Testing `renv_lock_r_ver()`", {
    tmpf <- tempfile()
    jsonlite::write_json(list(R = list(Version = "4.4.1")), tmpf, auto_unbox = TRUE)
    renv_lock <- read_renv_lock(tmpf)
    testthat::expect_equal(renv_lock_r_ver(renv_lock), "4.4.1")
    unlink(tmpf)
  })

  testthat::test_that("Testing `renv2nix()` on actual renv.lock files", {
    path_env_nix <- tempdir()

    save_renv2nix_test <- function(renv_lock_path, path_env_nix, output_nix_file, ...) {
      renv2nix(
        renv_lock_path = renv_lock_path,
        project_path = path_env_nix,
        message_type = "quiet",
        overwrite = TRUE,
        ...
      )

      file.copy(
        from = paste0(path_env_nix, "/default.nix"),
        to = paste0(path_env_nix, output_nix_file)
      )

      paste0(path_env_nix, output_nix_file)
    }

    testthat::expect_snapshot_file(
      # Suppress the warning about creating an expression with an old version of R
      path = suppressWarnings(save_renv2nix_test(
        "testdata/renv-samples/renv_v0-14-0.lock",
        path_env_nix,
        "/default_v0-14-0.nix"
      )),
      name = "default_v0-14-0.nix"
    )

    testthat::expect_snapshot_file(
      path = suppressWarnings(save_renv2nix_test(
        "testdata/renv-samples/renv_v0-15-5.lock",
        path_env_nix,
        "/default_v0-15-5.nix"
      )),
      name = "default_v0-15-5.nix"
    )

    testthat::expect_snapshot_file(
      path = suppressWarnings(save_renv2nix_test(
        "testdata/renv-samples/renv_v0-17-3.lock",
        path_env_nix,
        "/default_v0-17-3.nix"
      )),
      name = "default_v0-17-3.nix"
    )

    testthat::expect_snapshot_file(
      # suprressWarning about incomplete final line
      path = suppressWarnings(save_renv2nix_test(
        "testdata/renv-samples/renv_v1-0-7.lock",
        path_env_nix,
        "/default_v1-0-7.nix",
        override_r_ver = "4.3.3",
      )),
      name = "default_v1-0-7.nix"
    )

    # This should not get datathin twice in the generated
    # default.nix
    testthat::expect_snapshot_file(
      # suprressWarning about incomplete final line
      path = suppressWarnings(save_renv2nix_test(
        "testdata/renv-samples/renv_datathin.lock",
        path_env_nix,
        "/default_datathin.nix",
        override_r_ver = "2024-12-14",
      )),
      name = "default_datathin.nix"
    )

    on.exit(unlink(path_env_nix))
  })
})
