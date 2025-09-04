
## 04-09-2025 Submission, version 0.17.1 second attempt

First submission resulted in this note:

```
Found the following (possibly) invalid URLs:
  URL: https://matrix.to/#/#r:nixos.org
```

This url is however correct, but replacing the second `#`
with %23 solved it.

## 24-04-2025 Submission, version 0.16.0

R CMD check using R-devel with win-builder:

```
OK
```

Tested on other platforms, same results.

## 01-03-2025 Submission, version 0.15.7

R CMD check using R-devel with win-builder:

```
0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... [22s] NOTE
Maintainer: 'Bruno Rodrigues <bruno@brodrigues.co>'

```

We believe that this NOTE is not relevant for a new
release.

## 01-03-2025 Submission, version 0.15.5

R CMD check using R-devel with win-builder:

```
0 errors | 0 warnings | 0 note

same on other platforms.

```

This release also fixes the currently failing unit test:
https://cran.r-project.org/web/checks/check_results_rix.html

## 15-02-2025 Submission, version 0.15.2

R CMD check using R-devel with win-builder:

```
0 errors | 0 warnings | 1 note

same on other platforms.

Possibly misspelled words in DESCRIPTION:
  Dolstra (29:5)
```

This is not a misspelling.

## 21-01-2025 Submission, version 0.14.4

R CMD check using R-devel with win-builder:

0 errors | 0 warnings | 0 note

same on other platforms.

## 10-01-2025 Submission, version 0.14.3

R CMD check using R-devel with win-builder:

0 errors | 0 warnings | 0 note

same on other platforms.

## 02-10-2024 Submission, version 0.12.4

0 errors | 0 warnings | 1 note

Note is because previous submission was 6 days ago.
We contacted Uwe Ligges explaining that users found a bug and
that we wished to submit a fix.

Results on Rhub: https://github.com/ropensci/rix/actions/runs/11149347578
(linux, macos and windows)

Also ran R CMD check using R-devel with win-builder,
also only 1 note, same as above.

## 26-09-2024 Submission, version 0.12.3

0 errors | 0 warnings | 1 note

Possibly misspelled words in DESCRIPTION:
  Dolstra (19:5)

Results on Rhub: https://github.com/ropensci/rix/actions/runs/11056226443

Also ran R CMD check using R-devel with win-builder,
also only 1 note.

Note is because is because of the name of the author of the
thesis that we cite, Dolstra. It is not a typo.

## 23-09-2024 Resubmission, version 0.12.1

### R CMD check results

0 errors | 0 warnings | 1 note

Results on Rhub: https://github.com/ropensci/rix/actions/runs/11020276185

Also ran R CMD check using R-devel with win-builder,
also only 1 note.

Note is because it's a new release.

#### Comments from CRAN maintainers from submission of the 20-09-2024:

- The Title field starts with the package name. Please omit it.

Done.

- Please always write package names, software names and API (application
programming interface) names in single quotes in title and description.
e.g: --> 'Nix'
Please note that package names are case sensitive.

Done.

- The Description field is intended to be a (one paragraph) description of
what the package does and why it may be useful. Please add more details
about the package functionality and implemented methods in your
Description text.

Done.

- If there are references describing the methods in your package, please
add these in the description field of your DESCRIPTION file in the form
authors (year) <doi:...>
authors (year, ISBN:...)
or if those are not available: <https:...>
with no space after 'doi:', 'https:' and angle brackets for
auto-linking. (If you want to add a title as well please put it in
quotes: "Title")

We added a reference to a paper describing Nix.

- Please ensure that your functions do not write by default or in your
examples/vignettes/tests in the user's home filespace (including the
package directory and getwd()). This is not allowed by CRAN policies.
Please omit any default path in writing functions. In your
examples/vignettes/tests you can write to tempdir().
-> R/rix.R; R/rix_init.R

There was a vignette writing to `"."` instead of `tempdir()`, this has
been fixed with https://github.com/ropensci/rix/pull/328/commits/0f92911d6959b6f87cc4013744f2ede3c49d19d5

Regarding functions `rix()` and `rix_init()`: we don't set `project_path` to
`"."` by default anymore.

* This is a new release.

## R CMD check results

0 errors | 0 warnings | 1 note

Results on Rhub:
https://github.com/ropensci/rix/actions/runs/10964768061/job/30449117244#step:6:130

The Note is stating that this is a new submission:

New submission

Possibly misspelled words in DESCRIPTION:
  Rix (2:8)

* This is a new release.
