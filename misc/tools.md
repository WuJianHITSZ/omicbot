# ellmer function brief (re-done with upstream source context)

## Scope and method

- Repo provided: <https://github.com/tidyverse/ellmer>
- Local package on this Mac: `ellmer 0.4.0` at `/Library/Frameworks/R.framework/Versions/4.5-arm64/Resources/library/ellmer`
- Logic review combines:
  - exported docs/source mapping from ellmer site (`R/type.R`, `R/provider-claude-files.R`, `R/provider-claude-tools.R`, `R/provider-google-tools.R`, `R/provider-google-upload.R`)
  - runtime function body inspection from installed namespace (`asNamespace("ellmer")`)

## Function logic by pattern

### `Type*` classes (schema model layer)

- `Type`: base S7 class with shared metadata (`description`, `required`).
- `TypeBasic`: scalar type holder (`"boolean"`, `"integer"`, `"number"`, `"string"`).
- `TypeEnum`: enum holder (`values`) for constrained strings.
- `TypeArray`: array/list schema (`items`).
- `TypeObject`: object schema (`properties`, plus `additional_properties` policy).
- `TypeIgnore`: sentinel schema to tell tool-calling not to synthesize that argument.
- `TypeJsonSchema`: raw JSON Schema container for full custom schemas.

Core logic: `Type*` is the internal AST for function-call and structured-output schemas; provider adapters serialize these to provider-specific payloads.

### `type_*` constructors (developer-facing schema DSL)

- `type_boolean()`, `type_integer()`, `type_number()`, `type_string()`: build `TypeBasic`.
- `type_enum(values, ...)`: build `TypeEnum`.
- `type_array(items, ...)`: build `TypeArray`.
- `type_object(..., .required, .additional_properties)`: build `TypeObject` from named properties.
- `type_ignore()`: build `TypeIgnore`.
- `type_from_schema(text|path)`: parse JSON schema and wrap as `TypeJsonSchema`.
- `type_needs_wrapper(type, provider)`: internal OpenAI-compatible compatibility gate (wrap needed unless object/json-schema already).

Core logic: these functions are thin constructors; safety/reliability comes from strong typing at tool boundary.

### `claude_*` (Anthropic file + built-in web tools)

- `claude_file_upload(path, ...)`:
  - validates file exists
  - builds multipart request to Claude files endpoint
  - returns `ContentUploaded(uri=id, mime_type=...)`
- `claude_file_list(...)`: `GET /files`, maps JSON entries to tabular metadata.
- `claude_file_get(file_id, ...)`: resolves existing file id to `ContentUploaded`.
- `claude_file_download(file_id, path, ...)`: downloads `files/{id}/content` to disk.
- `claude_file_delete(file_id, ...)`: sends `DELETE /files/{id}`.
- `claude_tool_web_search(...)`:
  - validates domain filters are mutually exclusive
  - builds built-in tool JSON (`web_search_20250305`) with optional `user_location`
- `claude_tool_web_fetch(...)`:
  - same filter checks
  - builds built-in tool JSON (`web_fetch_20250910`) with citations/token controls

Core logic: a strict request-construction layer around Anthropic APIs (validation first, then typed `ToolBuiltIn`/`ContentUploaded` objects).

### `google_*` (Gemini web tools + resumable upload pipeline)

- `google_tool_web_search()`: returns built-in grounding/search tool payload.
- `google_tool_web_fetch()`: returns built-in URL-context tool payload.
- `google_upload(path, ...)` orchestration:
  1. normalize credentials (`api_key`/ambient auth)
  2. infer mime type if missing
  3. `google_upload_init()` creates resumable upload session URL
  4. `google_upload_send()` uploads+finalizes bytes
  5. `google_upload_wait()` polls processing state until done/fail
  6. returns `ContentUploaded(uri, mime_type)`
- `google_upload_status(uri, ...)`: single status check call.
- `google_location(location)`: formats non-global location prefixes.
- `google_oauth_reset()`: clears cached OAuth state.

Core logic: robust upload finite-state flow (init -> send -> poll -> ready/error), which is important when prompts depend on large files.

## How this maps to an R scripted agentic databot

- Schema-first tooling:
  - define all tool inputs/outputs with `type_object()` and nested `type_*`
  - use `type_ignore()` for non-LLM runtime params (`conn`, `cache`, feature flags)
- Evidence acquisition:
  - enable `claude_tool_web_search/fetch` or `google_tool_web_search/fetch` for current-world grounding
  - constrain domains using allow/block lists for safety
- Large-context ingestion:
  - move PDFs/reports/logs via `claude_file_*` or `google_upload()` instead of prompt stuffing
- Deterministic control loop:
  1. plan step -> tool call
  2. enforce schema on result
  3. retry/repair if invalid
  4. persist result + citation provenance
- Production tip:
  - keep provider-specific helpers behind a small adapter (`upload_file()`, `enable_web_tools()`) so the agent logic stays provider-agnostic.

## Upstream references

- <https://github.com/tidyverse/ellmer>
- <https://ellmer.tidyverse.org/reference/Type.html>
- <https://ellmer.tidyverse.org/reference/type_boolean.html>
- <https://ellmer.tidyverse.org/reference/claude_file_upload.html>
- <https://ellmer.tidyverse.org/reference/claude_tool_web_search.html>
- <https://ellmer.tidyverse.org/reference/claude_tool_web_fetch.html>
- <https://ellmer.tidyverse.org/reference/google_tool_web_search.html>
- <https://ellmer.tidyverse.org/reference/google_tool_web_fetch.html>
- <https://ellmer.tidyverse.org/reference/google_upload.html>
