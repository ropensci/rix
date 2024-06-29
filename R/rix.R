#' Generate a Nix expression that builds a reproducible development
#' environment
#' @return Nothing, this function only has the side-effect of writing a file
#'   called "default.nix" in the working directory. This file contains the
#'   expression to build a reproducible environment using the Nix package
#'   manager.
#' @param r_ver Character, defaults to "latest". The required R version, for
#'   example "4.0.0". You can check which R versions are available using
#'   `available_r`. For reproducibility purposes, you can also provide a nixpkgs
#'   revision directly. For older versions of R, `nix-build` might fail with an
#'   error stating 'this derivation is not meant to be built'. In this case,
#'   simply drop into the shell with `nix-shell` instead of building it first.
#'   It is also possible to provide either "bleeding_edge" or
#'   "frozen_edge" if you need an environment with bleeding edge packages. Read
#'   more in the "Details" below.
#' @param r_pkgs Vector of characters. List the required R packages for your
#'   analysis here.
#' @param system_pkgs Vector of characters. List further software you wish to
#'   install that are not R packages such as command line applications for
#'   example. You can look for available software on the NixOS website
#'   \url{https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=}
#' @param git_pkgs List. A list of packages to install from Git. See details for
#' more information.
#' @param local_pkgs List. A list of paths to local packages to install. These
#' packages need to be in the `.tar.gz` or `.zip` formats.
#' @param tex_pkgs Vector of characters. A set of tex packages to install. Use
#'   this if you need to compile `.tex` documents, or build PDF documents using
#'   Quarto. If you don't know which package to add, start by adding "amsmath".
#'   See the Vignette "Authoring LaTeX documents" for more details.
#' @param ide Character, defaults to "other". If you wish to use RStudio to work
#'   interactively use "rstudio" or "rserver" for the server version. Use "code"
#'   for Visual Studio Code. You can also use "radian", an interactive REPL. For
#'   other editors, use "other". This has been tested with RStudio, VS Code and
#'   Emacs. If other editors don't work, please open an issue.
#' @param project_path Character, defaults to the current working directory.
#'   Where to write `default.nix`, for example "/home/path/to/project".
#'   The file will thus be written to the file
#'   "/home/path/to/project/default.nix".
#' @param overwrite Logical, defaults to FALSE. If TRUE, overwrite the
#'   `default.nix` file in the specified path.
#' @param print Logical, defaults to FALSE. If TRUE, print `default.nix` to
#' console.
#' @param shell_hook Character of length 1, defaults to `NULL`. Commands added
#'   to the `shellHook` variable executed when the Nix shell starts. So
#'   by default, using `nix-shell default.nix` (or path with `shell.nix`) will
#'   start a specific program, possibly with flags (separated by space), and/or
#'   do shell actions. You can for example use `shell_hook = R`, if you want to
#'   directly enter the declared Nix R session.
#' @details This function will write a `default.nix` in the chosen path. Using
#'   the Nix package manager, it is then possible to build a reproducible
#'   development environment using the `nix-build` command in the path. This
#'   environment will contain the chosen version of R and packages, and will not
#'   interfere with any other installed version (via Nix or not) on your
#'   machine. Every dependency, including both R package dependencies but also
#'   system dependencies like compilers will get installed as well in that
#'   environment.
#'
#'   It is possible to use environments built with Nix interactively, either
#'   from the terminal, or using an interface such as RStudio.  If you 
#'   want to use RStudio, set it to `"rstudio"`. Please be aware that RStudio
#'   is not available for macOS through Nix. As such, you may want to use another
#'   editor on macOS. To use Visual Studio Code (or Codium), set the `ide`
#'   argument to `"code"`, which will add the `{languageserver}` R package
#'   to the list of R packages to be installed by Nix in that environment. You can
#'   use the version of Visual Studio Code or Codium you already use, or also install
#'   it using Nix (by adding "vscode" or "vscodium" to the list of `system_pkgs`).
#'   For non-interactive use, or to use the environment from the command line, or from another
#'   editor (such as Emacs or Vim), set the `ide` argument to `"other"`.
#'   We recommend reading the `vignette("e-interactive-use")` for more details.
#'
#'   Packages to install from Github must be provided in a list of 4 elements:
#'   "package_name", "repo_url", "branch_name" and "commit". This argument can
#'   also be a list of lists of these 4 elements. It is also possible to install
#'   old versions of packages by specifying a version. For example, to install
#'   the latest version of `{AER}` but an old version of `{ggplot2}`, you could
#'   write: `r_pkgs = c("AER", "ggplot2@2.2.1")`. Note however that doing this
#'   could result in dependency hell, because an older version of a package
#'   might need older versions of its dependencies, but other packages might
#'   need more recent versions of the same dependencies. If instead you want to
#'   use an environment as it would have looked at the time of `{ggplot2}`'s
#'   version 2.2.1 release, then use the Nix revision closest to that date, by
#'   setting `r_ver = "3.1.0"`, which was the version of R current at the time.
#'   This ensures that Nix builds a completely coherent environment.
#'
#'   By default, the nix shell will be configured with `"en_US.UTF-8"` for the
#'   relevant locale variables (`LANG`, `LC_ALL`, `LC_TIME`, `LC_MONETARY`,
#'   `LC_PAPER`, `LC_MEASUREMENT`). This is done to ensure locale
#'   reproducibility by default in Nix environments created with `rix()`. If
#'   there are good reasons to not stick to the default, you can set your
#'   preferred locale variables via `options(rix.nix_locale_variables =
#'   list(LANG = "de_CH.UTF-8", <...>)` and the aforementioned locale variable
#'   names.
#'
#'   It is possible to use "bleeding_edge" or "frozen_edge" as the value for the
#'   `r_ver` argument. This will create an environment with the very latest R
#'   packages. "bleeding_edge" means that every time you will build the
#'   environment, the packages will get updated. This is especially useful for
#'   environments that need to be constantly updated, for example when
#'   developing a package. In contrast, "frozen_edge" will create an environment
#'   that will remain stable at build time. So if you create a `default.nix`
#'   file using "bleeding_edge", each time you build it using `nix-build` that
#'   environment will be up-to-date. With "frozen_edge" that environment will be
#'   up-to-date on the date that the `default.nix` will be generated, and then
#'   each subsequent call to `nix-build` will result in the same environment. We
#'   highly recommend you read the vignette titled
#'   "z - Advanced topic: Understanding the rPackages set release cycle and using bleeding edge packages".
#' @export
#' @examples
#' \dontrun{
#' # Build an environment with the latest version of R
#' # and the dplyr and ggplot2 packages
#' rix(
#'   r_ver = "latest",
#'   r_pkgs = c("dplyr", "ggplot2"),
#'   system_pkgs = NULL,
#'   git_pkgs = NULL,
#'   local_pkgs = NULL,
#'   ide = "code",
#'   project_path = path_default_nix,
#'   overwrite = TRUE,
#'   print = TRUE,
#'   shell_hook = NULL
#' )
#' }
rix <- function(r_ver = "latest",
                r_pkgs = NULL,
                system_pkgs = NULL,
                git_pkgs = NULL,
                local_pkgs = NULL,
                tex_pkgs = NULL,
                ide = c("other", "code", "radian", "rstudio", "rserver"),
                project_path = ".",
                overwrite = FALSE,
                print = FALSE,
                shell_hook = NULL) {
  if (r_ver %in% c("bleeding_edge", "frozen_edge")) {
    warning(
      "You chose 'bleeding_edge' or 'frozen_edge' as the value for
`r_ver`. Please read the vignette
https://b-rodrigues.github.io/rix/articles/z-advanced-topic-understanding-the-rpackages-set-release-cycle-and-using-bleeding-edge-packages.html
before continuing."
    )
  }

  if(r_ver %in% available_r() & r_ver != "latest" & r_ver <= "4.1.1"){
    warning(
      "You are generating an expression for an older version of R.\n To use this environment, you should directly use `nix-shell` and not try to build it first using `nix-build`."
    )
  }

  if(r_ver == "4.4.0"){
    warning(
      "You chose '4.4.0' as the R version, however this version is not available in nixpkgs. The generated expression will thus install R version 4.4.1."
    )
  }

  ide <- match.arg(ide, c("other", "code", "radian", "rstudio", "rserver"))

  # Wrapper attributes to be used later
  attrib <- c(
    radian = "radianWrapper",
    rstudio = "rstudioWrapper",
    rserver = "rstudioServerWrapper"
  )

  if (Sys.info()["sysname"] == "Darwin" & ide == "rstudio") {
    warning(
      "Your detected operating system is macOS, and you chose
'rstudio' as the IDE. Please note that 'rstudio' is not
available through 'nixpkgs' for macOS, so the expression you
generated will not build on macOS. If you wish to build this
expression on macOS, change the 'ide =' argument to either
'code' or 'other'. Please refer to the macOS-specific vignette
https://b-rodrigues.github.io/rix/articles/b2-setting-up-and-using-rix-on-macos.html
for more details."
    )
  }

  project_path <- if (project_path == ".") {
    "default.nix"
  } else {
    paste0(project_path, "/default.nix")
  }

  # Find url to use
  # In case of bleeding or frozen edge, the rstats-on-nix/nixpkgs
  # fork is used. Otherwise, upstream NixOS/nixpkgs
  nix_repo <- make_nixpkgs_url(r_ver)

  project_path <- file.path(project_path)

  rix_call <- match.call()

  # Get the two lists. One list is current CRAN packages
  # the other is archived CRAN packages.
  cran_pkgs <- get_rpkgs(r_pkgs, ide)

  # If there are R packages, passes the string "rpkgs" to buildInputs
  flag_rpkgs <- if (is.null(cran_pkgs$rPackages) | cran_pkgs$rPackages == "") {
    ""
  } else {
    "rpkgs"
  }

  # If there are LaTeX packages, passes the string "tex" to buildInputs
  flag_tex_pkgs <- if (is.null(tex_pkgs)) {
    ""
  } else {
    "tex"
  }

  # If there are R packages from Git, passes the string "git_archive_pkgs" to buildInputs
  flag_git_archive <- if (!is.null(cran_pkgs$archive_pkgs) | !is.null(git_pkgs)) {
    "git_archive_pkgs"
  } else {
    ""
  }

  # If there are R packages local packages, passes the string "local_pkgs" to buildInputs
  flag_local_pkgs <- if (is.null(local_pkgs)) {
    ""
  } else {
    "local_pkgs"
  }

  # If there are wrapped packages (for example for RStudio), passes the "wrapped_pkgs"
  # to buildInputs
  flag_wrapper <- if (ide %in% names(attrib) & flag_rpkgs != "") "wrapped_pkgs" else ""

  # Correctly formats shellHook for Nix's mkShell
  shell_hook <- if (!is.null(shell_hook) && nzchar(shell_hook)) {
    paste0('shellHook = "', shell_hook, '";')
  } else {
    ""
  }

  # Generate default.nix file
  default.nix <- paste(
    generate_header(
      nix_repo,
      r_ver,
      rix_call
    ),
    generate_rpkgs(cran_pkgs$rPackages, flag_rpkgs),
    generate_git_archived_pkgs(git_pkgs, cran_pkgs$archive_pkgs, flag_git_archive),
    generate_tex_pkgs(tex_pkgs),
    generate_local_pkgs(local_pkgs, flag_local_pkgs),
    generate_system_pkgs(system_pkgs, r_pkgs),
    generate_wrapped_pkgs(ide, attrib, flag_git_archive, flag_rpkgs, flag_local_pkgs),
    generate_shell(
      flag_git_archive, flag_rpkgs, flag_tex_pkgs,
      flag_local_pkgs, flag_wrapper, shell_hook
    ),
    collapse = "\n"
  )

  default.nix <- readLines(textConnection(default.nix))

  if (print) {
    cat(default.nix, sep = "\n")
  }

  if (!file.exists(project_path) || overwrite) {
    writeLines(default.nix, project_path)
  } else {
    stop(paste0("File exists at ", project_path, ". Set `overwrite == TRUE` to overwrite."))
  }
}
