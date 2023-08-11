<!-- NEWS.md is maintained by https://cynkra.github.io/fledge, do not edit -->

# rix 0.1.1 (2023-08-11)

# Patches

- `nix_build()` now correctly checks presence of `nix-build`. ([4be69b2](https://github.com/b-rodrigues/rix/commit/4be69b2c438276a1f636f3b407a124555bb12c9b))


# rix 0.1.0 (2023-08-11)

## New features

- Added `nix_build()` helper that runs `nix-build` interactively from R. 
  ([#22](https://github.com/b-rodrigues/rix/pull/22))
- `rix()` now supports installing packages from GitHub and the CRAN archives.
- `rix()` now supports using a `nixpkgs` revision instead of an R version 
  for reproducibility
- Generated `default.nix` files now also include the call that was made to 
  generate them as top-level comment.

## Changes

- The `path` argument of `rix()` changed to `project_path`.


# rix (development version)

- Basic functionality added.
