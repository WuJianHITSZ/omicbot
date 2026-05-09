.omicbot_skills_dir <- function() {
  file.path(.omicbot_config_paths()$dir, "skills")
}

.omicbot_bundled_skills_dir <- function() {
  installed <- system.file("extdata", "skills", package = "omicbot")
  if (nzchar(installed)) {
    return(installed)
  }
  local <- file.path(getwd(), "inst", "extdata", "skills")
  if (dir.exists(local)) local else ""
}

.omicbot_skill_name_ok <- function(name) {
  is.character(name) && length(name) == 1L &&
    grepl("^[a-zA-Z][a-zA-Z0-9_-]*$", name)
}

.omicbot_skill_title <- function(skill_md) {
  lines <- readLines(skill_md, warn = FALSE)
  heading <- grep("^#\\s+", lines, value = TRUE)
  if (length(heading)) {
    return(trimws(sub("^#\\s+", "", heading[[1]])))
  }
  basename(dirname(skill_md))
}

.omicbot_skill_summary <- function(skill_md) {
  lines <- trimws(readLines(skill_md, warn = FALSE))
  lines <- lines[nzchar(lines)]
  lines <- lines[!grepl("^#", lines)]
  if (length(lines)) lines[[1]] else ""
}

.omicbot_scan_skill_root <- function(root, origin) {
  if (!nzchar(root) || !dir.exists(root)) {
    return(list())
  }
  dirs <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  skills <- list()
  for (dir in dirs) {
    name <- basename(dir)
    skill_md <- file.path(dir, "SKILL.md")
    if (!file.exists(skill_md) || !.omicbot_skill_name_ok(name)) {
      next
    }
    skills[[name]] <- list(
      name = name,
      title = .omicbot_skill_title(skill_md),
      summary = .omicbot_skill_summary(skill_md),
      path = normalizePath(dir, winslash = "/", mustWork = TRUE),
      skill_md = normalizePath(skill_md, winslash = "/", mustWork = TRUE),
      tools_r = file.path(dir, "tools.R"),
      origin = origin
    )
  }
  skills
}

.omicbot_discover_skills <- function() {
  bundled <- .omicbot_scan_skill_root(.omicbot_bundled_skills_dir(), "bundled")
  user <- .omicbot_scan_skill_root(.omicbot_skills_dir(), "user")
  skills <- bundled
  for (name in names(user)) {
    skills[[name]] <- user[[name]]
  }
  skills
}

.omicbot_get_skill <- function(name) {
  skills <- .omicbot_discover_skills()
  skill <- skills[[name]]
  if (is.null(skill)) {
    cli::cli_abort("No skill named {.field {name}} was found.")
  }
  skill
}

.omicbot_tool_read_skill <- function(name) {
  skill <- .omicbot_get_skill(name)
  paste(readLines(skill$skill_md, warn = FALSE), collapse = "\n")
}

omicbot_skill_tools <- function() {
  list(
    ellmer::tool(
      .omicbot_tool_read_skill,
      name = "read_skill",
      description = paste(
        "Read an installed Omicbot folder skill's SKILL.md instructions.",
        "Use this before applying a skill-specific workflow."
      ),
      arguments = list(
        name = ellmer::type_string("Installed skill folder name, e.g. gott.")
      )
    )
  )
}

.omicbot_load_skill_tools <- function(skill) {
  if (!file.exists(skill$tools_r)) {
    return(list())
  }
  env <- new.env(parent = parent.env(environment()))
  sys.source(skill$tools_r, envir = env)
  if (!exists("omicbot_skill_tools", envir = env, inherits = FALSE)) {
    return(list())
  }
  tools <- get("omicbot_skill_tools", envir = env, inherits = FALSE)(skill)
  if (is.null(tools)) {
    list()
  } else if (is.list(tools)) {
    tools
  } else {
    list(tools)
  }
}

.omicbot_register_folder_skills <- function(agent) {
  skills <- .omicbot_discover_skills()
  n_tools <- 0L
  for (skill in skills) {
    tools <- tryCatch(
      .omicbot_load_skill_tools(skill),
      error = function(e) {
        cli::cli_warn("Failed to load skill '{skill$name}' tools: {conditionMessage(e)}")
        list()
      }
    )
    for (tool in tools) {
      tryCatch({
        agent$register_tool(tool)
        n_tools <- n_tools + 1L
      }, error = function(e) {
        cli::cli_warn("Failed to register tool from skill '{skill$name}': {conditionMessage(e)}")
      })
    }
  }
  invisible(n_tools)
}

.omicbot_skill_prompt_index <- function() {
  skills <- .omicbot_discover_skills()
  if (!length(skills)) {
    return("")
  }
  rows <- vapply(skills, function(skill) {
    summary <- if (nzchar(skill$summary)) paste0(": ", skill$summary) else ""
    sprintf("- `%s` (%s)%s", skill$name, skill$origin, summary)
  }, character(1))
  paste(c(
    "## Installed Folder Skills",
    "",
    "Use `read_skill(name)` before applying a folder skill. Available skills:",
    rows
  ), collapse = "\n")
}

#' List installed folder skills.
#'
#' @return A data.frame of installed skill folders, invisibly.
#' @export
list_skills <- function() {
  skills <- .omicbot_discover_skills()
  if (!length(skills)) {
    cli::cli_alert_info("No folder skills installed.")
    return(invisible(NULL))
  }
  df <- do.call(rbind, lapply(skills, function(skill) {
    data.frame(
      name = skill$name,
      title = skill$title,
      origin = skill$origin,
      path = skill$path,
      stringsAsFactors = FALSE
    )
  }))
  rownames(df) <- NULL
  print(df)
  invisible(df)
}

#' Read a folder skill's SKILL.md instructions.
#'
#' @param name Skill folder name.
#' @return The SKILL.md contents as a string.
#' @export
read_skill <- function(name) {
  text <- .omicbot_tool_read_skill(name)
  cat(text, "\n", sep = "")
  invisible(text)
}

#' Install a folder skill by copying it into the Omicbot config directory.
#'
#' @param path Path to a skill folder containing SKILL.md.
#' @param name Optional installed folder name. Defaults to basename(path).
#' @param overwrite Replace an existing installed skill with the same name.
#' @return The installed skill path, invisibly.
#' @export
install_skill <- function(path, name = basename(normalizePath(path, mustWork = FALSE)),
                          overwrite = FALSE) {
  if (!dir.exists(path)) {
    cli::cli_abort("Skill folder does not exist: {.file {path}}")
  }
  if (!file.exists(file.path(path, "SKILL.md"))) {
    cli::cli_abort("Skill folder must contain SKILL.md: {.file {path}}")
  }
  if (!.omicbot_skill_name_ok(name)) {
    cli::cli_abort("Skill name must start with a letter and contain only letters, numbers, '-' or '_'.")
  }
  dest_root <- .omicbot_skills_dir()
  if (!dir.exists(dest_root)) {
    dir.create(dest_root, recursive = TRUE)
  }
  dest <- file.path(dest_root, name)
  if (dir.exists(dest)) {
    if (!isTRUE(overwrite)) {
      cli::cli_abort("Skill already exists: {.file {dest}}. Use overwrite = TRUE to replace it.")
    }
    unlink(dest, recursive = TRUE)
  }
  ok <- file.copy(path, dest_root, recursive = TRUE)
  if (!isTRUE(ok)) {
    cli::cli_abort("Failed to copy skill folder to {.file {dest_root}}.")
  }
  copied <- file.path(dest_root, basename(path))
  if (!identical(normalizePath(copied, mustWork = FALSE), normalizePath(dest, mustWork = FALSE))) {
    file.rename(copied, dest)
  }
  cli::cli_alert_success("Installed skill '{name}' to {.file {dest}}.")
  invisible(dest)
}

#' Create a folder skill scaffold.
#'
#' @param name Skill folder name. Must start with a letter and contain only
#'   letters, numbers, hyphens, or underscores.
#' @param path Parent directory where the skill folder should be created.
#' @param title Optional title for the SKILL.md heading.
#' @param description Optional first instruction paragraph for SKILL.md.
#' @param tools Whether to create a tools.R template.
#' @param overwrite Replace an existing skill folder at the destination.
#' @return The created skill folder path, invisibly.
#' @export
create_skill <- function(name, path = getwd(), title = NULL, description = NULL,
                         tools = FALSE, overwrite = FALSE) {
  if (!.omicbot_skill_name_ok(name)) {
    cli::cli_abort("Skill name must start with a letter and contain only letters, numbers, '-' or '_'.")
  }
  if (is.null(title) || !nzchar(title)) {
    title <- name
  }
  if (is.null(description) || !nzchar(description)) {
    description <- paste0("Use this skill for ", name, " workflows.")
  }
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  dest <- file.path(path, name)
  if (dir.exists(dest)) {
    if (!isTRUE(overwrite)) {
      cli::cli_abort("Skill folder already exists: {.file {dest}}. Use overwrite = TRUE to replace it.")
    }
    unlink(dest, recursive = TRUE)
  }
  dir.create(dest, recursive = TRUE)

  skill_md <- c(
    paste0("# ", title),
    "",
    description,
    "",
    "## When To Use",
    "",
    "- Use this skill when the user's request matches this workflow.",
    "",
    "## Workflow",
    "",
    "1. Read the user's request and identify the relevant inputs.",
    "2. Run the appropriate analysis or tool calls.",
    "3. Report the result, including any assumptions or files created.",
    "",
    "## Constraints",
    "",
    "- Do not overwrite user files unless explicitly requested.",
    "- Ask for missing inputs only when they cannot be inferred safely."
  )
  writeLines(skill_md, file.path(dest, "SKILL.md"))

  if (isTRUE(tools)) {
    tools_r <- c(
      "omicbot_skill_tools <- function(skill) {",
      "  list(",
      "    ellmer::tool(",
      "      function() {",
      "        \"ok\"",
      "      },",
      paste0("      name = \"", gsub("[^A-Za-z0-9_]", "_", name), "_ok\","),
      "      description = \"Return ok from this skill tool.\"",
      "    )",
      "  )",
      "}"
    )
    writeLines(tools_r, file.path(dest, "tools.R"))
  }

  cli::cli_alert_success("Created skill scaffold at {.file {dest}}.")
  invisible(dest)
}

#' Load installed folder-skill tools into the active agent.
#'
#' @param agent An \code{ellmer} chat object. If \code{NULL}, the active
#'   Omicbot agent is used.
#' @return Invisibly returns the number of executable tools registered.
#' @export
load_skills <- function(agent = NULL) {
  if (is.null(agent)) {
    agent <- .omicbot_get_agent()
  }
  n_tools <- .omicbot_register_folder_skills(agent)
  if (n_tools > 0L) {
    cli::cli_alert_info("Loaded {n_tools} skill tool{?s}.")
  }
  invisible(n_tools)
}
