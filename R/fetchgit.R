#' fetchgit Downloads and installs a package hosted of Git
#' @param git_pkg A list of four elements: "package_name", the name of the package, "repo_url", the repository's url, "branch_name", the name of the branch containing the code to download and "commit", the commit hash of interest. 
#' @return A character. The Nix definition to download and build the R package from Github.
#' @noRd
fetchgit <- function(git_pkg){

  package_name <- git_pkg$package_name
  repo_url <- git_pkg$repo_url
  branch_name <- git_pkg$branch_name
  commit <- git_pkg$commit

  output <- get_sri_hash_deps(repo_url, branch_name, commit)
  sri_hash <- output$sri_hash
  imports <- output$deps

  sprintf('
   (pkgs.rPackages.buildRPackage {
     name = \"%s\";
     src = pkgs.fetchgit {
       url = \"%s\";
       branchName = \"%s\";
       rev = \"%s\";
       sha256 = \"%s\";
     };
     propagatedBuildInputs = builtins.attrValues {
       inherit (pkgs.rPackages) %s;
     };
   })
',
  package_name,
  repo_url,
  branch_name,
  commit,
  sri_hash,
  imports
)

}


#' fetchzip Downloads and installs an archived CRAN package
#' @param archive_pkg A character of the form "dplyr@0.80"
#' @return A character. The Nix definition to download and build the R package from CRAN.
#' @noRd
fetchzip <- function(archive_pkg, sri_hash = NULL){

  pkgs <- unlist(strsplit(archive_pkg, split = "@"))

  cran_archive_link <- paste0(
    "https://cran.r-project.org/src/contrib/Archive/",
    pkgs[1], "/",
    paste0(pkgs[1], "_", pkgs[2]),
    ".tar.gz")

  package_name <- pkgs[1]
  repo_url <- cran_archive_link

  if(is.null(sri_hash)){
    output <- get_sri_hash_deps(repo_url, branch_name = NULL, commit = NULL)
    sri_hash <- output$sri_hash
    imports <- output$deps
  } else {
    sri_hash <- sri_hash
    imports <- NULL
  }

  sprintf('
  (pkgs.rPackages.buildRPackage {
    name = \"%s\";
    src = pkgs.fetchzip {
     url = \"%s\";
     sha256 = \"%s\";
    };
    propagatedBuildInputs = builtins.attrValues {
     inherit (pkgs.rPackages) %s;
    };
  })
',
  package_name,
  repo_url,
  sri_hash,
  imports
)
}


#' Removes base packages from list of packages dependencies
#' @param list_imports Atomic vector of packages
#' @importFrom stats na.omit
#' @return Atomic vector of packages without base packages
#' @noRd
remove_base <- function(list_imports){

  gsub("(^base$)|(^compiler$)|(^datasets$)|(^grDevices$)|(^graphics$)|(^grid$)|(^methods$)|(^parallel$)|(^profile$)|(^splines$)|(^stats$)|(^stats4$)|(^tcltk$)|(^tools$)|(^translations$)|(^utils$)",
       NA_character_,
       list_imports) |>
    na.omit()  |>
    paste(collapse = " ")

}

#' finds dependencies of a package
#' @param path path to package
#' @return Atomic vector of packages
#' @importFrom desc description
#' @noRd
get_imports <- function(path){

  output <- desc::description$new(path)$get_deps() |>
              subset(type %in% c("Depends", "Imports", "LinkingTo")) |>
              subset(package != "R")

  output <- output$package

  output <- remove_base(unique(output))

  gsub('\\.', '_', output)
}


#' fetchlocal Installs a local R package
#' @param local_pkg A list of local package names ('.tar.gz' archives) to install. These packages need to be in the same folder as the generated `default.nix` file.
#' @importFrom utils tail
#' @return A character. The Nix definition to build the R package from local sources.
#' @noRd
fetchlocal <- function(local_pkg){

  its_imports <- get_imports(local_pkg)

  # Remove package version from name
  package_name <- unlist(strsplit(local_pkg, split = "_"))

  package_name <- package_name[1]

  # Remove rest of path from name
  package_name <- unlist(strsplit(package_name, split = "/")) |> tail(1)

  sprintf('
  (pkgs.rPackages.buildRPackage {
    name = \"%s\";
    src = ./%s;
    propagatedBuildInputs = builtins.attrValues {
     inherit (pkgs.rPackages) %s;
    };
  })
',
package_name,
local_pkg,
its_imports
)
}

#' fetchlocals Installs a local R package
#' @param local_pkgs Either a list of paths to local packages, or a path to a single package
#' @return A character. The Nix definition to build the local R packages from local sources.
#' @noRd
fetchlocals <- function(local_pkgs){

  paths_exist <- file.exists(local_pkgs)

  if(!all(paths_exist)){
    stop(
      paste0("local_pkgs: The following paths are incorrect:\n",
             paste(local_pkgs[!paths_exist], collapse = "\n")
            )
         )
  } else if(length(local_pkgs) == 1){
    fetchlocal(local_pkgs)
  } else {
    paste(lapply(local_pkgs, fetchlocal), collapse = "\n")
  }

}



#' fetchgits Downloads and installs packages hosted on Git. Wraps `fetchgit()` to handle multiple packages
#' @param git_pkgs A list of four elements: "package_name", the name of the package, "repo_url", the repository's url, "branch_name", the name of the branch containing the code to download and "commit", the commit hash of interest. This argument can also be a list of lists of these four elements.
#' @return A character. The Nix definition to download and build the R package from Github.
#' @noRd
fetchgits <- function(git_pkgs){

  if(!all(vapply(git_pkgs, is.list, logical(1)))){
    fetchgit(git_pkgs)
  } else if(all(vapply(git_pkgs, is.list, logical(1)))){
    paste(lapply(git_pkgs, fetchgit), collapse = "\n")
  } else {
    stop("There is something wrong with the input. Make sure it is either a list of four elements 'package_name', 'repo_url', 'branch_name' and 'commit' or a list of lists with these four elements")
  }

}

#' fetchzips Downloads and installs packages hosted in the CRAN archives. Wraps `fetchzip()` to handle multiple packages.
#' @param archive_pkgs A character, or an atomic vector of characters.
#' @return A character. The Nix definition to download and build the R package from the CRAN archives.
#' @noRd
fetchzips <- function(archive_pkgs){

  if(is.null(archive_pkgs)){
    "" #Empty character in case the user doesn't need any packages from the CRAN archives.
  } else if(length(archive_pkgs) == 1){
    fetchzip(archive_pkgs)
  } else if(length(archive_pkgs) > 1){
    paste(lapply(archive_pkgs, fetchzip), collapse = "\n")
  } else {
    stop("There is something wrong with the input. Make sure it is either a single package name, or an atomic vector of package names, for example c('dplyr@0.8.0', 'tidyr@1.0.0').")
  }

}

#' fetchpkgs Downloads and installs packages hosted in the CRAN archives or Github.
#' @param git_pkgs A list of four elements: "package_name", the name of the package, "repo_url", the repository's url, "branch_name", the name of the branch containing the code to download and "commit", the commit hash of interest. This argument can also be a list of lists of these four elements.
#' @param archive_pkgs A character, or an atomic vector of characters.
#' @return A character. The Nix definition to download and build the R package from the CRAN archives.
#' @noRd
fetchpkgs  <- function(git_pkgs, archive_pkgs){
  paste(fetchgits(git_pkgs),
        fetchzips(archive_pkgs),
        collapse = "\n")
}

