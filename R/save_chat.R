# save_chat() / resume_chat() -----------------------------------------------
# Persist and restore agent sessions by UUID-named RDS files stored in the
# omicbot config directory (<config_dir>/chats/<uuid>.rds).

#' Generate a UUID v4 using base R
.omicbot_uuid <- function() {
  hex <- sprintf("%02x", sample(0:255, 16, replace = TRUE))
  # Set version bits: high nibble of byte 7 = 0100 (version 4)
  hex[7] <- sprintf("%02x", bitwOr(bitwAnd(strtoi(hex[7], 16L), 0x0F), 0x40))
  # Set variant bits: high 2 bits of byte 9 = 10 (RFC 4122)
  hex[9] <- sprintf("%02x", bitwOr(bitwAnd(strtoi(hex[9], 16L), 0x3F), 0x80))
  paste0(
    paste(hex[1:4],   collapse = ""), "-",
    paste(hex[5:6],   collapse = ""), "-",
    paste(hex[7:8],   collapse = ""), "-",
    paste(hex[9:10],  collapse = ""), "-",
    paste(hex[11:16], collapse = "")
  )
}

#' Save the current omicbot agent to the config directory
#'
#' Serializes the active agent (an \pkg{ellmer} `Chat` object, which carries
#' full conversation history and tool bindings) to an RDS file in the
#' `chats/` sub-directory of the omicbot config path.
#'
#' If the current session was started with \code{\link{resume_chat}}, you will
#' be asked whether to overwrite the existing file (reusing its UUID), save as
#' a new file (new UUID), or cancel.  For fresh sessions the file is always
#' saved with a new UUID.
#'
#' @return Invisibly returns the path to the saved file, or \code{NULL} if
#'   the user cancels.
#' @export
save_chat <- function() {
  agent <- .omicbot_get_agent()

  config_paths <- .omicbot_config_paths()
  chats_dir <- file.path(config_paths$dir, "chats")
  if (!dir.exists(chats_dir)) {
    dir.create(chats_dir, recursive = TRUE)
  }

  resume_uuid <- getOption("omicbot.resume_uuid")

  if (!is.null(resume_uuid)) {
    # Session was started via resume_chat() — ask what to do
    old_file <- paste0(resume_uuid, ".rds")
    choice <- utils::menu(
      choices = c(
        paste0("Update existing chat (", old_file, ")"),
        "Save as new chat (new UUID)",
        "Cancel"
      ),
      title = "This session was resumed from a saved chat. How would you like to save?"
    )

    if (choice == 0L || choice == 3L) {
      cli::cli_alert_info("Save cancelled.")
      return(invisible(NULL))
    }

    if (choice == 1L) {
      id <- resume_uuid
    } else {
      id <- .omicbot_uuid()
    }
  } else {
    id <- .omicbot_uuid()
  }

  out_path <- file.path(chats_dir, paste0(id, ".rds"))
  saveRDS(agent, out_path)

  # Update so future save_chat() calls know the current UUID
  options(omicbot.resume_uuid = id)

  cli::cli_alert_success("Chat saved to {.file {out_path}}")
  invisible(out_path)
}

#' Resume a previously saved omicbot chat session
#'
#' Loads an agent object saved by \code{\link{save_chat}} and restores it as
#' the active agent.  Use this in place of \code{quickstart()} when you want
#' to continue an earlier conversation.
#'
#' Tools are re-attached from the current package state so that any updates
#' since the file was written take effect.  The wakeword active binding is
#' also re-applied if enabled in \code{config.json}.
#'
#' @param uuid A UUID string returned by \code{save_chat()} (with or without
#'   the \code{.rds} extension), or a full file path to an RDS file.
#' @return Invisibly returns the restored agent.
#' @export
resume_chat <- function(uuid) {
  library(ellmer)

  # Resolve file path: accept a full path, a bare UUID, or UUID with .rds
  if (file.exists(uuid)) {
    rds_path <- uuid
    id <- sub("\\.rds$", "", basename(uuid))
  } else {
    id <- sub("\\.rds$", "", uuid)
    chats_dir <- file.path(.omicbot_config_paths()$dir, "chats")
    rds_path <- file.path(chats_dir, paste0(id, ".rds"))
  }

  if (!file.exists(rds_path)) {
    cli::cli_abort(c(
      "No saved chat found.",
      "x" = "Path checked: {.file {rds_path}}"
    ))
  }

  agent <- readRDS(rds_path)

  # Re-attach fresh tools from current package state (picks up any updates)
  agent <- tryCatch(
    {
      tools <- omicbot_tools()
      if (exists("omicbot_databot_tools", mode = "function")) {
        tools <- c(tools, omicbot_databot_tools())
      }
      if (exists("omicbot_git_tools", mode = "function")) {
        tools <- c(tools, omicbot_git_tools())
      }
      if (exists("omicbot_skill_tools", mode = "function")) {
        tools <- c(tools, omicbot_skill_tools())
      }
      .omicbot_attach_tools(agent, tools)
    },
    error = function(e) {
      cli::cli_warn(
        "Failed to re-attach tools ({conditionMessage(e)}). Continuing without tools."
      )
      agent
    }
  )

  options(omicbot.agent = agent)

  if (exists("load_skills", mode = "function")) {
    tryCatch(
      load_skills(agent = agent),
      error = function(e) {
        cli::cli_warn("Failed to load skills ({conditionMessage(e)}).")
      }
    )
  }

  # Load config and ensure the API key is in the environment.
  # After a session restart the .env file exists but has not been sourced yet,
  # so readRenviron() must be called before the connection test.
  config <- .omicbot_read_config(.omicbot_config_paths()$path)
  env_path <- .omicbot_env_path(.omicbot_config_paths()$path)
  .omicbot_ensure_api_key(config$provider, env_path)

  # Re-apply wakeword binding if enabled in config.json
  if (identical(config$wakeword, "enabled")) {
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

  # Connection test — mirrors quickstart() behaviour
  cli::cli_alert_info("Resuming chat, testing connection...")
  test_ok <- TRUE
  test_error <- NULL
  tryCatch(
    invisible(agent$chat("Reply with OK.")),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("does not support tools", msg, ignore.case = TRUE)) {
        agent <<- .omicbot_clear_tools(agent)
        retry_ok <- TRUE
        retry_err <- NULL
        tryCatch(
          invisible(agent$chat("Reply with OK.")),
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
    cli::cli_abort("resume_chat connection test failed: {conditionMessage(test_error)}")
  }

  # Welcome banner
  version_info <- .omicbot_get_version_info()
  model_line <- "model: <unset>"
  if (!is.null(config$provider) && nzchar(config$provider) &&
      !is.null(config$model) && nzchar(config$model)) {
    model_line <- paste0("model: ", config$provider, "/", config$model)
  }
  cli::cat_boxx(c(
    paste0("Welcome back to OMICBOT (", version_info, ")"),
    model_line,
    paste0("resumed from: ", cli::col_blue(basename(rds_path)))
  ))

  # Record the source UUID so save_chat() can offer update vs. new
  options(omicbot.resume_uuid = id)

  invisible(agent)
}
