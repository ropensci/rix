# mlr3_default.nix

path <- 'tests/testthat/testdata/remote-pkgs/'

rix(
  date = '2023-12-30',
  r_pkgs = c(
    'tidyverse',
    'mlr3',
    'qs',
    'matrixStats',
    'prospectr',
    'Cubist',
    'checkmate',
    'mlr3misc',
    'paradox'
  ),
  git_pkgs = list(
    package_name = 'mlr3extralearners',
    repo_url = 'https://github.com/mlr-org/mlr3extralearners/',
    commit = '6e2af9ef9ecd420d2be44e9aa2488772bb9f7080'
  ),
  ide = 'none',
  project_path = path,
  overwrite = TRUE,
  print = FALSE,
  ignore_remotes_cache = FALSE
)

file.rename(paste0(path, "default.nix"), paste0(path, "mlr3_default.nix"))

rix(
  date = '2023-12-30',
  r_pkgs = c(
    'tidyverse',
    'mlr3',
    'qs',
    'matrixStats',
    'prospectr',
    'Cubist',
    'checkmate',
    'mlr3misc',
    'paradox'
  ),
  git_pkgs = list(
    package_name = 'mlr3extralearners',
    repo_url = 'https://github.com/mlr-org/mlr3extralearners/',
    commit = '6e2af9ef9ecd420d2be44e9aa2488772bb9f7080'
  ),
  ide = 'none',
  project_path = path,
  overwrite = TRUE,
  print = FALSE,
  ignore_remotes_cache = TRUE
)

file.rename(paste0(path, "default.nix"), paste0(path, "mlr3_dups_default.nix"))
