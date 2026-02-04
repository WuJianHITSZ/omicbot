library(ellmer)

agent <- chat_openai_compatible(
  base_url = "https://dashscope.aliyuncs.com/compatible-mode/v1",
  model = "qwen-max",
  api_key = "sk-fb8787a0c0f747bfaa87dd2631bc5630"
)

agent$chat("hi")