settings <- function() {
  config_paths <- .omicbot_config_paths()
  config_dir <- config_paths$dir
  config_path <- config_paths$path

  config <- .omicbot_read_config(config_path)
  provider <- config$provider
  model <- config$model
  streaming <- config$streaming
  wakeword <- config$wakeword

  provider_label <- if (is.null(provider) || !nzchar(provider)) {
    "provider"
  } else {
    sprintf("provider (%s)", provider)
  }
  model_label <- if (is.null(model) || !nzchar(model)) {
    "model"
  } else {
    sprintf("model (%s)", model)
  }
  streaming_label <- if (is.null(streaming) || !nzchar(streaming)) {
    "streaming"
  } else {
    display <- if (streaming == "enabled") "enabled" else "disabled"
    sprintf("streaming (%s)", display)
  }
  wakeword_label <- if (is.null(wakeword) || !nzchar(wakeword)) {
    "wakeword"
  } else {
    display <- if (wakeword == "enabled") "enabled" else "disabled"
    sprintf("wakeword (%s)", display)
  }

  menu_options <- c(
    provider_label,
    model_label,
    streaming_label,
    wakeword_label,
    "full reset",
    "help"
  )
  selection <- .omicbot_menu_choice(menu_options, "setting")

  if (selection == provider_label) {
    provider <- .omicbot_menu_choice(.omicbot_provider_options(), "provider")
    model <- .omicbot_menu_choice(.omicbot_model_options(provider), "model")
    .omicbot_write_config(
      config_path = config_path,
      config_dir = config_dir,
      provider = provider,
      model = model,
      streaming = streaming,
      wakeword = wakeword
    )
  } else if (selection == model_label) {
    if (is.null(provider) || !nzchar(provider)) {
      provider <- .omicbot_menu_choice(.omicbot_provider_options(), "provider")
    }
    model <- .omicbot_menu_choice(.omicbot_model_options(provider), "model")
    .omicbot_write_config(
      config_path = config_path,
      config_dir = config_dir,
      provider = provider,
      model = model,
      streaming = streaming,
      wakeword = wakeword
    )
  } else if (selection == streaming_label) {
    streaming_choice <- .omicbot_menu_choice(c("enable", "disable"), "streaming")
    streaming <- if (streaming_choice == "enable") "enabled" else "disabled"
    .omicbot_write_config(
      config_path = config_path,
      config_dir = config_dir,
      provider = provider,
      model = model,
      streaming = streaming,
      wakeword = wakeword
    )
  } else if (selection == wakeword_label) {
    wakeword_choice <- .omicbot_menu_choice(c("enable", "disable"), "wakeword")
    wakeword <- if (wakeword_choice == "enable") "enabled" else "disabled"
    .omicbot_write_config(
      config_path = config_path,
      config_dir = config_dir,
      provider = provider,
      model = model,
      streaming = streaming,
      wakeword = wakeword
    )
  } else if (selection == "full reset") {
    reset()
    return(invisible())
  } else if (selection == "help") {
    .omicbot_print_help()
    return(invisible())
  }

  .omicbot_startup(
    force_config = FALSE,
    success_message = "Settings have been successfully updated."
  )
}

.omicbot_menu_choice <- function(options, label) {
  if (!length(options)) {
    cli::cli_abort("No {label} options available.")
  }
  idx <- utils::menu(
    choices = options,
    title = sprintf("Choose %s, press 0 to cancel", label)
  )
  if (idx < 1 || idx > length(options)) {
    cli::cli_abort("No {label} selected.")
  }
  options[[idx]]
}

.omicbot_print_help <- function() {
  readme_path <- file.path(getwd(), "README.md")
  if (!file.exists(readme_path)) {
    cli::cli_alert_warning("README.md not found.")
    return(invisible(FALSE))
  }

  lines <- readLines(readme_path, warn = FALSE)
  if (!length(lines)) {
    cli::cli_alert_warning("README.md is empty.")
    return(invisible(FALSE))
  }

  help_start <- grep("^##\\s+Help\\s*$", lines)
  if (!length(help_start)) {
    .omicbot_render_help_lines(lines)
    return(invisible(TRUE))
  }

  start <- help_start[1]
  next_h2 <- grep("^##\\s+", lines)
  next_h2 <- next_h2[next_h2 > start]
  end <- if (length(next_h2)) next_h2[1] - 1L else length(lines)
  .omicbot_render_help_lines(lines[start:end])
  invisible(TRUE)
}

.omicbot_render_help_lines <- function(lines) {
  i <- 1L
  n <- length(lines)
  printed_any <- FALSE
  last_block_type <- NULL
  while (i <= n) {
    line <- trimws(lines[[i]])
    if (!nzchar(line)) {
      i <- i + 1L
      next
    }

    if (grepl("^##\\s+", line)) {
      if (printed_any) cat("\n")
      cli::cli_h1(sub("^##\\s+", "", line))
      printed_any <- TRUE
      last_block_type <- "h1"
      i <- i + 1L
      next
    }

    if (grepl("^###\\s+", line)) {
      if (printed_any && !identical(last_block_type, "h1")) cat("\n")
      cli::cli_h2(sub("^###\\s+", "", line))
      printed_any <- TRUE
      last_block_type <- "h3"
      i <- i + 1L
      next
    }

    if (grepl("^-\\s+", line)) {
      items <- character(0)
      while (i <= n && grepl("^-\\s+", trimws(lines[[i]]))) {
        items <- c(items, sub("^-\\s+", "", trimws(lines[[i]])))
        i <- i + 1L
      }
      cli::cli_li(items)
      printed_any <- TRUE
      last_block_type <- "list"
      next
    }

    cli::cli_text(line)
    printed_any <- TRUE
    last_block_type <- "text"
    i <- i + 1L
  }
}
