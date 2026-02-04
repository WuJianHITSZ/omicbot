.omicbot_databot_object_exists <- function(name) {
  exists(name, envir = .GlobalEnv, inherits = FALSE)
}

.omicbot_databot_default_name <- function(path) {
  tools::file_path_sans_ext(basename(path))
}

.omicbot_tool_load_rds <- function(path, name = "") {
  gate <- .omicbot_guardrail_confirm(
    action = "load_rds",
    target = ".GlobalEnv",
    details = sprintf("source file: %s", path)
  )
  if (!gate$approved) return(gate$message)

  if (!file.exists(path)) {
    return(sprintf("Error: file not found: %s", path))
  }
  obj <- tryCatch(readRDS(path), error = function(e) e)
  if (inherits(obj, "error")) {
    return(sprintf("Error: %s", conditionMessage(obj)))
  }
  target <- trimws(name)
  if (!nzchar(target)) {
    target <- .omicbot_databot_default_name(path)
  }
  assign(target, obj, envir = .GlobalEnv)
  sprintf("Loaded RDS into .GlobalEnv as '%s'.", target)
}

.omicbot_tool_save_rds <- function(name, path, compress = TRUE) {
  gate <- .omicbot_guardrail_confirm(
    action = "save_rds",
    target = path,
    details = sprintf("object: %s", name)
  )
  if (!gate$approved) return(gate$message)

  if (!.omicbot_databot_object_exists(name)) {
    return(sprintf("Error: object '%s' not found in .GlobalEnv.", name))
  }
  dir_path <- dirname(path)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
  obj <- get(name, envir = .GlobalEnv, inherits = FALSE)
  ok <- tryCatch(
    {
      saveRDS(obj, file = path, compress = compress)
      TRUE
    },
    error = function(e) e
  )
  if (inherits(ok, "error")) {
    return(sprintf("Error: %s", conditionMessage(ok)))
  }
  sprintf("Saved object '%s' to %s", name, path)
}

.omicbot_tool_list_global <- function(pattern = "", include_hidden = FALSE) {
  names <- ls(envir = .GlobalEnv, all.names = include_hidden)
  if (nzchar(pattern)) {
    names <- names[grepl(pattern, names)]
  }
  if (!length(names)) return("No objects found in .GlobalEnv.")
  classes <- vapply(names, function(nm) paste(class(get(nm, envir = .GlobalEnv)), collapse = "/"), character(1))
  paste(sprintf("%s [%s]", names, classes), collapse = "\n")
}

.omicbot_tool_search_global <- function(query) {
  names <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (!length(names)) return("No objects found in .GlobalEnv.")
  hits <- names[grepl(query, names, ignore.case = TRUE)]
  if (!length(hits)) return(sprintf("No object names matched query: %s", query))
  paste(hits, collapse = "\n")
}

.omicbot_databot_snapshot <- function(obj, n = 6L) {
  out <- character(0)
  out <- c(out, sprintf("type: %s", typeof(obj)))
  out <- c(out, sprintf("class: %s", paste(class(obj), collapse = "/")))
  if (!is.null(dim(obj))) {
    out <- c(out, sprintf("dim: %s", paste(dim(obj), collapse = " x ")))
  } else {
    out <- c(out, sprintf("length: %d", length(obj)))
  }
  head_text <- tryCatch(capture.output(utils::head(obj, n = n)), error = function(e) sprintf("head() error: %s", conditionMessage(e)))
  c(out, "head:", head_text)
}

.omicbot_tool_inspect_object <- function(name, n = 6) {
  if (!.omicbot_databot_object_exists(name)) {
    return(sprintf("Error: object '%s' not found in .GlobalEnv.", name))
  }
  obj <- get(name, envir = .GlobalEnv, inherits = FALSE)
  n <- suppressWarnings(as.integer(n))
  if (is.na(n) || n <= 0) n <- 6L
  paste(.omicbot_databot_snapshot(obj, n = n), collapse = "\n")
}

.omicbot_tool_object_summary <- function(name) {
  if (!.omicbot_databot_object_exists(name)) {
    return(sprintf("Error: object '%s' not found in .GlobalEnv.", name))
  }
  obj <- get(name, envir = .GlobalEnv, inherits = FALSE)
  out <- tryCatch(capture.output(summary(obj)), error = function(e) sprintf("Error: %s", conditionMessage(e)))
  paste(out, collapse = "\n")
}

.omicbot_tool_global_overview <- function() {
  names <- ls(envir = .GlobalEnv, all.names = TRUE)
  if (!length(names)) return("No objects found in .GlobalEnv.")
  cls <- vapply(names, function(nm) class(get(nm, envir = .GlobalEnv, inherits = FALSE))[1], character(1))
  tb <- sort(table(cls), decreasing = TRUE)
  paste(sprintf("%s: %d", names(tb), as.integer(tb)), collapse = "\n")
}

.omicbot_tool_plot_df <- function(name, plot_type = "scatter", x = "", y = "", color = "", bins = 30) {
  if (!.omicbot_databot_object_exists(name)) {
    return(sprintf("Error: object '%s' not found in .GlobalEnv.", name))
  }
  df <- get(name, envir = .GlobalEnv, inherits = FALSE)
  if (!is.data.frame(df)) {
    return(sprintf("Error: object '%s' is not a data.frame.", name))
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    return("Error: ggplot2 is not installed.")
  }
  if (!nzchar(x) || !x %in% names(df)) {
    return("Error: valid x column is required.")
  }
  if (plot_type %in% c("scatter", "line", "box") && (!nzchar(y) || !y %in% names(df))) {
    return("Error: valid y column is required for this plot type.")
  }
  bins <- suppressWarnings(as.integer(bins))
  if (is.na(bins) || bins <= 0) bins <- 30L

  p <- NULL
  if (plot_type == "scatter") {
    aes <- if (nzchar(color) && color %in% names(df)) {
      ggplot2::aes_string(x = x, y = y, color = color)
    } else {
      ggplot2::aes_string(x = x, y = y)
    }
    p <- ggplot2::ggplot(df, aes) + ggplot2::geom_point()
  } else if (plot_type == "line") {
    aes <- if (nzchar(color) && color %in% names(df)) {
      ggplot2::aes_string(x = x, y = y, color = color)
    } else {
      ggplot2::aes_string(x = x, y = y)
    }
    p <- ggplot2::ggplot(df, aes) + ggplot2::geom_line()
  } else if (plot_type == "hist") {
    p <- ggplot2::ggplot(df, ggplot2::aes_string(x = x)) + ggplot2::geom_histogram(bins = bins)
  } else if (plot_type == "box") {
    p <- ggplot2::ggplot(df, ggplot2::aes_string(x = x, y = y)) + ggplot2::geom_boxplot()
  } else {
    return("Error: unsupported plot_type. Use one of: scatter, line, hist, box.")
  }

  print(p)
  sprintf("Plotted %s for '%s'.", plot_type, name)
}

.omicbot_tool_remove_object <- function(name) {
  gate <- .omicbot_guardrail_confirm(
    action = "remove_object",
    target = ".GlobalEnv",
    details = sprintf("object: %s", name)
  )
  if (!gate$approved) return(gate$message)

  if (!.omicbot_databot_object_exists(name)) {
    return(sprintf("Error: object '%s' not found in .GlobalEnv.", name))
  }
  rm(list = name, envir = .GlobalEnv)
  sprintf("Removed '%s' from .GlobalEnv.", name)
}

omicbot_databot_tools <- function() {
  list(
    ellmer::tool(
      .omicbot_tool_load_rds,
      name = "load_rds",
      description = "Load an .rds file and assign it to .GlobalEnv.",
      arguments = list(
        path = ellmer::type_string("Path to .rds file."),
        name = ellmer::type_string("Optional object name in .GlobalEnv.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_save_rds,
      name = "save_rds",
      description = "Save an object from .GlobalEnv to an .rds file.",
      arguments = list(
        name = ellmer::type_string("Object name in .GlobalEnv."),
        path = ellmer::type_string("Destination .rds path."),
        compress = ellmer::type_boolean("Whether to compress the RDS output.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_list_global,
      name = "list_global",
      description = "List objects in .GlobalEnv with class information.",
      arguments = list(
        pattern = ellmer::type_string("Optional regex pattern to filter object names."),
        include_hidden = ellmer::type_boolean("Include hidden names starting with '.'.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_search_global,
      name = "search_global",
      description = "Search object names in .GlobalEnv using a case-insensitive regex query.",
      arguments = list(
        query = ellmer::type_string("Regex query for object names.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_inspect_object,
      name = "inspect_object",
      description = "Show object type/class/size and a head() snapshot.",
      arguments = list(
        name = ellmer::type_string("Object name in .GlobalEnv."),
        n = ellmer::type_string("Number of rows/elements for head().")
      )
    ),
    ellmer::tool(
      .omicbot_tool_object_summary,
      name = "summary_object",
      description = "Run summary() on an object in .GlobalEnv.",
      arguments = list(
        name = ellmer::type_string("Object name in .GlobalEnv.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_global_overview,
      name = "global_overview",
      description = "Summarize object counts by class in .GlobalEnv.",
      arguments = list()
    ),
    ellmer::tool(
      .omicbot_tool_plot_df,
      name = "plot_df",
      description = "Plot a data.frame from .GlobalEnv using ggplot2 and print to the current plot device.",
      arguments = list(
        name = ellmer::type_string("data.frame object name in .GlobalEnv."),
        plot_type = ellmer::type_string("One of: scatter, line, hist, box."),
        x = ellmer::type_string("x column name."),
        y = ellmer::type_string("y column name (required for scatter/line/box)."),
        color = ellmer::type_string("Optional color column name."),
        bins = ellmer::type_string("Histogram bins (integer).")
      )
    ),
    ellmer::tool(
      .omicbot_tool_remove_object,
      name = "remove_object",
      description = "Remove an object from .GlobalEnv.",
      arguments = list(
        name = ellmer::type_string("Object name in .GlobalEnv.")
      )
    )
  )
}
