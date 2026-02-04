# R/codex_client.R and R/codex_client_run.R recap

## R/codex_client.R
Intent: implement a browser-based OAuth 2.0 PKCE flow to obtain an OpenAI access
token, then use it to call a model endpoint.

Logic overview:
- Defines OAuth constants (client ID, auth/token URLs, redirect URI).
- Generates PKCE verifier/challenge and a random `state` for CSRF protection.
- Opens the auth URL in a browser and starts a local `httpuv` server to receive
  the callback.
- Validates `state`, extracts the authorization code, and exchanges it for
  tokens via `httr2`.
- `send_codex_query()` calls `https://api.openai.com/v1/chat/completions` with a
  simple system + user message payload using the bearer token.
- Error handling prints detailed API error JSON when requests fail and surfaces
  informative messages to the caller.

## R/codex_client_run.R
Intent: provide a manual, script-like entry point for interactive testing of the
OAuth flow.

Logic overview:
- Calls `login_to_chatgpt()` to perform the OAuth flow and prints the token
  object for inspection.
- Includes a commented-out example of calling `send_codex_query()`.
- Designed to be run manually (not on source) as a quick testing harness.
