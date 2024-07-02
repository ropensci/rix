
- [Reproducible Environments with
  Nix](#reproducible-environments-with-nix)
  - [Introduction](#introduction)
  - [Quick start for returning users](#quick-start-for-returning-users)
  - [Getting started for new users](#getting-started-for-new-users)
    - [Docker](#docker)
  - [Contributing](#contributing)
  - [Thanks](#thanks)
  - [Recommended reading](#recommended-reading)

<!-- badges: start -->

[![R-CMD-check](https://github.com/b-rodrigues/rix/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/b-rodrigues/rix/actions/workflows/R-CMD-check.yaml)
[![runiverse-package
rix](https://b-rodrigues.r-universe.dev/badges/rix?scale=1&color=pink&style=round)](https://b-rodrigues.r-universe.dev/rix)
[![Docs](https://img.shields.io/badge/docs-release-blue.svg)](https://b-rodrigues.github.io/rix)
[![Status at rOpenSci Software Peer
Review](https://badges.ropensci.org/625_status.svg)](https://github.com/ropensci/software-review/issues/625)
<!-- badges: end -->

<!-- README.md is generated from README.Rmd. Please edit that file -->

# rix: Reproducible Environments with Nix <a href="https://https://b-rodrigues.github.io/rix/"><img src="man/figures/logo.png" align="right" height="138" /></a>

## Introduction

`{rix}` is an R package that leverages [Nix](https://nixos.org/), a
powerful package manager focusing on reproducible builds. With Nix, it
is possible to create project-specific environments that contain a
project-specific version of R and R packages (as well as other tools or
languages, if needed). This project-specific environment will also
include all the required system-level dependencies that can be difficult
to install, such as `GDAL` for packages for geospatial analysis for
example. This is how Nix installs software: it installs software as a
complete “bundle” that include all of its dependencies, and all of the
dependencies’ dependencies and so on. Nix is an incredibly useful piece
of software for ensuring reproducibility of projects, in research or
otherwise. For example, it allows you run web applications like Shiny
apps or `{plumber}` APIs in a controlled environment, or run `{targets}`
pipelines with the right version of R and dependencies, and it is also
possible to use environments managed by Nix to work interactively using
an IDE.

In essence, this means that you can use `{rix}` and Nix to replace
`{renv}` and Docker with one single tool, but the approach is quite
different: `{renv}` records specific versions of individual packages,
while `{rix}` provides a complete snapshot of the R ecosystem at a
specific point in time, but also snapshots all the required dependencies
to make your project-specific R environment work. To ensure complete
reproducibility with `{renv}`, it must be combined with Docker, in order
to include system-level dependencies (like `GDAL`, as per the example
above).

Nix has a fairly high entry cost though. Nix is a complex piece of
software that comes with its own programming language, which is also
called Nix. Its purpose is to solve a complex problem: defining
instructions on how to build software packages and manage configurations
in a declarative way. This makes sure that software gets installed in a
fully reproducible manner, on any operating system or hardware.

`{rix}` provides functions to help you write Nix expressions (written in
the Nix language). These expressions will be the inputs for the Nix
package manager, to build sets of software packages and provide them in
a reproducible development environment. These environments can be used
for interactive data analysis, or reproduced when running pipelines in
CI/CD systems. The [Nixpkgs
collection](https://github.com/nixos/nixpkgs) includes currently more
than 100.000 pieces of software available through the Nix package
manager.

With `{rix}`, you can define development environments, or shells, that
contain the required tools needed to analyze data using R. These
environments are isolated from each other and project-specific: this
means that a project can use one version of R and R packages, and
another environment another version of R and R packages. However, extra
care is required if you already have R installed through the usual
method for your operating system, as these development environments are
not totally isolated from the rest of your system. Unlike Docker, where
a running container cannot acces anything from the host system, unless
explicitely configured to do so, Nix development shells are nothing but
environments that add more software to the list of already available
software (the so-called `PATH`). As such, it is possible to access
anything (files and software) already present on the system from a
running Nix shell. Thus, `{rix}` also provides a function called
`rix_init()` that helps isolate R sessions running inside Nix
environments from the rest of your system. This avoids clashes between
the Nix-specific library of R packages and the user library of R
packages should you already have R installed and managed by the usual
method for your operating system.

It is also possible to add any other software package available on
Nixpkgs to a Nix environment, for example IDEs such as RStudio or VS
Code. The Nix R ecosystem currently includes almost the entirety of CRAN
and Bioconductor packages (there is around a hundred CRAN or
Biocondcuctor packages that are unavailable through Nix). Like with any
other programming language or software, it is also possible to install
older releases of R packages, or install packages from GitHub at defined
states, as well as local packages in the `.tar.gz` format.

The Nix package manager is extremely powerful. Not only does it handle
all the dependencies of any package extremely well in a deterministic
manner, it is also possible with it to reproduce environments containing
old releases of software. It is thus possible to build environments
containing R version 4.0.0 (for example) to run an old project that was
originally developed on that version of R.

If you need other tools or languages like Python or Julia, this can also
be done easily. Nix is available for Linux, macOS and Windows (via WSL2)
and `{rix}` comes with the following features:

- define complete development environments as code and use them
  anywhere;
- install project-specific complete R environments, which can be
  different from each other;
- run single R functions (and objects in the call stack) in a different
  environment (potentially with a different R version and R packages)
  for an interactive R session, and get back the output of that function
  using
  [`with_nix()`](https://b-rodrigues.github.io/rix/reference/with_nix.html);

`{rix}` does not require Nix to be installed on your system to generate
expressions. This means that you can generate expressions on a system on
which you cannot easily install software, and then use these expressions
on the cloud or on a CI/CD environment to build the project there.

If you have R installed, you can start straight away from your R session
by first installing `{rix}`:

``` r
install.packages("rix", repos = c("https://b-rodrigues.r-universe.dev",
  "https://cloud.r-project.org"))

library("rix")
```

``` r
path_default_nix <- "."

rix(r_ver = "4.3.3",
    r_pkgs = c("dplyr", "ggplot2"),
    system_pkgs = NULL,
    git_pkgs = NULL,
    ide = "code",
    project_path = path_default_nix,
    overwrite = TRUE,
    print = TRUE)
```

This generates a file called `default.nix` in the path
`path_default_nix` with the correct expression to build this
environment. To build the environment, the Nix package manager must be
installed. If you have Nix installed, you can build the expression above
using the `nix-build` terminal command and then enter the environment
using `nix-shell`. The vignettes included in the package walk you
through the whole workflow.

## Quick start for returning users

*If you are not familiar with Nix or `{rix}` skip to the next section.*

<details>
<summary>
Click to expand
</summary>

If you are already familiar with Nix and R, and simply want to get
started as quickly as possible, you can start by installing Nix using
the installer from [Determinate
Systems](https://determinate.systems/posts/determinate-nix-installer) a
company that provides services and tools built on Nix:

``` sh
curl --proto '=https' --tlsv1.2 -sSf \
    -L https://install.determinate.systems/nix | \
     sh -s -- install
```

You can check that everything works well by trying to build the Nix
expression that ships with `{rix}`. Nix expressions are typically saved
into files with the name `default.nix` or `shell.nix`. This expression
installs the latest version of R and `{rix}` in a separate, reproducible
environment:

``` r
file.copy(
  # default.nix is the file containing the Nix expression
  from = system.file("extdata", "default.nix", package = "rix"),
  to = ".", overwrite = TRUE
)

# nix_build() is a wrapper around the command line tool `nix-build`
nix_build(project_path = ".")
```

If everything worked well, you should see a file called `result` next to
`default.nix`. You can now enter this newly built development
environment by opening a terminal in that folder and typing `nix-shell`.
You should be immediately dropped into an interactive R session.

If you don’t have R installed, but have the Nix package manager
installed, you can run a temporary R session with R using this command
(it will build the same environment as the one above):

    nix-shell --expr "$(curl -sl https://raw.githubusercontent.com/b-rodrigues/rix/master/inst/extdata/default.nix)"

You can then create new development environment definitions, build them,
and start using them.
</details>

## Getting started for new users

To get started with `{rix}` and Nix, you should read the following
vignette `vignette("a-getting-started")` ([online
documentation](https://b-rodrigues.github.io/rix/articles/a-getting-started.html)).
The vignettes are numbered to get you to learn how to use `{rix}` and
Nix smoothly. There’s a lot of info, so take your time reading the
vignettes. Don’t hesitate to open an issue if something is not clear.

### Docker

You can also try out Nix inside Docker. To know more, read
`vignette("z-advanced-topic-using-nix-inside-docker")`
[link](https://github.com/b-rodrigues/rix/blob/HEAD/vignettes/z-advanced-topic-using-nix-inside-docker.Rmd).

## Contributing

Refer to `Contributing.md` to learn how to contribute to the package.

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
