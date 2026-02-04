shortcut <- function() {
  path <- "/Users/jianwu/.config/rstudio/keybindings/addins.json"
  if (!file.exists(path)) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    data <- list()
  } else {
    raw <- readLines(path, warn = FALSE)
    raw_text <- paste(raw, collapse = "\n")
    data <- tryCatch(jsonlite::fromJSON(raw_text), error = function(e) list())
    if (!is.list(data)) data <- list()
  }

  has_omicbot <- any(grepl("^omicbot", names(data)))
  if (!has_omicbot) {
    data[["omicbot::quickchat"]] <- "Ctrl+Enter"
    jsonlite::write_json(data, path, auto_unbox = TRUE, pretty = TRUE)
  }

  invisible(data)
}
