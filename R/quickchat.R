quickchat <- function() {
  routed <- prompt_router()
  text <- routed$text
  from_clipboard <- isTRUE(routed$from_clipboard)
  read_console_input <- isTRUE(routed$read_console_input)

  if (!nzchar(text)) {
    return(invisible())
  }

  if (!read_console_input) {
    tryCatch(
      console_cleanup(),
      error = function(e) FALSE
    )
  }

  prompt_input <- text
  if (identical(text, "??")) {
    prompt_input <- getOption("omicbot.last_error")
    if (is.null(prompt_input) || !nzchar(prompt_input)) {
      cli::cli_alert_info("No captured error.")
      return(invisible())
    }
  }

  if (from_clipboard || !read_console_input) {
    cli::cli_text(">> ", prompt_input, "\n", sep = "")
  }
  .omicbot_run_prompt(prompt_input)
  invisible()
}

.omicbot_get_agent <- function() {
  agent <- getOption("omicbot.agent")
  if (!is.null(agent)) {
    return(agent)
  }
  if (exists("agent", envir = .GlobalEnv, inherits = FALSE)) {
    return(get("agent", envir = .GlobalEnv, inherits = FALSE))
  }
  cli::cli_abort(
    "No agent found. Set `options(omicbot.agent = <agent>)` or define `agent` in .GlobalEnv."
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

.omicbot_read_clipboard <- function() {
  pbpaste <- Sys.which("pbpaste")
  if (!nzchar(pbpaste)) {
    return(NULL)
  }
  out <- tryCatch(system2(pbpaste, stdout = TRUE, stderr = FALSE), error = function(e) NULL)
  if (is.null(out)) {
    return(NULL)
  }
  text <- paste(out, collapse = "\n")
  text <- trimws(text)
  if (!nzchar(text)) {
    return(NULL)
  }
  text
}

.omicbot_clear_clipboard <- function() {
  pbcopy <- Sys.which("pbcopy")
  if (!nzchar(pbcopy)) {
    return(invisible(FALSE))
  }
  ok <- tryCatch(
    {
      con <- pipe(pbcopy, open = "w")
      on.exit(close(con), add = TRUE)
      writeLines("", con)
      TRUE
    },
    error = function(e) FALSE
  )
  invisible(ok)
}

.omicbot_run_prompt <- function(user_text) {
  agent <- .omicbot_get_agent()

  model <- NULL
  if (!is.null(agent$model)) {
    model <- agent$model
  } else if (is.function(agent$get_model)) {
    model <- agent$get_model()
  }
  chat_fn <- agent$chat
  args <- list(user_text)
  echo_supported <- is.function(chat_fn) && "echo" %in% names(formals(chat_fn))
  config <- .omicbot_read_config(.omicbot_config_paths()$path)
  streaming <- config$streaming
  if (echo_supported) {
    if (identical(streaming, "enabled")) {
      args$echo <- "output"
    } else {
      args$echo <- "none"
    }
  }
  busy_msg <- "…waiting for response"
  cat(busy_msg, "\r", sep = "")
  flush.console()
  ret <- do.call(chat_fn, args)
  cat(strrep(" ", nchar(busy_msg, type = "chars")), "\r", sep = "")
  if ((!echo_supported || !identical(streaming, "enabled")) &&
      !is.null(ret) && is.character(ret) && length(ret) == 1 && nzchar(ret)) {
    cat(ret, "\n", sep = "")
  }
  if (!is.null(ret) && is.character(ret) && length(ret) == 1 && nzchar(ret)) {
    options(omicbot.last_output = ret)
  }
  invisible(ret)
}
