## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(chronicler)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

# Ensure chronicler version of `pick()` is being used
pick <- chronicler::pick

data("avia")

## -----------------------------------------------------------------------------
# Define required functions 
# You can use `record_many()` to avoid having to write everything

r_select <- record(select, .g = dim)
r_pivot_longer <- record(pivot_longer, .g = dim)
r_filter <- record(filter, .g = dim)
r_mutate <- record(mutate, .g = dim)
r_separate <- record(separate, .g = dim)
r_group_by <- record(group_by, .g = dim)
r_summarise <- record(summarise, .g = dim)


## -----------------------------------------------------------------------------
avia_clean <- avia %>%
  r_select(1, contains("20")) %>% # select the first column and every column starting with 20
  bind_record(r_pivot_longer, -starts_with("unit"), names_to = "date", values_to = "passengers") %>%
  bind_record(r_separate,
              col = 1,
              into = c("unit", "tra_meas", "air_pr\\time"),
              sep = ",")


## -----------------------------------------------------------------------------
avia_monthly <- avia_clean %>%
  bind_record(r_filter,
              tra_meas == "PAS_BRD_ARR",
              !is.na(passengers),
              str_detect(date, "M")) %>%
  bind_record(r_mutate,
              date = paste0(date, "01"),
              date = ymd(date)) %>%
  bind_record(r_select,
              destination = "air_pr\\time", date, passengers)


## -----------------------------------------------------------------------------
avia_monthly

## -----------------------------------------------------------------------------
read_log(avia_monthly)

## -----------------------------------------------------------------------------
avia_monthly %>%
  pick("value")

## -----------------------------------------------------------------------------
check_g(avia_monthly)

