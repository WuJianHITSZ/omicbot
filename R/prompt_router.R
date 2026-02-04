.omicbot_read_console_input <- function() {
  if (!interactive()) {
    return("")
  }
  text <- tryCatch(readline(">> "), error = function(e) "")
  trimws(text %||% "")
}

prompt_router <- function() {
  text <- ""
  from_clipboard <- FALSE
  read_console_input <- FALSE
  clipboard_requested <- FALSE

  if (rstudioapi::isAvailable()) {
    text <- tryCatch(
      {
        ctx <- rstudioapi::getConsoleEditorContext()
        trimws(ctx$contents %||% "")
      },
      error = function(e) ""
    )
  }

  if (!nzchar(text)) {
    read_console_input <- TRUE
    text <- .omicbot_read_console_input()
  }

  if (identical(text, "!!")) {
    clipboard_requested <- TRUE
    text <- .omicbot_read_clipboard()
    text <- trimws(text %||% "")
    from_clipboard <- nzchar(text)
    if (nzchar(text) && isTRUE(getOption("omicbot.clear_clipboard", TRUE))) {
      .omicbot_clear_clipboard()
    }
  }

  if (clipboard_requested && !from_clipboard) {
    cli::cli_alert_info(
      "omicbot: console is empty and clipboard is empty; type a line or copy a prompt (Cmd+C) then press the shortcut."
    )
  }

  list(
    text = text,
    from_clipboard = from_clipboard,
    read_console_input = read_console_input
  )
}
