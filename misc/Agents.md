# AGENTS.md

## Purpose
This repo is an R package that adds an RStudio addin to run an agent `chat()` on
console input. These notes guide agentic coding tools working here.

## Repo layout
- `R/` package functions (internal helpers use `.omicbot_*` prefix)
- `inst/rstudio/addins.dcf` RStudio addin registration
- `inst/exdata/prompt.md` default system prompt used at startup
- `DESCRIPTION`, `NAMESPACE` standard R package metadata

## Build, lint, and test
There is no explicit build/lint/test tooling wired up beyond base R package
commands.

### Build / check
- Build tarball: `R CMD build .`
- Check package: `R CMD check .`
- Install locally: `R CMD INSTALL .`

### Tests
- No test framework or `tests/` directory is present.
- If you add testthat later, run all tests with:
  `Rscript -e 'testthat::test_dir("tests/testthat")'`
- Single test file (if testthat exists):
  `Rscript -e 'testthat::test_file("tests/testthat/test-foo.R")'`

### Lint / style
- No lint config detected.
- If lintr is added, run:
  `Rscript -e 'lintr::lint_package()'`

## RStudio addin usage
- The addin entry point is `quickchat()` and is bound in
  `inst/rstudio/addins.dcf`.
- `quickstart()` initializes provider/model selection and agent setup.

## Configuration and secrets
- Config is stored under `RSTUDIO_CONFIG_HOME` or `XDG_CONFIG_HOME`.
- The config file path is computed in `.omicbot_config_paths()`.
- API keys are stored in `.env` inside the config directory.
- Never commit `.env` or any local config artifacts.

## Code style guidelines
Follow established patterns in `R/`.

### Naming
- Exported functions use lower_snake_case (e.g., `quickstart`, `settings`).
- Internal helpers use `.omicbot_*` prefix and lower_snake_case.
- Constants are UPPER_SNAKE_CASE when truly constant (see `CLIENT_ID`).

### Imports
- Prefer `pkg::fun` when feasible to keep dependencies explicit.
- `library()` is used in a few files; avoid adding new global `library()` calls
  unless needed for side effects or a script-like file.
- Update `DESCRIPTION` Imports when adding new packages.

### Formatting
- Use `<-` for assignment.
- 2-space indentation; braces on same line as control statements.
- Keep lines reasonably short; wrap long strings with `paste()` or `sprintf()`.
- Use `sprintf()` for formatted output instead of string concatenation.

### Types and data handling
- Use `NULL` for missing values; prefer `is.null()` checks.
- Use `nzchar()` and `trimws()` for string validation.
- Use `as.character()` when coercing user-facing values.
- Return `invisible()` when a function is primarily side-effecting.

### Error handling
- For user-facing errors, use `stop(..., call. = FALSE)`.
- Use `tryCatch()` for non-critical steps (e.g., clipboard, API probes).
- If a failure is expected/handled, return `NULL` or `invisible(FALSE)`.
- Prefer early returns to reduce nesting.

### I/O and side effects
- Use `readLines()`/`writeLines()` for simple file operations.
- Avoid writing to package files at runtime; write to config dir only.
- Console output uses `cat()` for user messages; `message()` for warnings.

### Configuration patterns
- Centralize config paths in `.omicbot_config_paths()`.
- Read/write JSON via `jsonlite::read_json` and `jsonlite::write_json`.
- Keep the config schema minimal: `provider`, `model`.

### Agent lifecycle
- Agent is stored in `options(omicbot.agent = agent)`.
- Access via `.omicbot_get_agent()` and validate before use.
- Support methods on agent objects by probing for functions (see
  `.omicbot_set_system_prompt()`).

### RStudio API usage
- Check `rstudioapi::isAvailable()` before using RStudio APIs.
- Use `rstudioapi::getConsoleEditorContext()` for console reads.
- Use `rstudioapi::sendToConsole()` to trigger execution.

## Security and privacy
- Do not log or print API keys.
- Avoid writing tokens to disk unless required by existing flows.
- Keep OAuth and auth flows contained and recoverable.

## Patterns to preserve
- Clipboard handling uses `pbpaste`/`pbcopy` with graceful fallback.
- Use `%||%` helper for null coalescing.
- `stopServer()` is called after OAuth callback completes.
- Errors are surfaced with helpful messages and minimal stack traces.

## Documentation updates
- If you add new exported functions, update `NAMESPACE` and `DESCRIPTION`.
- Keep addin metadata in `inst/rstudio/addins.dcf` in sync with entry points.

## Cursor / Copilot rules
- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`
  found in this repo.

## Suggested verification (when applicable)
- Run `R CMD check .` after changes to `R/` or `DESCRIPTION`.
- Manually exercise `quickstart()` and `quickchat()` in RStudio when
  touching addin behavior.
