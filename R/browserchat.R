browserchat <- function() {
  agent <- getOption("omicbot.agent")
  if (is.null(agent)) {
    stop("No agent found. Run quickstart() first.", call. = FALSE)
  }

  if (!rstudioapi::isAvailable()) {
    stop("browserchat() requires RStudio to run a background job.", call. = FALSE)
  }

  temp_script <- tempfile("omicbot-browserchat-", fileext = ".R")
  script <- paste(
    "if (requireNamespace(\"omicbot\", quietly = TRUE)) {",
    "  omicbot::quickstart()",
    "} else {",
    "  source(\"R/models.R\")",
    "  source(\"R/api_key.R\")",
    "  source(\"R/agents.R\")",
    "  source(\"R/quickstart.R\")",
    "  quickstart()",
    "}",
    "agent <- getOption(\"omicbot.agent\")",
    "if (is.null(agent)) stop(\"No agent found.\", call. = FALSE)",
    "options(shiny.launch.browser = rstudioapi::viewer)",
    "options(browser = rstudioapi::viewer)",
    "url <- ellmer::live_browser(agent)",
    "if (is.character(url) && length(url) == 1 && grepl(\"^https?://\", url)) {",
    "  rstudioapi::viewer(url)",
    "}",
    sep = "\n"
  )
  writeLines(script, temp_script)
  rstudioapi::jobRunScript(
    temp_script,
    name = "omicbot browser chat",
    workingDir = normalizePath(".")
  )
}
