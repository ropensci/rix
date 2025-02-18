#' Generate a Nix expression that builds a reproducible development environment
#' @return Nothing, this function only has the side-effect of writing two files:
#'   `default.nix` and `.Rprofile` in the working directory. `default.nix`
#'   contains a Nix expression to build a reproducible environment using the Nix
#'   package manager, and `.Rprofile` ensures that a running R session from a
#'   Nix environment cannot access local libraries, nor install packages using
#'   `install.packages()` (nor remove nor update them).
#' @param r_ver Character. The required R version, for example "4.0.0". You can
#'   check which R versions are available using `available_r()`, and for more
#'   details check `available_df()`. For reproducibility purposes, you can also
#'   provide a `nixpkgs` revision directly. For older versions of R, `nix-build`
#'   might fail with an error stating 'this derivation is not meant to be
#'   built'. In this case, simply drop into the shell with `nix-shell` instead
#'   of building it first. It is also possible to provide either "bleeding-edge"
#'   or "frozen-edge" if you need an environment with bleeding edge packages.
#'   Read more in the "Details" section below.
#' @param date Character. Instead of providing `r_ver`, it is also possible to
#'   provide a date. This will build an environment containing R and R packages
#'   (and other dependencies) as of that date. You can check which dates are
#'   available with `available_dates()`. For more details about versions check
#'   `available_df()`.
#' @param r_pkgs Vector of characters. List the required R packages for your
#'   analysis here.
#' @param system_pkgs Vector of characters. List further software you wish to
#'   install that are not R packages such as command line applications for
#'   example. You can look for available software on the NixOS website
#'   \url{https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=}
#' @param git_pkgs List. A list of packages to install from Git. See details for
#'   more information.
#' @param local_r_pkgs List. A list of local packages to install. These packages
#'   need to be in the `.tar.gz` or `.zip` formats and must be in the same
#'   folder as the generated "default.nix" file.
#' @param tex_pkgs Vector of characters. A set of TeX packages to install. Use
#'   this if you need to compile `.tex` documents, or build PDF documents using
#'   Quarto. If you don't know which package to add, start by adding "amsmath".
#'   See the
#'   `vignette("d2- installing-system-tools-and-texlive-packages-in-a-nix-environment")`
#'   for more details.
#' @param ide Character, defaults to "none". If you wish to use RStudio to work
#'   interactively use "rstudio" or "rserver" for the server version. Use "code"
#'   for Visual Studio Code or "codium" for Codium, or "positron" for Positron.
#'   You can also use "radian", an interactive REPL. This will install a
#'   project-specific version of the chosen editor which will be differrent than
#'   the one already present in your system (if any). For other editors or if
#'   you want to use an editor already installed on your system (which will
#'   require some configuration to make it work seamlessly with Nix shells see
#'   the `vignette("e-configuring-ide")` for configuration examples), use
#'   "none". Please be aware that VS Code and Positron are not free software. To
#'   facilitate their installation, `rix()` automatically enables a required
#'   setting without prompting the user for confirmation. See the "Details"
#'   section below for more information.
#' @param project_path Character, where to write `default.nix`, for example
#'   "/home/path/to/project". The file will thus be written to the file
#'   "/home/path/to/project/default.nix". If the folder does not exist, it will
#'   be created.
#' @param overwrite Logical, defaults to FALSE. If TRUE, overwrite the
#'   `default.nix` file in the specified path.
#' @param print Logical, defaults to FALSE. If TRUE, print `default.nix` to
#'   console.
#' @param message_type Character. Message type, defaults to `"simple"`, which
#'   gives minimal but sufficient feedback. Other values are currently
#'   `"quiet`, which generates the files without message, and `"verbose"`,
#'   displays all the messages.
#' @param shell_hook Character of length 1, defaults to `NULL`. Commands added
#'   to the `shellHook` variable are executed when the Nix shell starts. So by
#'   default, using `nix-shell default.nix` will start a specific program,
#'   possibly with flags (separated by space), and/or do shell actions. You can
#'   for example use `shell_hook = R`, if you want to directly enter the
#'   declared Nix R session when dropping into the Nix shell.
#' @param skip_post_processing Logical, defaults to FALSE. Should post-processing be
#'   skipped? By default, if there are GitHub packages, the generated `default.nix`
#'   is post-processed to eliminate potential duplicate definitions of packages,
#'   which may happen if these packages have recursive remote dependencies. Set
#'   to TRUE to skip post processing, which might be useful for debugging.
#'
#' @details This function will write a `default.nix` and an `.Rprofile` in the
#'   chosen path. Using the Nix package manager, it is then possible to build a
#'   reproducible development environment using the `nix-build` command in the
#'   path. This environment will contain the chosen version of R and packages,
#'   and will not interfere with any other installed version (via Nix or not) on
#'   your machine. Every dependency, including both R package dependencies but
#'   also system dependencies like compilers will get installed as well in that
#'   environment.
#'
#'   It is possible to use environments built with Nix interactively, either
#'   from the terminal, or using an interface such as RStudio. If you want to
#'   use RStudio, set the `ide` argument to `"rstudio"`. Please be aware that
#'   RStudio is not available for macOS through Nix. As such, you may want to
#'   use another editor on macOS. To use Visual Studio Code (or Codium), set the
#'   `ide` argument to `"code"` or `"codium"` respectively, which will add the
#'   `{languageserver}` R package to the list of R packages to be installed by
#'   Nix in that environment. It is also possible to use Positron by setting the
#'   `ide` argument to `"positron"`. Setting the `ide` argument to an editor
#'   will install it from Nix, meaning that each of your projects can have a
#'   dedicated IDE (or IDE version). `"radian"` and `"rserver"` are also
#'   options.
#'
#'   Instead of using Nix to install an IDE, you can also simply use the one you
#'   have already installed on your system, with the exception of RStudio which
#'   must be managed by Nix to "see" Nix environments. Positron must also be
#'   heavily configured to work with Nix shells, so we recommend installing it
#'   using Nix. To use an editor that you already have installed on your system,
#'   set `ide = "none"` and refer to the `vignette("e-configuring-ide")` for
#'   more details on how to set up your editor to work with Nix shells.
#'
#'   Packages to install from GitHub or Gitlab must be provided in a list of 3
#'   elements: "package_name", "repo_url" and "commit". To install several
#'   packages, provide a list of lists of these 3 elements, one per package to
#'   install. It is also possible to install old versions of packages by
#'   specifying a version. For example, to install the latest version of `{AER}`
#'   but an old version of `{ggplot2}`, you could write: `r_pkgs = c("AER",
#'   "ggplot2@2.2.1")`. Note however that doing this could result in dependency
#'   hell, because an older version of a package might need older versions of
#'   its dependencies, but other packages might need more recent versions of the
#'   same dependencies. If instead you want to use an environment as it would
#'   have looked at the time of `{ggplot2}`'s version 2.2.1 release, then use
#'   the Nix revision closest to that date, by setting `r_ver = "3.1.0"`, which
#'   was the version of R current at the time. This ensures that Nix builds a
#'   completely coherent environment. For security purposes, users that wish to
#'   install packages from GitHub/Gitlab or from the CRAN archives must provide
#'   a security hash for each package. `{rix}` automatically precomputes this
#'   hash for the source directory of R packages from GitHub/Gitlab or from the
#'   CRAN archives, to make sure the expected trusted sources that match the
#'   precomputed hashes in the `default.nix` are downloaded. If Nix is
#'   available, then the hash will be computed on the user's machine, however,
#'   if Nix is not available, then the hash gets computed on a server that we
#'   set up for this purposes. This server then returns the security hash as
#'   well as the dependencies of the packages. It is possible to control this
#'   behaviour using `options(rix.sri_hash=x)`, where `x` is one of "check_nix"
#'   (the default), "locally" (use the local Nix installation) or "api_server"
#'   (use the remote server to compute and return the hash).
#'
#'   Note that installing packages from Git or old versions using the `"@"`
#'   notation or local packages, does not leverage Nix's capabilities for
#'   dependency solving. As such, you might have trouble installing these
#'   packages. If that is the case, open an issue on `{rix}`'s GitHub
#'   repository.
#'
#'   If GitHub packages have dependencies on GitHub as well, `{rix}` will
#'   attempt to generate the correct expression, but we highly recommend you
#'   read the
#'   `vignette("z-advanced-topic-handling-packages-with-remote-dependencies")`
#'   Vignette.
#'
#'   By default, the Nix shell will be configured with `"en_US.UTF-8"` for the
#'   relevant locale variables (`LANG`, `LC_ALL`, `LC_TIME`, `LC_MONETARY`,
#'   `LC_PAPER`, `LC_MEASUREMENT`). This is done to ensure locale
#'   reproducibility by default in Nix environments created with `rix()`. If
#'   there are good reasons to not stick to the default, you can set your
#'   preferred locale variables via `options(rix.nix_locale_variables =
#'   list(LANG = "de_CH.UTF-8", <...>)` and the aforementioned locale variable
#'   names.
#'
#'   It is possible to use `"bleeding-edge`" or `"frozen-edge`" as the value for
#'   the `r_ver` argument. This will create an environment with the very latest
#'   R packages. `"bleeding-edge`" means that every time you will build the
#'   environment, the packages will get updated. This is especially useful for
#'   environments that need to be constantly updated, for example when
#'   developing a package. In contrast, `"frozen-edge`" will create an
#'   environment that will remain stable at build time. So if you create a
#'   `default.nix` file using `"bleeding-edge`", each time you build it using
#'   `nix-build` that environment will be up-to-date. With `"frozen-edge`" that
#'   environment will be up-to-date on the date that the `default.nix` will be
#'   generated, and then each subsequent call to `nix-build` will result in the
#'   same environment. `"bioc-devel"` is the same as `"bleeding-edge"`, but also
#'   adds the development version of Bioconductor. `"r-devel"` is the same as
#'   bleeding edge, but with the R development version instead of the latest
#'   stable version and `"r-devel-bioc-devel"` is the same as `"r-devel"` but
#'   with Bioconductor on the development version. We highly recommend you read
#'   the vignette titled
#'   "z - Advanced topic: Understanding the rPackages set release cycle and
#'   using bleeding edge packages".
#' @export
#' @examples
#' \dontrun{
#' # Build an environment with the latest version of R available from Nixpkgs
#' # and the dplyr and ggplot2 packages
#' rix(
#'   r_ver = "latest-upstream",
#'   r_pkgs = c("dplyr", "ggplot2"),
#'   system_pkgs = NULL,
#'   git_pkgs = NULL,
#'   local_r_pkgs = NULL,
#'   ide = "code",
#'   project_path = path_default_nix,
#'   overwrite = TRUE,
#'   print = TRUE,
#'   message_type = "simple",
#'   shell_hook = NULL,
#'   skip_post_processing = FALSE
#' )
#' }
rix <- function(r_ver = NULL,
                date = NULL,
                r_pkgs = NULL,
                system_pkgs = NULL,
                git_pkgs = NULL,
                local_r_pkgs = NULL,
                tex_pkgs = NULL,
                ide = "none",
                project_path,
                overwrite = FALSE,
                print = FALSE,
                message_type = "simple",
                shell_hook = NULL,
                skip_post_processing = FALSE) {
  
  message_type <- match.arg(message_type,
    choices = c("quiet", "simple", "verbose")
  )

  if (ide == "other") {
    stop("ide = 'other' has been deprecated in favour of ide = 'none' as of version 0.15.0.")
  } else if (ide == "code") {
    warning("The behaviour of the 'ide' argument changed since version 0.15.0; we highly recommend reading this vignette: https://docs.ropensci.org/rix/articles/e-configuring-ide.html if you want to use VS Code.")
  } else if (!(ide %in% c(
    "none", "code", "codium", "positron",
    "radian", "rstudio", "rserver"
  ))) {
    stop("'ide' must be one of 'none', 'code', 'codium', 'positron', 'radian', 'rstudio', 'rserver'")
  }

  if (!is.null(date) && !(date %in% available_dates())) {
    # nolint start: line_length_linter
    stop("The provided date is not available.\nRun available_dates() to see which dates are available.")
    # nolint end
  }

  if (!is.null(date) && !is.null(r_ver)) {
    stop("Provide either an R version or a date, not both.")
  }

  if (is.null(date) && r_ver == "latest") {
    stop("'latest' was deprecated in favour of 'latest-upstream' as of version 0.14.0.")
  }

  if (
    !(message_type %in% c("simple", "quiet")) &&
      r_ver %in% c("bleeding-edge", "frozen-edge", "r-devel", "bioc-devel", "r-devel-bioc-devel")
  ) {
    warning(
      "You chose 'bleeding-edge', 'frozen-edge', 'r-devel', 'bioc-devel' or 'r-devel-bioc-devel'
as the value for `r_ver`. Please read the vignette
https://docs.ropensci.org/rix/articles/z-bleeding-edge.html
before continuing."
    )
  }

  if (
    identical(ide, "rstudio") && is.null(r_pkgs) && is.null(git_pkgs) &&
      is.null(local_r_pkgs)
  ) {
    stop(
      paste0(
        "You chose 'rstudio' as the IDE, but didn't add any R packages",
        " to the environment.\nThis expression will not build successfully. ",
        "Consider adding R packages."
      )
    )
  }

  # Wrapper attributes to be used later
  attrib <- c(
    radian = "radianWrapper",
    rstudio = "rstudioWrapper",
    rserver = "rstudioServerWrapper"
  )

  if (
    message_type != "quiet" && Sys.info()["sysname"] == "Darwin" &&
      ide == "rstudio"
  ) {
    warning(
      "Your detected operating system is macOS, and you chose
'rstudio' as the IDE. Please note that 'rstudio' is not
available through 'nixpkgs' for macOS, so the expression you
generated will not build on macOS. If you wish to build this
expression on macOS, change the 'ide =' argument to either
'code' or 'none'. Please refer to the macOS-specific vignette
https://docs.ropensci.org/rix/articles/b2-setting-up-and-using-rix-on-macos.html
for more details."
    )
  }

  if (isFALSE(dir.exists(project_path))) {
    dir.create(path = project_path, recursive = TRUE)
    project_path <- normalizePath(path = project_path)
  }

  # nolint start: object_name_linter
  default.nix_path <- file.path(project_path, "default.nix")
  .Rprofile_path <- file.path(project_path, ".Rprofile")
  # nolint end

  # Find url to use
  # In all cases but 'latest-upstream', the rstats-on-nix/nixpkgs
  # fork is used. Otherwise, upstream NixOS/nixpkgs
  nix_repo <- make_nixpkgs_url(r_ver, date)

  rix_call <- match.call()

  # Get the two lists. One list is current CRAN packages
  # the other is archived CRAN packages.
  cran_pkgs <- get_rpkgs(r_pkgs, ide)

  # If there are R packages, passes the string "rpkgs" to buildInputs
  flag_rpkgs <- if (
    is.null(cran_pkgs$rPackages) || cran_pkgs$rPackages == ""
  ) {
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
  flag_git_archive <- if (
    !is.null(git_pkgs) || !is.null(cran_pkgs$archive_pkgs)
  ) {
    # If git_pkgs is a list of lists, then sapply will succeed
    # if not, then we can access "package_name" directly
    git_pkgs_names <- if (!is.null(git_pkgs)) {
      tryCatch(
        sapply(git_pkgs, function(x) x$package_name),
        error = function(e) git_pkgs$package_name
      )
    }
    # CRAN archive pkgs are written as "AER@123"
    # so we need to split at the '@' character and then
    # walk through the list to grab the first element
    # which will be the name of the package
    cran_archive_names <- if (!is.null(cran_pkgs$archive_pkgs)) {
      pkgs <- strsplit(cran_pkgs$archive_pkgs, split = "@")
      sapply(pkgs, function(x) x[[1]])
    }

    paste0(c(git_pkgs_names, cran_archive_names), collapse = " ")
  } else {
    ""
  }

  # If there are R packages local packages, passes the string "local_r_pkgs" to buildInputs
  flag_local_r_pkgs <- if (is.null(local_r_pkgs)) {
    ""
  } else {
    "local_r_pkgs"
  }

  # If there are wrapped packages (for example for RStudio), passes the "wrapped_pkgs"
  # to buildInputs
  flag_wrapper <- if (ide %in% names(attrib) && flag_rpkgs != "") "wrapped_pkgs" else ""

  # Correctly formats shellHook for Nix's mkShell
  shell_hook <- if (!is.null(shell_hook) && nzchar(shell_hook)) {
    paste0('shellHook = "', shell_hook, '";')
  } else {
    ""
  }

  default.nix <- paste(
    generate_header(
      nix_repo,
      r_ver,
      rix_call,
      ide
    ),
    generate_rpkgs(cran_pkgs$rPackages, flag_rpkgs),
    generate_git_archived_pkgs(git_pkgs, cran_pkgs$archive_pkgs, flag_git_archive),
    generate_tex_pkgs(tex_pkgs),
    generate_local_r_pkgs(local_r_pkgs, flag_local_r_pkgs),
    generate_system_pkgs(system_pkgs, r_pkgs, ide),
    generate_wrapped_pkgs(ide, attrib, flag_git_archive, flag_rpkgs, flag_local_r_pkgs),
    generate_shell(
      flag_git_archive, flag_rpkgs, flag_tex_pkgs,
      flag_local_r_pkgs, flag_wrapper, shell_hook
    ),
    collapse = "\n"
  )

  # Generate default.nix file # nolint next: object_name_linter

  default.nix <- strsplit(default.nix, split = "\n")[[1]]

  # Remove potential duplicates
  default.nix <- post_processing(default.nix, flag_git_archive, skip_post_processing)

  if (print) {
    print(default.nix)
  }

  if (!file.exists(default.nix_path) || overwrite) {
    if (!dir.exists(project_path)) {
      dir.create(project_path, recursive = TRUE)
    }
    con <- file(default.nix_path, open = "wb", encoding = "native.enc")
    on.exit(close(con))


    writeLines(enc2utf8(default.nix), con = con, useBytes = TRUE)

    if (file.exists(.Rprofile_path)) {
      if (!any(grepl(
        "File generated by `rix::rix_init()",
        readLines(.Rprofile_path)
      ))) {
        if (message_type != "quiet" && identical(Sys.getenv("TESTTHAT"), "false")) {
          message("\n\n### Successfully generated `default.nix` ###\n\n")
        }
        warning(
          "\n\n### .Rprofile file already exists. ",
          "You may want to call rix_init(rprofile_action = 'append') manually ",
          "to ensure correct functioning of your Nix environment. ###\n\n"
        )
      } else {
        if (message_type != "quiet"  && identical(Sys.getenv("TESTTHAT"), "false")) {
          message(
            sprintf(
              "\n\n### Successfully generated `default.nix` in %s. ",
              normalizePath(project_path)
            ),
            "Keeping `.Rprofile` generated by `rix::rix_init()`###\n\n"
          )
        }
      }
    } else if (!file.exists(.Rprofile_path)) {
      rix_init(
        project_path = project_path,
        rprofile_action = "create_missing",
        # 'verbose' is too chatty for rix()
        # hence why it's transformed to "simple"
        message_type = ifelse(message_type == "verbose",
          "simple", message_type
        )
      )

      if (message_type != "quiet" && identical(Sys.getenv("TESTTHAT"), "false")) {
        message("\n\n### Successfully generated `default.nix` and `.Rprofile` ###\n\n")
      }
    }
  } else {
    project_path <- if (project_path == ".") {
      "current folder"
    } else {
      project_path
    }
    stop(
      paste0(
        "`default.nix` exists in ", project_path,
        ". Set `overwrite == TRUE` to overwrite."
      )
    )
  }

  on.exit(close(con))


}


#' @noRd
post_processing <- function(default.nix, flag_git_archive, skip_post_processing){

  # Remove potential duplicates
  do_processing <- if (flag_git_archive == "") {
                     FALSE
                   } else {
                     TRUE
                   }

  # only do post processing if there are git packages
  # or if skip_post_processing is TRUE
  if (all(c(do_processing, !skip_post_processing))){
    out <- remove_duplicate_entries(default.nix) |>
      remove_empty_lines()
  } else {
    out <-default.nix
  }

  out
}
