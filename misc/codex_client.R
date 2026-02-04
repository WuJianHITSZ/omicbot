library(httr2)
library(httpuv)
library(jsonlite)
library(openssl)
library(shiny)

# 1. Configuration Constants
CLIENT_ID <- "app_EMoamEEZ73f0CkXaXp7hrann" # The Codex Public Client ID
AUTH_URL  <- "https://auth.openai.com/oauth/authorize"
TOKEN_URL <- "https://auth.openai.com/oauth/token"
REDIRECT_URI <- "http://localhost:1455/auth/callback"

# 2. PKCE Helper Functions
# Creates a high-entropy random string
generate_verifier <- function() {
  chars <- c(letters, LETTERS, 0:9, "-", ".", "_", "~")
  paste(sample(chars, 64, replace = TRUE), collapse = "")
}

# Hashes the verifier for the 'challenge'
generate_challenge <- function(verifier) {
  sha256_hash <- sha256(charToRaw(verifier))
  # Base64 URL encoding (no padding, replace + and /)
  challenge <- base64_encode(sha256_hash)
  challenge <- gsub("\\+", "-", challenge)
  challenge <- gsub("/", "_", challenge)
  challenge <- gsub("=", "", challenge)
  return(challenge)
}

# 3. The Login Function
login_to_chatgpt <- function() {
  verifier <- generate_verifier()
  challenge <- generate_challenge(verifier)
  # Generate a random state for CSRF protection
  state <- paste(sample(c(letters, LETTERS, 0:9), 16, replace = TRUE), collapse = "")
  
  # Build the Authorization URL
  auth_request_url <- url_parse(AUTH_URL)
  auth_request_url$query <- list(
    client_id = CLIENT_ID,
    response_type = "code",
    scope = "openid profile email offline_access",
    redirect_uri = REDIRECT_URI,
    code_challenge = challenge,
    code_challenge_method = "S256",
    audience = "https://api.openai.com/v1",
    state = state # Add state to the request
  )
  final_url <- url_build(auth_request_url)
  
  cat("Opening browser for login...\n")
  browseURL(final_url)
  
  # 4. Local Server to catch the Auth Code
  auth_code <- NULL
  server_error <- NULL
  server <- startServer("127.0.0.1", 1455, list(
    call = function(req) {
      qs <- shiny::parseQueryString(req$QUERY_STRING)
      
      # Check for errors from the auth server
      if (!is.null(qs$error)) {
        server_error <<- paste("Authentication error:", qs$error, "-", qs$error_description)
        return(list(status = 400L, headers = list('Content-Type' = 'text/html'), body = paste0("<h1>Error</h1><p>", server_error, "</p>")))
      }
      
      # Verify the state to prevent CSRF
      if (is.null(qs$state) || qs$state != state) {
        server_error <<- "Invalid state parameter. Possible CSRF attack."
        return(list(status = 400L, headers = list('Content-Type' = 'text/html'), body = "<h1>Error: Invalid State</h1><p>Please try logging in again.</p>"))
      }
      
      auth_code <<- qs$code
      
      res <- list(
        status = 200L,
        headers = list('Content-Type' = 'text/html'),
        body = "<h1>Login Successful!</h1><p>You can close this window and return to R.</p>"
      )
      return(res)
    }
  ))
  
  # Wait for the code or an error
  while(is.null(auth_code) && is.null(server_error)) {
    service()
    Sys.sleep(0.1)
  }
  stopServer(server)
  
  # If an error occurred in the server, stop execution and report it
  if (!is.null(server_error)) {
    stop(server_error)
  }
  
  cat("Authorization code received. Exchanging for token...\n")
  
  # 5. Exchange Code for Access Token
  token_response <- request(TOKEN_URL) %>%
    req_body_form(
      client_id = CLIENT_ID,
      grant_type = "authorization_code",
      code = auth_code,
      code_verifier = verifier,
      redirect_uri = REDIRECT_URI
    ) %>%
    req_perform() %>%
    resp_body_json()
  
  return(token_response)
}

# 6. The Codex "Responses-API" Request Function
send_codex_query <- function(token, prompt) {
  # Use the standard Chat Completions endpoint
  api_url <- "https://api.openai.com/v1/chat/completions"
  
  # Use the standard Chat Completions body format
  body <- list(
    model = "gpt-4o",
    messages = list(
      list(role = "system", content = "You are a helpful coding assistant."),
      list(role = "user", content = prompt)
    )
  )
  
  # Build the request
  req <- request(api_url) %>%
    req_auth_bearer_token(token$access_token) %>%
    req_body_json(body) %>%
    # Do not automatically throw an error on 4xx/5xx responses
    req_error(is_error = function(resp) FALSE)
    
  # Perform the request
  resp <- req_perform(req)
  
  # Check if the response is an error
  if (resp_is_error(resp)) {
    cat("--- DETAILED API ERROR RESPONSE ---\n")
    error_body <- resp_body_json(resp, simplifyVector = TRUE)
    print(error_body)
    cat("-------------------------------------\n")
    stop(paste("API Request Failed with status", resp_status(resp), ":", error_body$error$message))
  }
  
  return(resp_body_json(resp))
}

# --- EXECUTION ---
# The code below is commented out so it doesn't run automatically on source().
# You can run these lines manually in your console after sourcing the file.

# # Step 1: Login
# my_tokens <- login_to_chatgpt()
# cat("Access Token obtained successfully! Inspect the token object below:\n")
# print(my_tokens)
# 
# # Step 2: Test a query
# # result <- send_codex_query(my_tokens, "Write an R function to calculate prime numbers.")
# # print(result)