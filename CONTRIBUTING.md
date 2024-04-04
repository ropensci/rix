# Contributing

## Development environment

We provide a `default.nix` file that defines the right development environment
if you already are a Nix user and wish to contribute to the package. This
development environment will provide bleeding edge packages, as it is uses
a fork of `nixpkgs` that gets updated daily (R packages included). Because
this environment is bleeding edge, no pre-built binaries are available from
`chache.nixos.org`, so building this environment locally is quite time-consuming.

To speed-up this process, we also provide a cache of this environment that
also gets updated several times a day. To use this cache, you need
to have [cachix](https://app.cachix.org/) installed and configured. So if you
wish to use this development environment and its associated cache to very
quickly have the right environment to contribute to the package, run the 
following steps:

- First, install cachix: `nix-env -iA cachix -f https://cachix.org/api/v1/install`
- Enable the cache: `cachix use b-rodrigues`

You might get an error message stating that your user cannot use caches. Simply
follow the instructions in the warning to give the right permissions to your
user to use caches.

Then, when you run `nix-build`, binaries will be pulled from `b-rodrigues.cachix.org` and
`cache.nixos.org`. Building the development environment is nothing more than
waiting for packages to download.

There is also the possibility that you cannot successfully build the devoplement 
environment: because the `nixpkgs` fork gets updated fully automatically several times
a day without any checks, if building a package fails, there will be no fix released yet.

If you cannot build the development environment, please open an issue, we could then
propose a fix upstream.

## {fusen} and {fledge}

This package is developed using the `{fusen}` package. If you want to
contribute, please edit the `.Rmd` files found in the `dev/` folder. Then,
inflate the package using `fusen::inflate_all()`. If no errors are found
(warning and notes are OK), then commit and open a PR. To learn how to use
`{fusen}` (don't worry, it's super easy), refer to this
[vignette](https://thinkr-open.github.io/fusen/articles/How-to-use-fusen.html).
In our development workflow, we use [semantic versioning](https://semver.org)
via [{fledge}](https://fledge.cynkra.com).

## Discussions

For general discussion about the package, open a discussion on <https://github.com/b-rodrigues/rix/discussions>.
To submit bug reports or request features, open an issue <https://github.com/b-rodrigues/issues>.
