testthat::test_that("testing renv_helpers", {
  testthat::expect_true(exists("renv2nix"))
  # following as nested test pattern based on:
  # https://rpahl.github.io/r-some-blog/posts/2024-10-07-nested-unit-tests-with-testthat/

  # testthat::skip("skipping remaining renv_helpers tests...") # uncomment to skip subsequent tests

  testthat::test_that("Testing `read_renv_lock()`", {
    testthat::expect_error(read_renv_lock("nosuchfile"), "nosuchfile does not exist")
    tmpf <- tempfile()
    cat("not json", file = tmpf)
    testthat::expect_error(read_renv_lock(tmpf), "Error reading renv\\.lock file")
    unlink(tmpf)
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
  })

  testthat::test_that("Testing `renv2nix()`", {
    tmpf <- tempfile()
    jsonlite::write_json(synthetic_renv_lock_example, tmpf, auto_unbox = TRUE)
    test_call <- call(
      "rix", r_ver = "4.4.1", r_pkgs = c("MASS", "R6"), git_pkgs = expected_git_pkg
    )
    warns <- testthat::capture_warnings({
      call <- renv2nix(tmpf, return_rix_call = TRUE)
    })
    testthat::expect_equal(call, test_call)
    testthat::expect_match(warns, "has the unsupported remote type")
    unlink(tmpf)
  })

  testthat::test_that("Testing `renv_lock_r_ver()`", {
    tmpf <- tempfile()
    jsonlite::write_json(list(R = list(Version = "4.4.1")), tmpf, auto_unbox = TRUE)
    testthat::expect_equal(renv_lock_r_ver(renv_lock_path = tmpf), "4.4.1")
    unlink(tmpf)
  })

})

