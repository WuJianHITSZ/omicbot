.omicbot_init_agent <- function(provider, model, prompt) {
  if (provider == "openai") {
    chat_openai(system_prompt = prompt, model = model)
  } else if (provider == "google") {
    chat_google_gemini(system_prompt = prompt, model = model)
  } else if (provider == "deepseek") {
    chat_deepseek(system_prompt = prompt, model = model)
  } else if (provider == "alibaba") {
    base_url <- .omicbot_openai_compatible_base_url(provider)
    chat_openai_compatible(
      system_prompt = prompt,
      model = model,
      base_url = base_url,
      credentials = function() Sys.getenv("DASHSCOPE_API_KEY")
    )
  } else if (provider == "ollama") {
    model_clean <- sub(":latest$", "", model)
    chat_ollama(system_prompt = prompt, model = model_clean)
  } else {
    stop("Unsupported provider.")
  }
}
