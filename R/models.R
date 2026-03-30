.omicbot_provider_options <- function() {
  c("openai", "google", "deepseek", "alibaba", "ollama")
}

.omicbot_config_paths <- function() {
  rstudio_config_home <- Sys.getenv("RSTUDIO_CONFIG_HOME", "")
  if (rstudio_config_home == "") {
    xdg_config_home <- Sys.getenv(
      "XDG_CONFIG_HOME",
      file.path(path.expand("~"), ".config")
    )
    rstudio_config_home <- file.path(xdg_config_home, "rstudio")
  }
  config_dir <- file.path(rstudio_config_home, "omicbot")
  list(
    dir = config_dir,
    path = file.path(config_dir, "config.json")
  )
}

.omicbot_read_config <- function(config_path) {
  if (!file.exists(config_path)) {
    return(list(
      provider = NULL,
      model = NULL,
      streaming = "disabled",
      wakeword = "disabled"
    ))
  }
  config <- jsonlite::read_json(config_path, simplifyVector = TRUE)
  streaming <- config$streaming
  if (is.null(streaming) || !nzchar(streaming)) streaming <- "disabled"
  wakeword <- config$wakeword
  if (is.null(wakeword) || !nzchar(wakeword)) wakeword <- "disabled"
  list(
    provider = config$provider,
    model = config$model,
    streaming = streaming,
    wakeword = wakeword
  )
}

.omicbot_write_config <- function(config_path, config_dir, provider, model,
                                  streaming = "disabled", wakeword = "disabled") {
  if (!dir.exists(config_dir)) dir.create(config_dir, recursive = TRUE)
  jsonlite::write_json(
    list(
      provider = provider,
      model = model,
      streaming = streaming,
      wakeword = wakeword
    ),
    config_path,
    auto_unbox = TRUE,
    pretty = TRUE
  )
}

.omicbot_model_options <- function(provider) {
  if (provider == "openai") {
    c("gpt-4o", "gpt-4.1", "gpt-4.1-mini")
  } else if (provider == "google") {
    c("gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.5-flash-lite")
  } else if (provider == "deepseek") {
    c("deepseek-chat", "deepseek-coder", "deepseek-reasoner")
  } else if (provider == "alibaba") {
    c("qwen3-max", "qwen3-235b-a22b", "qwen3-coder-plus")
  } else if (provider == "ollama") {
    .omicbot_ollama_models()
  } else {
    stop("Unsupported provider.")
  }
}

.omicbot_ollama_models <- function() {
  ollama_bin <- Sys.which("ollama")
  if (!nzchar(ollama_bin)) {
    return(character(0))
  }
  out <- tryCatch(
    system2(ollama_bin, "list", stdout = TRUE, stderr = FALSE),
    error = function(e) character(0)
  )
  if (!length(out)) {
    return(character(0))
  }
  out <- trimws(out)
  out <- out[nzchar(out)]
  if (!length(out)) {
    return(character(0))
  }
  # Skip header line if present and take first column as model name
  if (grepl("^NAME\\s+", out[1])) {
    out <- out[-1]
  }
  if (!length(out)) {
    return(character(0))
  }
  models <- sub("\\s+.*$", "", out)
  models <- models[nzchar(models)]
  if (!length(models)) {
    return(character(0))
  }
  models
}

.omicbot_prompt_choice <- function(options, label) {
  if (!length(options)) {
    stop(sprintf("No %s options available.", label))
  }
  cli::cli_alert_info("Choose {label}, press 0 to cancel:")
  numbered <- sprintf("%d) %s", seq_along(options), options)
  cli::cli_li(numbered)
  choice_idx <- as.integer(readline(cli::style_bold("Enter number: ")))
  if (is.na(choice_idx)) choice_idx <- 1L
  if (choice_idx < 1 || choice_idx > length(options)) {
    stop(sprintf("Invalid %s selection.", label))
  }
  options[choice_idx]
}

.omicbot_prompt_provider_model <- function() {
  provider <- .omicbot_prompt_choice(.omicbot_provider_options(), "provider")
  model <- .omicbot_prompt_choice(.omicbot_model_options(provider), "model")
  list(provider = provider, model = model)
}

.omicbot_select_provider_model <- function(config_path, config_dir, force = FALSE) {
  if (file.exists(config_path) && !force) {
    return(.omicbot_read_config(config_path))
  }

  selection <- .omicbot_prompt_provider_model()
  .omicbot_write_config(
    config_path = config_path,
    config_dir = config_dir,
    provider = selection$provider,
    model = selection$model,
    streaming = "disabled",
    wakeword = "disabled"
  )
  list(
    provider = selection$provider,
    model = selection$model,
    streaming = "disabled",
    wakeword = "disabled"
  )
}
