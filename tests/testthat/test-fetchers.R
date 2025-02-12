testthat::test_that("Test fetchgit works", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "housing",
        repo_url = "https://github.com/rap4all/housing/",
        commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
      )
    ),
    "\n    housing = (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchgit fails gracefully", {
  testthat::skip_on_cran()
  testthat::expect_error(
    fetchgit(
      list(
        package_name = "housing",
        repo_url = "https://github.com/rap4all/housing666/",
        commit = "this_commit_is_wrong"
      )
    ), "Are these correct?"
  )
})

testthat::test_that("Test fetchgit works with gitlab packages", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "housing",
        repo_url = "https://gitlab.com/b-rodrigues/housing/",
        commit = "9442aa63d352d3c900f1c6f5a06f7930cdf702c4"
      )
    ),
    "\n    housing = (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://gitlab.com/b-rodrigues/housing/\";\n        rev = \"9442aa63d352d3c900f1c6f5a06f7930cdf702c4\";\n        sha256 = \"sha256-3V9XbNbq/YpbgnzkEu3XH7QKSDY8yNNd1vpOeR9ER0w=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchgit works with packages with empty imports", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "helloworld",
        repo_url = "https://github.com/jrosell/helloworld/",
        commit = "48ceefdfb4858743454ede71d19999c2e6b38ed2"
      )
    ),
    "\n    helloworld = (pkgs.rPackages.buildRPackage {\n      name = \"helloworld\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/jrosell/helloworld/\";\n        rev = \"48ceefdfb4858743454ede71d19999c2e6b38ed2\";\n        sha256 = \"sha256-vaO7ItKMO6PfvNDhWNDdw5ST/K081HplyW3RoQhNsEs=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) ;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchzip works", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchzip("AER@1.2-8"),
    "\n    AER = (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchzip fails gracefully", {
  testthat::skip_on_cran()
  testthat::expect_error(
    fetchzip("AER@999999"),
    "Are these correct?"
  )
})

testthat::test_that("Test fetchgits", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgits(
      list(
        list(
          package_name = "housing",
          repo_url = "https://github.com/rap4all/housing/",
          commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
        ),
        list(
          package_name = "fusen",
          repo_url = "https://github.com/ThinkR-open/fusen",
          commit = "d617172447d2947efb20ad6a4463742b8a5d79dc"
        )
      )
    ),
    "\n    fusen = (pkgs.rPackages.buildRPackage {\n      name = \"fusen\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/ThinkR-open/fusen\";\n        rev = \"d617172447d2947efb20ad6a4463742b8a5d79dc\";\n        sha256 = \"sha256-TOHA1ymLUSgZMYIA1a2yvuv0799svaDOl3zOhNRxcmw=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          attachment\n          cli\n          desc\n          devtools\n          glue\n          here\n          magrittr\n          parsermd\n          roxygen2\n          stringi\n          tibble\n          tidyr\n          usethis\n          yaml;\n      };\n    });\n\n\n    housing = (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchgits works when PR is provided in a remote package", {
  # The PR is not provided in the commit, but in the DESCRIPTION file
  # see https://github.com/mlr-org/mlr3proba/commit/c5bec7b9b0b73d3611e61882e7556404a6d9fb2e
  # This should not fail, however it will not use the PR
  testthat::skip_on_cran()
  result <- fetchgits(
    list(
      list(
        package_name = "mlr3extralearners",
        repo_url = "https://github.com/mlr-org/mlr3proba/",
        commit = "c5bec7b9b0b73d3611e61882e7556404a6d9fb2e"
      )
    )
  )
  
  # Test that output is a character string and contains essential elements
  testthat::expect_type(result, "character")
  testthat::expect_true(grepl("mlr3extralearners = \\(pkgs.rPackages.buildRPackage", result))
})

testthat::test_that("Test fetchgits works when tag is provided in a remote package", {
  testthat::skip_on_cran()
  pkg_list <- list(
    list(
      package_name = "rixTest",
      repo_url = "https://github.com/mihem/rixTest",
      commit = "25da90697895b006934a70bbd003aab5c5206c8b"
    )
  )
  expected_output <- paste0(
    "\n    rix = (pkgs.rPackages.buildRPackage {\n",
    "      name = \"rix\";\n",
    "      src = pkgs.fetchgit {\n",
    "        url = \"https://github.com/ropensci/rix\";\n",
    "        rev = \"v0.8.0\";\n",
    "        sha256 = \"sha256-E4WYQeQRPuIKPZY7TEudcSW9AxNc0KDKs7+QV2U7sjI=\";\n",
    "      };\n",
    "      propagatedBuildInputs = builtins.attrValues {\n",
    "        inherit (pkgs.rPackages) \n",
    "          codetools\n",
    "          curl\n",
    "          jsonlite\n",
    "          sys;\n",
    "      };\n",
    "    });\n\n",
    "    rixTest = (pkgs.rPackages.buildRPackage {\n",
    "      name = \"rixTest\";\n",
    "      src = pkgs.fetchgit {\n",
    "        url = \"https://github.com/mihem/rixTest\";\n",
    "        rev = \"25da90697895b006934a70bbd003aab5c5206c8b\";\n",
    "        sha256 = \"sha256-+EP74d5nWjGbniQ0iEzDyKUky94L8FpvkyxFNfokJKM=\";\n",
    "      };\n",
    "      propagatedBuildInputs = builtins.attrValues {\n",
    "        inherit (pkgs.rPackages) ;\n",
    "      } ++ [ rix ];\n",
    "    });\n"
  )
  testthat::expect_equal(
    fetchgits(pkg_list),
    expected_output
  )
})

testthat::test_that("Test fetchzips works", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchzips(
      c("dplyr@0.8.0", "AER@1.2-8")
    ),
    "\n    AER = (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    });\n\n\n    dplyr = (pkgs.rPackages.buildRPackage {\n      name = \"dplyr\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.0.tar.gz\";\n       sha256 = \"sha256-f30raalLd9KoZKZSxeTN71PG6BczXRIiP6g7EZeH09U=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          glue\n          magrittr\n          pkgconfig\n          R6\n          Rcpp\n          rlang\n          tibble\n          tidyselect\n          BH\n          plogr;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchpkgs works", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchpkgs(
      git_pkgs = list(
        list(
          package_name = "housing",
          repo_url = "https://github.com/rap4all/housing/",
          commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
        ),
        list(
          package_name = "fusen",
          repo_url = "https://github.com/ThinkR-open/fusen",
          commit = "d617172447d2947efb20ad6a4463742b8a5d79dc"
        )
      ),
      archive_pkgs = c("AER@1.2-8", "dplyr@0.8.0")
    ),
    "\n    fusen = (pkgs.rPackages.buildRPackage {\n      name = \"fusen\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/ThinkR-open/fusen\";\n        rev = \"d617172447d2947efb20ad6a4463742b8a5d79dc\";\n        sha256 = \"sha256-TOHA1ymLUSgZMYIA1a2yvuv0799svaDOl3zOhNRxcmw=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          attachment\n          cli\n          desc\n          devtools\n          glue\n          here\n          magrittr\n          parsermd\n          roxygen2\n          stringi\n          tibble\n          tidyr\n          usethis\n          yaml;\n      };\n    });\n\n\n    housing = (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    });\n \n    AER = (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    });\n\n\n    dplyr = (pkgs.rPackages.buildRPackage {\n      name = \"dplyr\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.0.tar.gz\";\n       sha256 = \"sha256-f30raalLd9KoZKZSxeTN71PG6BczXRIiP6g7EZeH09U=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          glue\n          magrittr\n          pkgconfig\n          R6\n          Rcpp\n          rlang\n          tibble\n          tidyselect\n          BH\n          plogr;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchgit gets a package with several remote deps and commits", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    suppressMessages(
      fetchgit(
        list(
          package_name = "lookup",
          repo_url = "https://github.com/b-rodrigues/lookup/",
          commit = "ee5505c817b19b59d37236ed35a81a65aa376124"
        )
      )
    ),
    "\n    httr2 = (pkgs.rPackages.buildRPackage {\n      name = \"httr2\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/b-rodrigues/httr2\";\n        rev = \"15243331d3f6192e1a2c210b2959d6fec63402c4\";\n        sha256 = \"sha256-ny4J2WqUL4LPLWRKS8rgVqwvgMOQ2Rm/lbBWtF+99PE=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          cli\n          curl\n          glue\n          lifecycle\n          magrittr\n          openssl\n          R6\n          rappdirs\n          rlang\n          vctrs\n          withr;\n      };\n    });\n\n    gh = (pkgs.rPackages.buildRPackage {\n      name = \"gh\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/b-rodrigues/gh\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-POXEMZv8kqHokAxK8LoWkS0qYrcIcVdQi5xyGD992KU=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          cli\n          gitcreds\n          glue\n          ini\n          jsonlite\n          lifecycle\n          rlang;\n      } ++ [ httr2 ];\n    });\n\n\n    highlite = (pkgs.rPackages.buildRPackage {\n      name = \"highlite\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/jimhester/highlite\";\n        rev = \"767b122ef47a60a01e1707e4093cf3635a99c86b\";\n        sha256 = \"sha256-lkWMlAi75MYxiBUYnLwxLK9ApXkWanA4Mt7g4qtLpxM=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Rcpp\n          BH;\n      };\n    });\n\n\n    memoise = (pkgs.rPackages.buildRPackage {\n      name = \"memoise\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/b-rodrigues/memoise\";\n        rev = \"74d62c8\";\n        sha256 = \"sha256-fsdop66VglkOIYrJ0LKZKikIZmzQ2gqEATLy9tTJ/B8=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          digest;\n      };\n    });\n\n    lookup = (pkgs.rPackages.buildRPackage {\n      name = \"lookup\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/b-rodrigues/lookup/\";\n        rev = \"ee5505c817b19b59d37236ed35a81a65aa376124\";\n        sha256 = \"sha256-jiSBuC1vzJbN6OckgVX0E+XuMCeZS5LKsldIVL7DNgo=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Rcpp\n          codetools\n          crayon\n          rex\n          jsonlite\n          rstudioapi\n          withr\n          httr;\n      } ++ [ highlite gh memoise ];\n    });\n"
  )
})

testthat::test_that("Test fetchgit gets a package that is not listed in DESCRIPTION, only in NAMESPACE", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "seurat-data",
        repo_url = "https://github.com/satijalab/seurat-data",
        commit = "4dc08e022f51c324bc7bf785b1b5771d2742701d"
      )
    ),
    "\n    seurat-data = (pkgs.rPackages.buildRPackage {\n      name = \"seurat-data\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/satijalab/seurat-data\";\n        rev = \"4dc08e022f51c324bc7bf785b1b5771d2742701d\";\n        sha256 = \"sha256-dyv8ttrVaGwd5tPle2+wDHMa8lVjozZnVMsKArEMTPE=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          cli\n          crayon\n          rappdirs\n          SeuratObject\n          Matrix\n          Seurat;\n      };\n    });\n"
  )
})

testthat::test_that("Test fetchgit works even if there are not `importfrom` in NAMESPACE", {
  testthat::skip_on_cran()
  testthat::expect_no_error(
    fetchgit(
      list(
        package_name = "CSFAtlasTools",
        repo_url = "https://github.com/mihem/CSFAtlasTools",
        commit = "ac4a34d39812e8b8fa5746b63df4cf321a13b7a7"
      )
    )
  )
})

testthat::test_that("get_commit_date works with valid repo and commit", {
  testthat::skip_on_cran()
  date <- get_commit_date(
    "ropensci/rix",
    "cd7a53f7c670bd5106a94b48573d5f824174170f"
  )
  testthat::expect_match(date, "2025-01-10T07:05:02Z")
})

testthat::test_that("get_commit_date tells you when it cannot get commit date and then uses the current date", {
  testthat::skip_on_cran()
  testthat::expect_message(
    date <- get_commit_date(
      "nonexistent/repo",
      "cd7a53f7c670bd5106a94b48573d5f824174170f"
    ),
    "Failed to get commit date from <<< nonexistent/repo >>> : API request failed with status code: 404"
  )
  testthat::expect_equal(date, Sys.Date())
})

testthat::test_that("get_commit_date fails with invalid commit", {
  testthat::skip_on_cran()
  testthat::expect_message(
    date <- get_commit_date(
      "ropensci/rix",
      "ad7a53f7c670bd5106a94b48573d5f824174170f"
    ),
    "Failed to get commit date from <<< ropensci/rix >>>"
  )
  testthat::expect_equal(date, Sys.Date())
})

testthat::test_that("get_commit_date tells you when no GitHub token is found", {
  testthat::skip_on_cran()
  # Temporarily unset GITHUB_PAT if it exists
  old_pat <- Sys.getenv("GITHUB_PAT")
  Sys.unsetenv("GITHUB_PAT")
  on.exit(Sys.setenv(GITHUB_PAT = old_pat))

  testthat::expect_message(
    get_commit_date(
      "ropensci/rix",
      "cd7a53f7c670bd5106a94b48573d5f824174170f"
    ),
    "When fetching the commit date from GitHub from <<< ropensci/rix >>>, no GitHub Personal Access Token found"
  )
})

testthat::test_that("Test download_all_commits works with valid repo", {
  testthat::skip_on_cran()
  commits <- download_all_commits("ropensci/rix", "2025-01-10T07:05:02Z")

  # Check structure
  testthat::expect_true(is.data.frame(commits))
  testthat::expect_named(commits, c("sha", "date"))

  # Check content
  testthat::expect_true(nrow(commits) > 0)
  testthat::expect_true(all(!is.na(commits$sha)))
  testthat::expect_true(all(!is.na(commits$date)))

  # Verify date format
  testthat::expect_true(all(class(commits$date) %in% c("POSIXct", "POSIXt")))
})

testthat::test_that("Test download_all_commits fails with invalid repo", {
  testthat::skip_on_cran()
  testthat::expect_error(
    download_all_commits("nonexistent/repo"),
    "Failed to download commit data"
  )
})

testthat::test_that("resolve_package_commit works with different input cases", {
  testthat::skip_on_cran()

  # Test case 1: When ref is provided
  pkg_with_ref <- c("schex", "031320d")
  remotes <- c("welch-lab/liger", "SaskiaFreytag/schex@031320d")
  target_date <- "2024-04-04T14:16:11Z"
  testthat::expect_equal(
    resolve_package_commit(remote_pkg_name_and_ref = pkg_with_ref, date = target_date, remotes = remotes),
    "031320d"
  )

  # Test case 2: When no ref is provided find the closest commit
  pkg_without_ref <- c("liger")
  remotes <- c("welch-lab/liger", "hms-dbmi/conos")
  target_date <- "2024-04-04T14:16:11Z"
  testthat::expect_equal(
    resolve_package_commit(remote_pkg_name_and_ref = pkg_without_ref, date = target_date, remotes = remotes),
    "43fccb96b986f9da2c3a4320fe58693ca660193b"
  )

  # Test case 3: When input is invalid
  testthat::expect_error(
    resolve_package_commit(c(), date, remotes),
    "remote_pkg_name_and_ref must be a list of length 1 or 2"
  )

  # Test case 4: resolve_package_commit falls back to HEAD when API fails
  pkg_name <- c("nonexistent")
  remotes <- c("user/nonexistent")
  target_date <- "2024-04-04T14:16:11Z"

  testthat::expect_message(
    result <- resolve_package_commit(pkg_name, target_date, remotes),
    "Failed to get closest commit for user/nonexistent:"
  )
  testthat::expect_equal(result, "HEAD")
})
