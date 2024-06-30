testthat::test_that("Test fetchgit works", {
  testthat::expect_equal(
    fetchgit(
      list(package_name = "housing",
           repo_url = "https://github.com/rap4all/housing/",
           branch_name = "fusen",
           commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
      )
    ),
      "\n    (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        branchName = \"fusen\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    })\n"
  )
})

testthat::test_that("Test fetchgit fails gracefully", {
  testthat::expect_error(
    fetchgit(
      list(package_name = "housing",
           repo_url = "https://github.com/rap4all/housing666/",
           branch_name = "this_branch_does_not_exist", # branch name not tested
           commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
           )
    ), "Are these correct?"
  )
})



testthat::test_that("Test fetchzip works", {
  testthat::expect_equal(
    fetchzip("AER@1.2-8"),
    "\n    (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    })\n"
    )
})

testthat::test_that("Test fetchzip fails gracefully", {
  testthat::expect_error(
    fetchzip("AER@999999"),
    "Are these correct?"
  )
})

testthat::test_that("Test fetchgits", {
  testthat::expect_equal(
    fetchgits(
      list(
        list(
          package_name = "housing",
          repo_url = "https://github.com/rap4all/housing/",
          branch_name = "fusen",
          commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"
        ),
        list(
          package_name = "fusen",
          repo_url = "https://github.com/ThinkR-open/fusen",
          branch_name = "main",
          commit = "d617172447d2947efb20ad6a4463742b8a5d79dc")
      )
    ),
    "\n    (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        branchName = \"fusen\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    })\n\n\n    (pkgs.rPackages.buildRPackage {\n      name = \"fusen\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/ThinkR-open/fusen\";\n        branchName = \"main\";\n        rev = \"d617172447d2947efb20ad6a4463742b8a5d79dc\";\n        sha256 = \"sha256-TOHA1ymLUSgZMYIA1a2yvuv0799svaDOl3zOhNRxcmw=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          attachment\n          cli\n          desc\n          devtools\n          glue\n          here\n          magrittr\n          parsermd\n          roxygen2\n          stringi\n          tibble\n          tidyr\n          usethis\n          yaml;\n      };\n    })\n"
  )
})

testthat::test_that("Test fetchzips works", {
  testthat::expect_equal(
    fetchzips(
      c("AER@1.2-8", "dplyr@0.8.0")),
      "\n    (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    })\n\n\n    (pkgs.rPackages.buildRPackage {\n      name = \"dplyr\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.0.tar.gz\";\n       sha256 = \"sha256-f30raalLd9KoZKZSxeTN71PG6BczXRIiP6g7EZeH09U=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          glue\n          magrittr\n          pkgconfig\n          R6\n          Rcpp\n          rlang\n          tibble\n          tidyselect\n          BH\n          plogr;\n      };\n    })\n"
  )
})


testthat::test_that("Test fetchpkgs works", {
  testthat::expect_equal(
    fetchpkgs(
      git_pkgs = list(
        list(
          package_name = "housing",
          repo_url = "https://github.com/rap4all/housing/",
          branch_name = "fusen",
          commit = "1c860959310b80e67c41f7bbdc3e84cef00df18e"),
       list(package_name = "fusen",
         repo_url = "https://github.com/ThinkR-open/fusen",
         branch_name = "main",
         commit = "d617172447d2947efb20ad6a4463742b8a5d79dc")
      ),
      archive_pkgs = c("AER@1.2-8", "dplyr@0.8.0")
    ),
    "\n    (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        branchName = \"fusen\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    })\n\n\n    (pkgs.rPackages.buildRPackage {\n      name = \"fusen\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/ThinkR-open/fusen\";\n        branchName = \"main\";\n        rev = \"d617172447d2947efb20ad6a4463742b8a5d79dc\";\n        sha256 = \"sha256-TOHA1ymLUSgZMYIA1a2yvuv0799svaDOl3zOhNRxcmw=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          attachment\n          cli\n          desc\n          devtools\n          glue\n          here\n          magrittr\n          parsermd\n          roxygen2\n          stringi\n          tibble\n          tidyr\n          usethis\n          yaml;\n      };\n    })\n \n    (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    })\n\n\n    (pkgs.rPackages.buildRPackage {\n      name = \"dplyr\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.0.tar.gz\";\n       sha256 = \"sha256-f30raalLd9KoZKZSxeTN71PG6BczXRIiP6g7EZeH09U=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          glue\n          magrittr\n          pkgconfig\n          R6\n          Rcpp\n          rlang\n          tibble\n          tidyselect\n          BH\n          plogr;\n      };\n    })\n"
    )
})
