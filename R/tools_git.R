.omicbot_git_run <- function(path = ".", args = character()) {
  git_bin <- Sys.which("git")
  if (!nzchar(git_bin)) {
    return("Error: git is not installed.")
  }
  out <- tryCatch(
    system2(git_bin, c("-C", path, args), stdout = TRUE, stderr = TRUE),
    error = function(e) e
  )
  if (inherits(out, "error")) {
    return(sprintf("Error: %s", conditionMessage(out)))
  }
  status <- attr(out, "status")
  text <- if (length(out)) paste(out, collapse = "\n") else ""
  if (!is.null(status) && status != 0) {
    if (!nzchar(text)) text <- sprintf("git command failed with status %s", status)
    return(sprintf("Error: %s", text))
  }
  if (!nzchar(text)) "OK" else text
}

.omicbot_tool_git_init_baseline <- function(path = ".", message = "baseline") {
  gate <- .omicbot_guardrail_confirm(
    action = "git_init_baseline",
    target = path,
    details = sprintf("git init && git add . && git commit -m %s", shQuote(message))
  )
  if (!gate$approved) return(gate$message)

  res_init <- .omicbot_git_run(path, c("init"))
  if (startsWith(res_init, "Error:")) return(res_init)
  res_add <- .omicbot_git_run(path, c("add", "."))
  if (startsWith(res_add, "Error:")) return(res_add)
  res_commit <- .omicbot_git_run(path, c("commit", "-m", message))
  if (startsWith(res_commit, "Error:")) return(res_commit)
  paste("Repository initialized and baseline committed.", res_commit)
}

.omicbot_tool_git_status <- function(path = ".") {
  .omicbot_git_run(path, c("status", "--short"))
}

.omicbot_tool_git_create_patch <- function(path = ".", patch_file = "proposed.patch", word_diff = FALSE) {
  mode_args <- if (isTRUE(word_diff)) c("diff", "--word-diff") else c("diff")
  diff_text <- .omicbot_git_run(path, mode_args)
  if (startsWith(diff_text, "Error:")) return(diff_text)

  out_path <- file.path(path, patch_file)
  dir_path <- dirname(out_path)
  if (!dir.exists(dir_path)) dir.create(dir_path, recursive = TRUE)
  writeLines(diff_text, out_path)
  sprintf("Patch written to %s", out_path)
}

.omicbot_tool_git_commit_approved <- function(path = ".", message = "Apply AI edits") {
  gate <- .omicbot_guardrail_confirm(
    action = "git_commit_approved",
    target = path,
    details = sprintf("git add -A && git commit -m %s", shQuote(message))
  )
  if (!gate$approved) return(gate$message)

  res_add <- .omicbot_git_run(path, c("add", "-A"))
  if (startsWith(res_add, "Error:")) return(res_add)
  res_commit <- .omicbot_git_run(path, c("commit", "-m", message))
  if (startsWith(res_commit, "Error:")) return(res_commit)
  paste("Approved edits committed.", res_commit)
}

.omicbot_tool_git_reject_restore <- function(path = ".", staged = TRUE) {
  gate <- .omicbot_guardrail_confirm(
    action = "git_reject_restore",
    target = path,
    details = "Discard current working changes and restore baseline"
  )
  if (!gate$approved) return(gate$message)

  if (isTRUE(staged)) {
    res_unstage <- .omicbot_git_run(path, c("restore", "--staged", "."))
    if (startsWith(res_unstage, "Error:")) return(res_unstage)
  }
  res_restore <- .omicbot_git_run(path, c("restore", "."))
  if (startsWith(res_restore, "Error:")) return(res_restore)
  "Rejected edits discarded and working tree restored."
}

omicbot_git_tools <- function() {
  list(
    ellmer::tool(
      .omicbot_tool_git_init_baseline,
      name = "git_init_baseline",
      description = "Initialize a git repo and create a baseline commit (git init, git add ., git commit).",
      arguments = list(
        path = ellmer::type_string("Target working directory."),
        message = ellmer::type_string("Baseline commit message.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_git_status,
      name = "git_status",
      description = "Show concise git working tree status.",
      arguments = list(
        path = ellmer::type_string("Target working directory.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_git_create_patch,
      name = "git_create_patch",
      description = "Create a proposed patch file from current git diff for review.",
      arguments = list(
        path = ellmer::type_string("Target working directory."),
        patch_file = ellmer::type_string("Patch output filename, e.g. proposed.patch."),
        word_diff = ellmer::type_boolean("Use --word-diff for easier review.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_git_commit_approved,
      name = "git_commit_approved",
      description = "Commit approved edits (git add -A, git commit).",
      arguments = list(
        path = ellmer::type_string("Target working directory."),
        message = ellmer::type_string("Commit message.")
      )
    ),
    ellmer::tool(
      .omicbot_tool_git_reject_restore,
      name = "git_reject_restore",
      description = "Discard rejected edits and restore working tree.",
      arguments = list(
        path = ellmer::type_string("Target working directory."),
        staged = ellmer::type_boolean("Also unstage changes before restore.")
      )
    )
  )
}
