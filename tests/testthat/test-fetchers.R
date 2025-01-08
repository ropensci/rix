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
    "\n    AER = (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    }),\n"
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

testthat::test_that("Test fetchzips works", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchzips(
      c("dplyr@0.8.0", "AER@1.2-8")
    ),
    "\n    AER = (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    }),\n\n\n    dplyr = (pkgs.rPackages.buildRPackage {\n      name = \"dplyr\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.0.tar.gz\";\n       sha256 = \"sha256-f30raalLd9KoZKZSxeTN71PG6BczXRIiP6g7EZeH09U=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          glue\n          magrittr\n          pkgconfig\n          R6\n          Rcpp\n          rlang\n          tibble\n          tidyselect\n          BH\n          plogr;\n      };\n    }),\n"
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
    "\n    fusen = (pkgs.rPackages.buildRPackage {\n      name = \"fusen\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/ThinkR-open/fusen\";\n        rev = \"d617172447d2947efb20ad6a4463742b8a5d79dc\";\n        sha256 = \"sha256-TOHA1ymLUSgZMYIA1a2yvuv0799svaDOl3zOhNRxcmw=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          attachment\n          cli\n          desc\n          devtools\n          glue\n          here\n          magrittr\n          parsermd\n          roxygen2\n          stringi\n          tibble\n          tidyr\n          usethis\n          yaml;\n      };\n    });\n\n\n    housing = (pkgs.rPackages.buildRPackage {\n      name = \"housing\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/rap4all/housing/\";\n        rev = \"1c860959310b80e67c41f7bbdc3e84cef00df18e\";\n        sha256 = \"sha256-s4KGtfKQ7hL0sfDhGb4BpBpspfefBN6hf+XlslqyEn4=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          dplyr\n          ggplot2\n          janitor\n          purrr\n          readxl\n          rlang\n          rvest\n          stringr\n          tidyr;\n      };\n    });\n \n    AER = (pkgs.rPackages.buildRPackage {\n      name = \"AER\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/AER/AER_1.2-8.tar.gz\";\n       sha256 = \"sha256-OqxXcnUX/2C6wfD5fuNayc8OU+mstI3tt4eBVGQZ2S0=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          car\n          lmtest\n          sandwich\n          survival\n          zoo\n          Formula;\n      };\n    }),\n\n\n    dplyr = (pkgs.rPackages.buildRPackage {\n      name = \"dplyr\";\n      src = pkgs.fetchzip {\n       url = \"https://cran.r-project.org/src/contrib/Archive/dplyr/dplyr_0.8.0.tar.gz\";\n       sha256 = \"sha256-f30raalLd9KoZKZSxeTN71PG6BczXRIiP6g7EZeH09U=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          glue\n          magrittr\n          pkgconfig\n          R6\n          Rcpp\n          rlang\n          tibble\n          tidyselect\n          BH\n          plogr;\n      };\n    }),\n"
  )
})

testthat::test_that("Test fetchgit gets a package with several remote deps", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "lookup",
        repo_url = "https://github.com/jimhester/lookup/",
        commit = "eba63db477dd2f20153b75e2949eb333a36cccfc"
      )
    ),
    "\n    httr2 = (pkgs.rPackages.buildRPackage {\n      name = \"httr2\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/r-lib/httr2\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-rPMn+MvN/KCnhulS0Itv2g58fRYQw75SBJC15cSBxBI=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          cli\n          curl\n          glue\n          lifecycle\n          magrittr\n          openssl\n          R6\n          rappdirs\n          rlang\n          vctrs\n          withr;\n      };\n    });\n\n    gh = (pkgs.rPackages.buildRPackage {\n      name = \"gh\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/gaborcsardi/gh\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-VpxFIfUEk0PudytQ3boMhEJhT0AnelWkSU++WD/HAyo=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          cli\n          gitcreds\n          glue\n          ini\n          jsonlite\n          lifecycle\n          rlang;\n      } ++ [ httr2 ];\n    });\n\n\n    highlite = (pkgs.rPackages.buildRPackage {\n      name = \"highlite\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/jimhester/highlite\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-lkWMlAi75MYxiBUYnLwxLK9ApXkWanA4Mt7g4qtLpxM=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Rcpp\n          BH;\n      };\n    });\n\n\n    memoise = (pkgs.rPackages.buildRPackage {\n      name = \"memoise\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/hadley/memoise\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-FDMNgrgctzkN8dXKRoWsOKe3tXxmm8Cqdu/Sh6WKx/Q=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          rlang\n          cachem;\n      };\n    });\n\n    lookup = (pkgs.rPackages.buildRPackage {\n      name = \"lookup\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/jimhester/lookup/\";\n        rev = \"eba63db477dd2f20153b75e2949eb333a36cccfc\";\n        sha256 = \"sha256-arl7LVxL8xGUW3LhuDCSUjcfswX0rdofL/7v8Klw8FM=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Rcpp\n          codetools\n          crayon\n          rex\n          jsonlite\n          rstudioapi\n          withr\n          httr;\n      } ++ [ highlite gh memoise ];\n    });\n"
  )
})


testthat::test_that("Test fetchgit gets a package with one remote dep", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "scMisc",
        repo_url = "https://github.com/mihem/scMisc/",
        commit = "e2ebddcb779b935551f14216514c0429616fc91d"
      )
    ),
    "\n    enrichR = (pkgs.rPackages.buildRPackage {\n      name = \"enrichR\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/wjawaid/enrichR\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-Jm6Z46ARyp+geSY4RLb/x9zV6uvlyjnFdLh4/c6uGoI=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          httr\n          curl\n          rjson\n          ggplot2\n          WriteXLS;\n      };\n    });\n\n    scMisc = (pkgs.rPackages.buildRPackage {\n      name = \"scMisc\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/mihem/scMisc/\";\n        rev = \"e2ebddcb779b935551f14216514c0429616fc91d\";\n        sha256 = \"sha256-Atmr+vGfJxNc5HK+UgpnSIeZ1fYKWEzD3Dt2va1xoFE=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Seurat\n          readr\n          glue\n          viridis\n          ggplot2\n          pheatmap\n          homologene\n          dplyr\n          tibble\n          magrittr\n          clustifyr\n          ggrepel\n          writexl\n          ggsignif\n          patchwork\n          rstatix\n          readxl\n          tidyr\n          speckle\n          limma\n          RColorBrewer\n          factoextra\n          FactoMineR\n          Matrix\n          ggpubr\n          tidyselect\n          stringr\n          forcats;\n      } ++ [ enrichR ];\n    });\n"
  )
})

testthat::test_that("Test fetchgit gets a package with several remote deps and commits", {
  testthat::skip_on_cran()
  testthat::expect_equal(
    fetchgit(
      list(
        package_name = "lookup",
        repo_url = "https://github.com/b-rodrigues/lookup/",
        commit = "f7c836fae9bddf7da298f7b7fb311ce0fb33488b"
      )
    ),
    "\n    glue = (pkgs.rPackages.buildRPackage {\n      name = \"glue\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/tidyverse/glue\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-HuYKjZYVd2RF16F3HsYE7xGQHvV45z6YIe5K6OlDFLo=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) ;\n      };\n    });\n\n\n    httr = (pkgs.rPackages.buildRPackage {\n      name = \"httr\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/hadley/httr\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-DtgrlVyPhp0V3bgpwzvJMH7luxqPJJ37ObMIeZnUDX8=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          curl\n          jsonlite\n          mime\n          openssl\n          R6;\n      };\n    });\n\n    httrmock = (pkgs.rPackages.buildRPackage {\n      name = \"httrmock\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/gaborcsardi/httrmock\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-+Sncxv83N/FB0mL1KJSTtwFoZb6zxULncmr00cv7Fuc=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          assertthat\n          base64enc\n          debugme\n          digest\n          lintr\n          R6\n          rprojroot\n          whoami;\n      } ++ [ httr glue ];\n    });\n\n    gh = (pkgs.rPackages.buildRPackage {\n      name = \"gh\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/gaborcsardi/gh\";\n        rev = \"8237a88\";\n        sha256 = \"sha256-yZofcmA+mpYsi81DcEQsA2vtVcaTvK1FDXfpJEiLqVY=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          ini\n          jsonlite\n          httr;\n      } ++ [ httrmock ];\n    });\n\n\n    highlite = (pkgs.rPackages.buildRPackage {\n      name = \"highlite\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/jimhester/highlite\";\n        rev = \"HEAD\";\n        sha256 = \"sha256-lkWMlAi75MYxiBUYnLwxLK9ApXkWanA4Mt7g4qtLpxM=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Rcpp\n          BH;\n      };\n    });\n\n\n    memoise = (pkgs.rPackages.buildRPackage {\n      name = \"memoise\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/hadley/memoise\";\n        rev = \"74d62c8\";\n        sha256 = \"sha256-fsdop66VglkOIYrJ0LKZKikIZmzQ2gqEATLy9tTJ/B8=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          digest;\n      };\n    });\n\n    lookup = (pkgs.rPackages.buildRPackage {\n      name = \"lookup\";\n      src = pkgs.fetchgit {\n        url = \"https://github.com/b-rodrigues/lookup/\";\n        rev = \"a36973c87ec0f24e4b1bf2884c7cc99dc442f8ff\";\n        sha256 = \"sha256-zE5LcjeO5xcABo+ZfHLh6N1bWbH9rJYLfL0ewZe7/bk=\";\n      };\n      propagatedBuildInputs = builtins.attrValues {\n        inherit (pkgs.rPackages) \n          Rcpp\n          codetools\n          crayon\n          rex\n          jsonlite\n          rstudioapi\n          withr\n          httr;\n      } ++ [ highlite gh memoise ];\n    });\n"
  )
})
