get_deps <- function(path){
  tmp_dir <- tempdir()
  untar(path, exdir = tmp_dir)

  paths <- list.files(tmp_dir, full.names = TRUE, recursive = TRUE)
  desc_path <- grep("DESCRIPTION", paths, value = TRUE)

  imports <- as.data.frame(read.dcf(desc_path))$Imports

  on.exit(unlink(tmp_dir, recursive = TRUE))

  trimws(unlist(strsplit(imports, split = ",")))
}
