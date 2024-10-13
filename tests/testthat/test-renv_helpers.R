testthat::test_that("Testing `read_renv_lock()`", {
    testthat::expect_error(read_renv_lock("nosuchfile"), "nosuchfile does not exist")
    tmpf <- tempfile()
    cat("not json", file = tmpf)
    testthat::expect_error(read_renv_lock(tmpf), "Error reading renv\\.lock file")
    unlink(tmpf)
})

testthat::test_that("Testing `renv_remote_pkg()`", {
    synthetic_renv_lock_example <- list(
        githubpkg = list(
            Package = "githubpkg",
            RemoteType = "github",
            RemoteUser = "user",
            RemoteRepo = "repo",
            RemoteSha = "yki8snny7wgpjolz5cq0bwxjshxdd0xv0mcyygoz",
            RemoteHost = "api.github.com"
        ),
        gitlabpkg = list(
            Package = "gitlabpkg",
            RemoteType = "gitlab",
            RemoteUser = "user",
            RemoteRepo = "repo",
            RemoteSha = "45p9megdp0i5230rtw1lisy6rquc466zb9yxn7eh",
            RemoteHost = "gitlab.com"
        )
    )

    expected_git_pkg <- list(
        githubpkg = list(
            package_name = "githubpkg",
            repo_url = "https://github.com/user/repo",
            commit =  "yki8snny7wgpjolz5cq0bwxjshxdd0xv0mcyygoz"
        ),
        gitlabpkg = list(
            package_name = "gitlabpkg",
            repo_url = "https://gitlab.com/user/repo",
            commit =  "45p9megdp0i5230rtw1lisy6rquc466zb9yxn7eh"
        )
    )

    testthat::expect_equal(renv_remote_pkg(synthetic_renv_lock_example$githubpkg), expected_git_pkg$githubpkg)
    testthat::expect_equal(renv_remote_pkg(synthetic_renv_lock_example$gitlabpkg), expected_git_pkg$gitlabpkg)
})

