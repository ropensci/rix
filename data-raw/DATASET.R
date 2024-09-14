## code to prepare `DATASET` dataset goes here

library(rix)

# This script is only needed for the developers of `{rix}`.

# To install old versions of R, specific Nix revisions must be used. This tool
# [Nix Package Versions](https://lazamar.co.uk/nix-versions/) provides a simple
# web-interface to look for packages and get their revisions.

# It is possible to scrape the table and get the data, but the code below
# should not be executed and is instead kept for historcial reasons:

# This is commented as it is not needed anymore
# library(rvest)
# library(dplyr)
# library(janitor)

# r_nix_revs <-
#  read_html(
#    "https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=r"
#  ) |>
#  html_element("table") |>
#  html_table() |>
#  clean_names() |>
#  filter(!grepl("wrapper", version)) |>
#  select(-package)

# The code above provided commits up until version 4.3.1. The commit for the
# 4.3.2 release does not use the above code, instead we manually chose the last
# commit that contains all the fixes that were merged during this release. This
# ensures that a maximum of packages are in a working state.


# data("r_nix_revs")

# This was added already, so it's commented now
# revision_4.3.2 <- as.data.frame(
#  list(
#    "version" = "4.3.2",
#    "revision" = "219f896bdf192721446db4fedc338eebf732057d",
#    "date" = "2024-03-10"
#  )
# )

# revision_4.3.3 <- as.data.frame(
#  list(
#    "version" = "4.3.3",
#    "revision" = "019f5c29c5afeb215587e17bf1ec31dc1913595b",
#    "date" = "2024-06-17"
#  )
# )
#
# revision_4.4.0 <- as.data.frame(
#  list(
#    "version" = "4.4.0",
#    "revision" = "6f3340bf0f888d0fda9a3b91dd5b3a9b05d08212",
#    "date" = "2024-06-20"
#  )
# )

# uncomment to update
# revision_4.4.0 <- as.data.frame(
#  list(
#    "version" = "4.4.0",
#    "revision" = "6f3340bf0f888d0fda9a3b91dd5b3a9b05d08212",
#    "date" = "2024-06-20"
#  )
# )

sysdata <- rbind(
  sysdata,
  revision_4.3.3,
  revision_4.4.0
)

usethis::use_data(sysdata, internal = TRUE, overwrite = TRUE)
