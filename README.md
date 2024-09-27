
# rix: Reproducible Environments with Nix <a href="https://docs.ropensci.org/rix/"><img src="man/figures/logo.png" align="right" height="138" /></a>

- [Introduction](#introduction)
- [Quick start for returning users](#quick-start-for-returning-users)
- [Getting started for new users](#getting-started-for-new-users)
  - [Docker](#docker)
- [Why Nix? Comparison with Docker+renv/Conda/Guix](#why-nix-comparison)
- [Contributing](#contributing)
- [Thanks](#thanks)
- [Recommended reading](#recommended-reading)

<!-- badges: start -->

[![R-hub
v2](https://github.com/ropensci/rix/actions/workflows/rhub.yaml/badge.svg)](https://github.com/ropensci/rix/actions/workflows/rhub.yaml/)
[![CRAN](https://www.r-pkg.org/badges/version/rix)](https://CRAN.R-project.org/package=rix)
[![runiverse-package
rix](https://ropensci.r-universe.dev/badges/rix?scale=1&color=pink&style=round)](https://ropensci.r-universe.dev/rix)
[![Docs](https://img.shields.io/badge/docs-release-blue.svg)](https://docs.ropensci.org/rix/)
[![Status at rOpenSci Software Peer
Review](https://badges.ropensci.org/625_status.svg)](https://github.com/ropensci/software-review/issues/625)
<!-- badges: end -->

## Introduction

`{rix}` is an R package that leverages [Nix](https://nixos.org/), a
package manager focused on reproducible builds. With Nix, you can create
project-specific environments with a custom version of R, its packages,
and all system dependencies (e.g., `GDAL`). Nix ensures full
reproducibility, which is crucial for research and development projects.

Use cases include running web apps (e.g., Shiny, `{plumber}` APIs) or
`{targets}` pipelines with a controlled R environment. Unlike `{renv}`,
which snapshots package versions, `{rix}` provides an entire ecosystem
snapshot, including system-level dependencies.

*Important sidenote: as it so happened, there is currently a bug in the
released CRAN version that we thought we had solved, which we did, but
only partially. When running `rix::rix()` two files should be generated:
a `default.nix` and an `.Rprofile` for your project. It turns out that
this file can be empty. If it is, run
`rix::rix_init(rprofile_action = "overwrite")` to generate a proper
`.Rprofile`. This is important, especially on Mac or if you have a
system-wide library of packages! We will submit a fix asap.*

While Nix has a steep learning curve, `{rix}`

1.  simplifies creating Nix expressions, which define reproducible
    environments.
2.  lets you work interactively in IDEs like RStudio or VS Code, or use
    Nix in CI/CD workflows.
3.  provides helpers that make it easy to build those environments,
    evaluate the same code in different development environments, and
    finally to deploy software environments in production.

If you want to watch a 5-Minute video introduction click
[here](https://youtu.be/OOu6gjQ310c?si=qQ5lUhAg5U-WT2W1).

Nix includes nearly all CRAN and Bioconductor packages, with the ability
to install specific package versions or GitHub snapshots. Nix also
includes Python, Julia (and many of their respective packages) as well
as many, many other tools (up to 100’000 pieces of software as of
writing).

If you have R installed, you can start straight away from your R session
by first installing `{rix}`:

``` r
install.packages("rix", repos = c(
  "https://ropensci.r-universe.dev",
  "https://cloud.r-project.org"
))
library("rix")
```

Now try to generate an expression using `rix()`:

``` r
# Choose the path to your project
# This will create two files: .Rprofile and default.nix
path_default_nix <- "."

rix(
  r_ver = "4.3.3",
  r_pkgs = c("dplyr", "ggplot2"),
  system_pkgs = NULL,
  git_pkgs = NULL,
  ide = "code",
  project_path = path_default_nix,
  overwrite = TRUE,
  print = TRUE
)
```

This will generate two files, `default.nix` and `.Rprofile` in
`project_default_nix`. `default.nix` is the environment definition
written in the Nix programming language, and `.Rprofile` prevents
conflicts with library paths from system-installed R versions, offering
better control over your environment and improving isolation of Nix
environments. `.Rprofile` is created by `rix_init()` which is called
automatically by the main function, `rix()`.

## Quick Start for Returning Users

<details>
<summary>
Click to expand
</summary>

If you’re already familiar with Nix and `{rix}`, install Nix using the
[Determinate Systems
installer](https://determinate.systems/posts/determinate-nix-installer):

``` bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

You can then use `{rix}` to build and enter a Nix-based R environment:

``` r
library(rix)

path_default_nix <- "."

rix(
  r_ver = "4.3.3",
  r_pkgs = c("dplyr", "ggplot2"),
  system_pkgs = NULL,
  git_pkgs = NULL,
  ide = "code",
  project_path = path_default_nix,
  overwrite = TRUE,
  print = TRUE
)
```

``` r
# nix_build() is a wrapper around the command line tool `nix-build`
nix_build(project_path = ".")
```

If you don’t have R installed, but have the Nix package manager
installed, you can run a temporary R session with R using this command
(it will build an environment with the latest development version of
`{rix}` ):

    nix-shell --expr "$(curl -sl https://raw.githubusercontent.com/ropensci/rix/main/inst/extdata/default.nix)"

You can then create new development environment definitions, build them,
and start using them.
</details>

## Getting started for new users

New to `{rix}` and Nix? Start by reading the
`vignette("a-getting-started")` ([online
documentation](https://docs.ropensci.org/rix/articles/a-getting-started.html)).
to learn how to set up and use Nix smoothly.

### Docker

Try Nix inside Docker by following this
`vignette("z-advanced-topic-using-nix-inside-docker")`
[vignette](https://github.com/ropensci/rix/blob/HEAD/vignettes/z-advanced-topic-using-nix-inside-docker.Rmd).

## How is Nix different from Docker+renv/{groundhog}/{rang}/(Ana/Mini)Conda/Guix? or Why Nix?

### Docker + {renv}

Docker and {renv} provide robust reproducibility by combining package
snapshots with system-level dependencies. However, for long-term
reproducibility, Nix offers a simpler approach by bundling everything
(R, packages, and dependencies) in a single environment.

### Ana/Miniconda & Mamba

Conda is similar to Nix, but Nix offers immutable environments, making
it more reliable for preventing accidental changes. Nix also supports
nearly all CRAN and Bioconductor packages, which Conda lacks.

### Nix vs. Guix

Guix, like Nix, focuses on reproducibility, but Nix supports more
CRAN/Bioconductor packages and works across Windows, macOS, and Linux.

### Is {rix} all there is?

No, there are other tools that you might want to check out, especially
if you want to set up polyglot environments (even though it is possible
to use `{rix}` to set up an environment with R and Python packages for
example).

Take a look at <https://devenv.sh/> and <https://prefix.dev/> if you
want to explore other tools that make using Nix easier!

## Contributing

Refer to `Contributing.md` to learn how to contribute to the package.

Please note that this package is released with a [Contributor Code of
Conduct](https://ropensci.org/code-of-conduct/). By contributing to this
project, you agree to abide by its terms.

## Thanks

Thanks to the [Nix community](https://nixos.org/community/) for making
Nix possible, and thanks to the community of R users on Nix for their
work packaging R and CRAN/Bioconductor packages for Nix (in particular
[Justin Bedő](https://github.com/jbedo), [Rémi
Nicole](https://github.com/minijackson),
[nviets](https://github.com/nviets), [Chris
Hammill](https://github.com/cfhammill), [László
Kupcsik](https://github.com/Kupac), [Simon
Lackerbauer](https://github.com/ciil),
[MrTarantoga](https://github.com/MrTarantoga) and every other person
from the [Matrix Nixpkgs R channel](https://matrix.to/#/#r:nixos.org)).

Finally, thanks to [David Solito](https://www.davidsolito.com/about/)
for creating `{rix}`’s logo!

## Recommended reading

- [NixOS’s website](https://nixos.org/)
- [Nixpkgs’s GitHub repository](https://github.com/NixOS/nixpkgs)
- [Nix for R series from Bruno’s
  blog](https://www.brodrigues.co/tags/nix/). Or, in case you like video
  tutorials, watch [this one on Reproducible R development environments
  with Nix](https://www.youtube.com/watch?v=c1LhgeTTxaI)
- [nix.dev
  tutorials](https://nix.dev/tutorials/first-steps/towards-reproducibility-pinning-nixpkgs#pinning-nixpkgs)
- [INRIA’s Nix
  tutorial](https://nix-tutorial.gitlabpages.inria.fr/nix-tutorial/installation.html)
- [Nix pills](https://nixos.org/guides/nix-pills/)
- [Nix for Data
  Science](https://github.com/nix-community/nix-data-science)
- [NixOS explained](https://christitus.com/nixos-explained/): NixOS is
  an entire Linux distribution that uses Nix as its package manager.
- [Blog post: Nix with R and
  devtools](https://rgoswami.me/posts/nix-r-devtools/)
- [Blog post: Statistical Rethinking and
  Nix](https://rgoswami.me/posts/rethinking-r-nix/)
- [Blog post: Searching and installing old versions of Nix
  packages](https://lazamar.github.io/download-specific-package-version-with-nix/)
