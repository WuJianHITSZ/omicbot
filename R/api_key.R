.omicbot_env_path <- function(config_path) {
  file.path(dirname(config_path), ".env")
}

.omicbot_api_key_var <- function(provider) {
  if (provider == "openai") {
    "OPENAI_API_KEY"
  } else if (provider == "google") {
    "GOOGLE_API_KEY"
  } else if (provider == "deepseek") {
    "DEEPSEEK_API_KEY"
  } else if (provider == "alibaba") {
    "DASHSCOPE_API_KEY"
  } else if (provider == "ollama") {
    NULL
  } else {
    stop("Unsupported provider.")
  }
}

.omicbot_read_api_key <- function(env_path, env_var) {
  if (!file.exists(env_path)) {
    return("")
  }
  env_lines <- readLines(env_path, warn = FALSE)
  key_pattern <- paste0("^", env_var, "=")
  key_line <- env_lines[grepl(key_pattern, env_lines)]
  if (!length(key_line)) {
    return("")
  }
  api_key <- sub(key_pattern, "", key_line[1])
  trimws(api_key)
}

.omicbot_write_api_key <- function(env_path, env_var, api_key) {
  env_line <- sprintf("%s=%s", env_var, api_key)
  if (file.exists(env_path)) {
    env_lines <- readLines(env_path, warn = FALSE)
    key_pattern <- paste0("^", env_var, "=.*$")
    if (any(grepl(key_pattern, env_lines))) {
      env_lines <- sub(key_pattern, env_line, env_lines)
    } else {
      env_lines <- c(env_lines, env_line)
    }
    writeLines(env_lines, env_path)
  } else {
    writeLines(env_line, env_path)
  }
}

.omicbot_erase_api_key <- function(env_path, env_var) {
  if (is.null(env_var) || !nzchar(env_var)) {
    return(invisible(FALSE))
  }
  if (!file.exists(env_path)) {
    return(invisible(FALSE))
  }
  env_lines <- readLines(env_path, warn = FALSE)
  key_pattern <- paste0("^", env_var, "=")
  if (!any(grepl(key_pattern, env_lines))) {
    return(invisible(FALSE))
  }
  env_lines <- env_lines[!grepl(key_pattern, env_lines)]
  writeLines(env_lines, env_path)
  invisible(TRUE)
}

.omicbot_ensure_api_key <- function(provider, env_path) {
  env_var <- .omicbot_api_key_var(provider)
  if (is.null(env_var) || !nzchar(env_var)) {
    return(NULL)
  }
  api_key <- .omicbot_read_api_key(env_path, env_var)

  if (api_key == "") {
    cli::cli_alert_info("Please enter {.field {env_var}}.")
    api_key <- getPass::getPass(sprintf("Enter %s: ", env_var))
    .omicbot_write_api_key(env_path, env_var, api_key)
  }

  readRenviron(env_path)
  env_var
}

.omicbot_openai_compatible_base_url <- function(provider) {
  if (provider != "alibaba") {
    return(NULL)
  }
  base_url <- Sys.getenv("DASHSCOPE_BASE_URL", "")
  if (nzchar(base_url)) {
    return(base_url)
  }
  "https://dashscope.aliyuncs.com/compatible-mode/v1"
}
