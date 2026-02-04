.omicbot_tool_read_file <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("File not found: %s", path))
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

.omicbot_guardrail_confirm <- function(action, target = "", details = "") {
  if (!isTRUE(getOption("omicbot.guardrail", TRUE))) {
    return(list(approved = TRUE, message = "Guardrail bypassed by option."))
  }
  if (!interactive()) {
    return(list(approved = FALSE, message = "Rejected: non-interactive session."))
  }

  cli::cli_h2("Approval Request")
  cli::cli_text("{.strong Action}: {action}")
  if (nzchar(target)) cli::cli_text("{.strong Target}: {target}")
  if (nzchar(details)) cli::cli_text("{.strong Details}: {details}")

  choice <- utils::menu(
    choices = c("Approve", "Reject"),
    title = "Allow this operation? (0 = Reject)"
  )
  if (choice != 1L) {
    return(list(approved = FALSE, message = "Rejected by user."))
  }
  list(approved = TRUE, message = "Approved by user.")
}

.omicbot_tool_write_file <- function(path, content, append = FALSE) {
  gate <- .omicbot_guardrail_confirm(
    action = if (isTRUE(append)) "append_file" else "write_file",
    target = path
  )
  if (!gate$approved) return(gate$message)

  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  if (append) {
    cat(content, file = path, sep = "\n", append = TRUE)
    cat("\n", file = path, append = TRUE)
  } else {
    writeLines(content, path, sep = "\n", useBytes = TRUE)
  }
  sprintf("Wrote %d characters to %s", nchar(content, type = "chars"), path)
}

.omicbot_tool_list_files <- function(path = ".", recursive = FALSE) {
  if (!dir.exists(path)) {
    stop(sprintf("Directory not found: %s", path))
  }
  list.files(path, recursive = recursive, all.files = FALSE, no.. = TRUE)
}

.omicbot_tool_search_files <- function(pattern, path = ".", ignore_case = FALSE) {
  if (!dir.exists(path)) {
    stop(sprintf("Directory not found: %s", path))
  }
  rg <- Sys.which("rg")
  if (nzchar(rg)) {
    args <- c(pattern, path, "--no-heading", "--line-number")
    if (ignore_case) args <- c(args, "-i")
    out <- tryCatch(system2(rg, args, stdout = TRUE, stderr = TRUE), error = function(e) character(0))
    return(out)
  }
  files <- list.files(path, recursive = TRUE, full.names = TRUE)
  hits <- character(0)
  for (file in files) {
    if (dir.exists(file)) next
    lines <- tryCatch(readLines(file, warn = FALSE), error = function(e) NULL)
    if (is.null(lines)) next
    idx <- if (ignore_case) {
      grep(pattern, lines, ignore.case = TRUE)
    } else {
      grep(pattern, lines)
    }
    if (length(idx)) {
      for (i in idx) {
        hits <- c(hits, sprintf("%s:%d:%s", file, i, lines[[i]]))
      }
    }
  }
  hits
}

.omicbot_tool_run_shell <- function(command) {
  gate <- .omicbot_guardrail_confirm(
    action = "run_shell",
    target = "system shell",
    details = command
  )
  if (!gate$approved) return(gate$message)

  out <- tryCatch(
    system(command, intern = TRUE, ignore.stderr = FALSE),
    error = function(e) e
  )
  if (inherits(out, "error")) {
    return(sprintf("Error: %s", conditionMessage(out)))
  }
  paste(out, collapse = "\n")
}

.omicbot_tool_apply_patch <- function(patch) {
  gate <- .omicbot_guardrail_confirm(
    action = "apply_patch",
    target = "local files"
  )
  if (!gate$approved) return(gate$message)

  patch_bin <- Sys.which("patch")
  if (!nzchar(patch_bin)) {
    stop("The 'patch' command is not available on this system.")
  }
  tmp <- tempfile(fileext = ".patch")
  writeLines(patch, tmp)
  out <- tryCatch(
    system2(patch_bin, c("-p0", "-i", tmp), stdout = TRUE, stderr = TRUE),
    error = function(e) e
  )
  if (inherits(out, "error")) {
    return(sprintf("Error: %s", conditionMessage(out)))
  }
  paste(out, collapse = "\n")
}

.omicbot_tool_patch_preview <- function(patch, max_lines = 80) {
  if (!nzchar(trimws(patch))) {
    return("No patch content provided.")
  }

  lines <- strsplit(patch, "\n", fixed = TRUE)[[1]]
  file_headers <- grep("^\\*\\*\\* (Update|Add|Delete) File: ", lines, value = TRUE)
  file_names <- sub("^\\*\\*\\* (Update|Add|Delete) File: ", "", file_headers)

  adds <- sum(grepl("^\\+", lines) & !grepl("^\\+\\+\\+", lines))
  dels <- sum(grepl("^-", lines) & !grepl("^---", lines))

  out <- character(0)
  out <- c(out, sprintf("Patch summary: %d file(s), +%d -%d", length(file_names), adds, dels))
  if (length(file_names)) {
    out <- c(out, "Files:")
    out <- c(out, paste0("- ", file_names))
  }
  out <- c(out, "", "Hunks (truncated):")

  keep <- grepl("^\\*\\*\\* (Update|Add|Delete) File: |^@@|^[ +-]", lines)
  body <- lines[keep]
  body <- body[body != "*** Begin Patch" & body != "*** End Patch"]

  max_lines <- suppressWarnings(as.integer(max_lines))
  if (is.na(max_lines) || max_lines <= 0) max_lines <- 80L
  if (length(body) > max_lines) {
    body <- c(body[seq_len(max_lines)], "... (truncated)")
  }

  paste(c(out, body), collapse = "\n")
}

.omicbot_tool_run_r <- function(code) {
  gate <- .omicbot_guardrail_confirm(
    action = "run_r",
    target = ".GlobalEnv",
    details = code
  )
  if (!gate$approved) return(gate$message)

  if (!nzchar(trimws(code))) {
    return("No R code provided.")
  }
  out <- tryCatch(
    {
      output <- capture.output({
        value <- eval(parse(text = code), envir = .GlobalEnv)
        if (!is.null(value)) print(value)
      })
      if (!length(output)) "R code executed successfully."
      else paste(output, collapse = "\n")
    },
    error = function(e) sprintf("Error: %s", conditionMessage(e))
  )
  out
}

.omicbot_tool_source_r <- function(path) {
  gate <- .omicbot_guardrail_confirm(
    action = "source_r",
    target = path
  )
  if (!gate$approved) return(gate$message)

  if (!file.exists(path)) {
    return(sprintf("Error: file not found: %s", path))
  }
  out <- tryCatch(
    {
      output <- capture.output(source(path, local = .GlobalEnv, echo = FALSE))
      if (!length(output)) sprintf("Sourced %s successfully.", path)
      else paste(output, collapse = "\n")
    },
    error = function(e) sprintf("Error: %s", conditionMessage(e))
  )
  out
}

omicbot_tools <- function() {
  list(
    ellmer::tool(
      .omicbot_tool_read_file,
      name = "read_file",
      description = "Read a UTF-8 text file and return its contents as a single string.",
      arguments = list(
        path = ellmer::type_string("Path to the file to read.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_write_file,
      name = "write_file",
      description = "Write text to a file, creating parent directories if needed.",
      arguments = list(
        path = ellmer::type_string("Path to the file to write."),
        content = ellmer::type_string("Text content to write."),
        append = ellmer::type_boolean("Append to the file instead of overwriting.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_list_files,
      name = "list_files",
      description = "List files in a directory.",
      arguments = list(
        path = ellmer::type_string("Directory path to list."),
        recursive = ellmer::type_boolean("Whether to list files recursively.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_search_files,
      name = "search_files",
      description = "Search for a pattern in files under a directory.",
      arguments = list(
        pattern = ellmer::type_string("Regex pattern to search for."),
        path = ellmer::type_string("Directory to search."),
        ignore_case = ellmer::type_boolean("Whether to ignore case in matching.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_run_shell,
      name = "shell",
      description = "Run a shell command and return combined output.",
      arguments = list(
        command = ellmer::type_string("Shell command to run.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_apply_patch,
      name = "apply_patch",
      description = "Apply a unified diff patch using the system 'patch' command.",
      arguments = list(
        patch = ellmer::type_string("Unified diff patch text to apply.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_patch_preview,
      name = "patch_preview",
      description = "Preview and summarize a patch with file-level and hunk-level changes without printing full file contents.",
      arguments = list(
        patch = ellmer::type_string("Unified diff patch text to preview."),
        max_lines = ellmer::type_string("Maximum number of hunk lines to show.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_run_r,
      name = "run_r",
      description = "Execute R code in the current session's global environment and return printed output.",
      arguments = list(
        code = ellmer::type_string("R code to execute in .GlobalEnv.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_source_r,
      name = "source_r",
      description = "Source an R script file into the current session's global environment.",
      arguments = list(
        path = ellmer::type_string("Path to the R script file to source.")
      )
    )
  )
}

.omicbot_attach_tools <- function(agent, tools) {
  if (is.function(agent$set_tools)) {
    agent$set_tools(tools)
    return(agent)
  }
  set_tools_fn <- tryCatch(get("set_tools", envir = asNamespace("ellmer")), error = function(e) NULL)
  if (is.function(set_tools_fn)) {
    return(set_tools_fn(agent, tools))
  }
  agent
}

.omicbot_clear_tools <- function(agent) {
  if (is.function(agent$set_tools)) {
    agent$set_tools(list())
    return(agent)
  }
  set_tools_fn <- tryCatch(get("set_tools", envir = asNamespace("ellmer")), error = function(e) NULL)
  if (is.function(set_tools_fn)) {
    return(set_tools_fn(agent, list()))
  }
  agent
}
