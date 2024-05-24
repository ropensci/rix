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



#' fetchgits Downloads and installs a packages hosted of Git. Wraps `fetchgit()` to handle multiple packages
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

