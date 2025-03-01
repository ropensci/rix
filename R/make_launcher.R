#' Create a startup script to launch an editor inside of a Nix shell
#' @param editor Character, the command to launch the editor. See the "Details" section below for more information.
#' @param project_path Character, where to write the launcher, for example
#'   "/home/path/to/project". The file will thus be written to the file
#'   "/home/path/to/project/start-editor.sh". If the folder does not exist, it will
#'   be created.
#'
#' @details This function will write a launcher to start an IDE inside of a
#'   Nix shell. With a launcher, you only need to execute it instead of first
#'   having to drop into the shell using `nix-shell` and then type the command
#'   to run the IDE. For security reasons, this script is not executable upon
#'   creation, so you need to make it executable first by running
#'   `chmod +x start-editor.sh` (replace `editor` with whichever editor you use).
#'   You don’t need this launcher if you use `direnv`;
#'   see `vignette("e-configuring-ide")` for more details.
#'
#' @return Nothing, writes a script.
#' @export
#'
#' @examples
#' available_dates()
make_launcher <- function(editor, project_path) {
  editor <- trimws(editor)

  stopifnot(
    "'editor' argument must be a single word" = grepl("^[A-Za-z]+$", editor)
  )

  if (isFALSE(dir.exists(project_path))) {
    dir.create(path = project_path, recursive = TRUE)
    project_path <- normalizePath(path = project_path)
  }

  script_text <- sprintf(
    "#!/usr/bin/env nix-shell\n#!nix-shell default.nix -i bash\n%s",
    editor
  )
  script_path <- file.path(project_path, paste0("start-", editor, ".sh"))
  writeLines(script_text, script_path)

  # Hide messages when testing
  if (identical(Sys.getenv("TESTTHAT"), "false")) {
    message("Wrote launcher successfully!")
  }

  if (identical(Sys.getenv("TESTTHAT"), "true")) {
    file.path(script_path)
  }
}
