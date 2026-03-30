.omicbot_enable_error_capture <- function() {
  old_handler <- getOption("error")
  options(error = function() {
    err <- geterrmessage()
    options(omicbot.last_error = err)
    if (is.function(old_handler)) {
      old_handler()
    }
  })
  invisible(TRUE)
}

.omicbot_startup <- function(force_config = FALSE,
                             success_message = "Omicbot has successfully started.") {
  library(ellmer)

  # Load system prompt for the agent
  prompt_path <- system.file("exdata", "prompt.md", package = "omicbot")
  if (!nzchar(prompt_path)) {
    prompt_path <- file.path(getwd(), "inst", "exdata", "prompt.md")
  }
  if (!file.exists(prompt_path)) {
    cli::cli_abort("Cannot find prompt file at {.file {prompt_path}}.")
  }
  prompt <- readLines(prompt_path, warn = FALSE)
  prompt <- paste(prompt, collapse = "\n")

  # Resolve config paths for storing provider/model
  config_paths <- .omicbot_config_paths()
  config_dir <- config_paths$dir
  config_json_path <- config_paths$path

  config <- .omicbot_select_provider_model(
    config_path = config_json_path,
    config_dir = config_dir,
    force = force_config
  )
  provider <- config$provider
  model <- config$model
  wakeword <- config$wakeword

  # Ensure API key exists for the chosen provider
  env_path <- .omicbot_env_path(config_json_path)
  env_var <- .omicbot_ensure_api_key(provider, env_path)

  # Initialize the agent without passing the key explicitly
  agent <- .omicbot_init_agent(provider = provider, model = model, prompt = prompt)
  agent <- tryCatch(
    {
      tools <- omicbot_tools()
      if (exists("omicbot_databot_tools", mode = "function")) {
        tools <- c(tools, omicbot_databot_tools())
      }
      if (exists("omicbot_git_tools", mode = "function")) {
        tools <- c(tools, omicbot_git_tools())
      }
      .omicbot_attach_tools(agent, tools)
    },
    error = function(e) {
      cli::cli_warn(
        "Failed to attach tools ({conditionMessage(e)}). Continuing without tools."
      )
      agent
    }
  )

  options(omicbot.agent = agent)

  if (identical(wakeword, "enabled")) {
    tryCatch(
      {
        if (exists("hi", envir = .GlobalEnv, inherits = FALSE)) {
          rm(list = "hi", envir = .GlobalEnv)
        }
        makeActiveBinding("hi", function() quickchat(), .GlobalEnv)
      },
      error = function(e) invisible(FALSE)
    )
    .omicbot_enable_error_capture()
  }

  # Sanity check: ensure the agent can respond
  cli::cli_alert_info("Trying to connect with {provider}...")
  test_ok <- TRUE
  test_error <- NULL
  tryCatch(
    {
      invisible(agent$chat("Reply with OK."))
    },
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("does not support tools", msg, ignore.case = TRUE)) {
        agent <<- .omicbot_clear_tools(agent)
        retry_ok <- TRUE
        retry_err <- NULL
        tryCatch(
          {
            invisible(agent$chat("Reply with OK."))
          },
          error = function(e2) {
            retry_ok <<- FALSE
            retry_err <<- e2
          }
        )
        if (retry_ok) {
          cli::cli_warn("Model does not support tools; continuing without tools.")
          options(omicbot.agent = agent)
          return(invisible(NULL))
        }
        test_ok <<- FALSE
        test_error <<- retry_err
      } else {
        test_ok <<- FALSE
        test_error <<- e
      }
    }
  )

  if (!test_ok) {
    # On auth failure, erase the stored key to force re-entry next time
    if (file.exists(env_path)) {
      .omicbot_erase_api_key(env_path, env_var)
    }
    cli::cli_abort(c(
      "omicbot startup test failed: {conditionMessage(test_error)}",
      "i" = "{env_var} has been erased from {.file {env_path}}."
    ))
  }

  # Success message
  cli::cli_alert_success("{success_message}")
  config <- .omicbot_read_config(.omicbot_config_paths()$path)
  version_info <- .omicbot_get_version_info()
  model_line <- "model: <unset>"
  emoji <- '(>_<)/"'
  if (!is.null(config$provider) && nzchar(config$provider) &&
      !is.null(config$model) && nzchar(config$model)) {
    model_line <- paste0("model: ", config$provider, "/", config$model)
  }
  cli::cat_boxx(c(
    paste0("Welcome to OMICBOT (", version_info,")"),
    model_line,
    paste0("run ", cli::col_blue("settings()"), " for help.")
  ))
}

quickstart <- function(){
  .omicbot_startup()
}

.omicbot_get_version_info <- function() {
  pkg_desc <- tryCatch(utils::packageDescription("omicbot"), error = function(e) NULL)
  if (!is.null(pkg_desc) && !is.null(pkg_desc$Version) && nzchar(pkg_desc$Version)) {
    return(pkg_desc$Version)
  }
  local_desc <- file.path(getwd(), "DESCRIPTION")
  if (file.exists(local_desc)) {
    desc <- tryCatch(read.dcf(local_desc), error = function(e) NULL)
    if (!is.null(desc) && "Version" %in% colnames(desc)) {
      ver <- desc[1, "Version"]
      if (!is.na(ver) && nzchar(ver)) return(ver)
    }
  }
  "unknown"
}
