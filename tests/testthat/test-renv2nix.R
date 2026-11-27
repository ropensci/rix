testthat::test_that("`renv2nix()` skips packages without a RemoteHost", {
  tmpf <- tempfile()
  on.exit(unlink(tmpf), add = TRUE)
  renv_lock_local <- list(
    R = list(Version = "4.4.1"),
    Packages = list(
      MASS = list(
        Package = "MASS",
        Version = "7.3-56",
        Source = "Repository",
        Repository = "CRAN",
        Hash = "af0e1955cb80bb36b7988cc657db261e",
        Requirements = list()
      ),
      localpkg = list(
        Package = "localpkg",
        Version = "0.1.0",
        Source = "Local",
        RemoteType = "local",
        RemoteUrl = "~/localpkg"
      )
    )
  )
  jsonlite::write_json(renv_lock_local, tmpf, auto_unbox = TRUE)

  testthat::expect_warning(
    {
      call <- renv2nix(
        tmpf,
        project_path = tempdir(),
        return_rix_call = TRUE
      )
    },
    "localpkg has the unsupported remote host \\(none\\)"
  )
  testthat::expect_equal(call$r_pkgs, "MASS")
  testthat::expect_null(call$git_pkgs)
})
