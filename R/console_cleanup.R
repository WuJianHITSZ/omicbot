console_cleanup <- function() {
  if (!rstudioapi::isAvailable()) {
    return(invisible(FALSE))
  }
  if (!isTRUE(getOption("omicbot.clear_input", TRUE))) {
    return(invisible(FALSE))
  }

  ctx <- rstudioapi::getConsoleEditorContext()
  has_console_input <- nzchar(trimws(ctx$contents %||% ""))
  if (!has_console_input) {
    return(invisible(FALSE))
  }

  selection_text_raw <- paste(vapply(ctx$selection, `[[`, character(1), "text"), collapse = "\n")
  has_selection <- nzchar(trimws(selection_text_raw))
  ranges <- NULL

  if (has_selection) {
    ranges <- lapply(ctx$selection, `[[`, "range")
  } else {
    lines <- strsplit(ctx$contents, "\n", fixed = TRUE)[[1]]
    if (!length(lines)) {
      lines <- ""
    }
    end_row <- length(lines)
    end_col <- nchar(lines[[end_row]], type = "chars") + 1L
    ranges <- list(
      rstudioapi::document_range(
        rstudioapi::document_position(1L, 1L),
        rstudioapi::document_position(end_row, end_col)
      )
    )
  }

  tryCatch(
    {
      for (range in rev(ranges)) {
        rstudioapi::modifyRange(location = range, text = "", id = ctx$id)
      }
      invisible(TRUE)
    },
    error = function(e) invisible(FALSE)
  )
}
