#!/usr/bin/env Rscript

# Minimal agentic databot demo using ellmer.
# - Schema-first outputs (`type_*`)
# - Local tool calling
# - Optional provider web tools (`claude_*` / `google_*`)

suppressPackageStartupMessages({
  library(ellmer)
})

tool_list_csv <- tool(
  function(path = ".") {
    if (!dir.exists(path)) stop("Directory not found: ", path)
    list.files(path, pattern = "\\.csv$", full.names = TRUE)
  },
  name = "list_csv",
  description = "List CSV files in a directory.",
  arguments = list(
    path = type_string("Directory to scan for CSV files.")
  )
)

tool_peek_csv <- tool(
  function(path, n = 10L) {
    if (!file.exists(path)) stop("File not found: ", path)
    dat <- utils::read.csv(path, check.names = FALSE)
    utils::head(dat, n = as.integer(n))
  },
  name = "peek_csv",
  description = "Read and preview top rows of a CSV file.",
  arguments = list(
    path = type_string("Path to CSV file."),
    n = type_integer("Number of rows to preview.")
  )
)

tool_summarize_csv <- tool(
  function(path) {
    if (!file.exists(path)) stop("File not found: ", path)
    dat <- utils::read.csv(path, check.names = FALSE)
    is_num <- vapply(dat, is.numeric, logical(1))
    nums <- dat[is_num]
    list(
      rows = nrow(dat),
      cols = ncol(dat),
      numeric_columns = names(nums),
      numeric_summary = if (length(nums)) summary(nums) else "No numeric columns"
    )
  },
  name = "summarize_csv",
  description = "Compute a lightweight summary of a CSV file.",
  arguments = list(
    path = type_string("Path to CSV file.")
  )
)

make_databot <- function(provider = "openai", model = NULL, web_tools = TRUE) {
  if (is.null(model)) {
    model <- switch(
      provider,
      openai = "gpt-5-mini",
      claude = "claude-sonnet-4-5",
      google = "gemini-2.5-flash",
      ollama = "qwen2.5:latest",
      stop("Unsupported provider: ", provider)
    )
  }

  system_prompt <- paste(
    "You are an R data analyst agent.",
    "Use tools before making claims about files.",
    "Return concise, evidence-backed answers.",
    sep = " "
  )

  bot <- switch(
    provider,
    openai = chat_openai(model = model, system_prompt = system_prompt, echo = "none"),
    claude = chat_claude(model = model, system_prompt = system_prompt, echo = "none"),
    google = chat_google_gemini(model = model, system_prompt = system_prompt, echo = "none"),
    ollama = chat_ollama(model = model, system_prompt = system_prompt, echo = "none")
  )

  tools <- list(tool_list_csv, tool_peek_csv, tool_summarize_csv)

  if (isTRUE(web_tools) && provider == "claude") {
    tools <- c(tools, list(claude_tool_web_search(), claude_tool_web_fetch()))
  }
  if (isTRUE(web_tools) && provider == "google") {
    tools <- c(tools, list(google_tool_web_search(), google_tool_web_fetch()))
  }

  bot$register_tools(tools)
  bot
}

run_demo <- function(data_dir = ".", provider = "openai", model = NULL) {
  bot <- make_databot(provider = provider, model = model, web_tools = TRUE)

  schema <- type_object(
    objective = type_string("Overall task objective."),
    files_to_check = type_array(type_string("CSV file path.")),
    analysis_plan = type_array(type_string("Ordered steps to run.")),
    risks = type_array(type_string("Potential data quality risks.")),
    recommended_output = type_string("Suggested output report path.")
  )

  prompt <- paste(
    "Build a short analysis plan for CSV files in:", normalizePath(data_dir),
    "Use tools to inspect files before proposing steps.",
    "Keep the plan practical for an R scripted databot."
  )

  bot$chat_structured(prompt, type = schema, echo = "all")
}

if (identical(environment(), globalenv())) {
  # Example:
  # Sys.setenv(OPENAI_API_KEY = "...")
  # plan <- run_demo(data_dir = "inst/exdata", provider = "openai")
  # str(plan)
  message("Loaded demo helpers: make_databot(), run_demo()")
}
