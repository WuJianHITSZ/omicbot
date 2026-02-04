test_that("provider to env var mapping is stable", {
  expect_identical(omicbot:::.omicbot_api_key_var("openai"), "OPENAI_API_KEY")
  expect_identical(omicbot:::.omicbot_api_key_var("google"), "GOOGLE_API_KEY")
  expect_identical(omicbot:::.omicbot_api_key_var("deepseek"), "DEEPSEEK_API_KEY")
  expect_identical(omicbot:::.omicbot_api_key_var("alibaba"), "DASHSCOPE_API_KEY")
  expect_null(omicbot:::.omicbot_api_key_var("ollama"))
  expect_error(omicbot:::.omicbot_api_key_var("unknown"), "Unsupported provider")
})

test_that("api key read/write/erase lifecycle works", {
  tmp <- tempfile(fileext = ".env")
  env_var <- "OPENAI_API_KEY"

  expect_identical(omicbot:::.omicbot_read_api_key(tmp, env_var), "")

  omicbot:::.omicbot_write_api_key(tmp, env_var, "abc123")
  expect_identical(omicbot:::.omicbot_read_api_key(tmp, env_var), "abc123")

  omicbot:::.omicbot_write_api_key(tmp, env_var, "xyz789")
  expect_identical(omicbot:::.omicbot_read_api_key(tmp, env_var), "xyz789")

  expect_true(omicbot:::.omicbot_erase_api_key(tmp, env_var))
  expect_identical(omicbot:::.omicbot_read_api_key(tmp, env_var), "")
})

test_that("openai-compatible base url defaults and override work", {
  withr::local_envvar(DASHSCOPE_BASE_URL = NA)
  expect_identical(
    omicbot:::.omicbot_openai_compatible_base_url("alibaba"),
    "https://dashscope.aliyuncs.com/compatible-mode/v1"
  )

  withr::local_envvar(DASHSCOPE_BASE_URL = "https://example.com/v1")
  expect_identical(
    omicbot:::.omicbot_openai_compatible_base_url("alibaba"),
    "https://example.com/v1"
  )

  expect_null(omicbot:::.omicbot_openai_compatible_base_url("openai"))
})
