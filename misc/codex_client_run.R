# --- EXECUTION ---
# The code below is commented out so it doesn't run automatically on source().
# You can run these lines manually in your console after sourcing the file.

# Step 1: Login
my_tokens <- login_to_chatgpt()
cat("Access Token obtained successfully! Inspect the token object below:\n")
print(my_tokens)

# Step 2: Test a query
# result <- send_codex_query(my_tokens, "Write an R function to calculate prime numbers.")
# print(result)