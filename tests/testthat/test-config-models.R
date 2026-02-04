test_that("config write/read roundtrip includes streaming", {
  tmp_dir <- tempfile("omicbot-config-")
  dir.create(tmp_dir, recursive = TRUE)
  cfg <- file.path(tmp_dir, "config.json")

  omicbot:::.omicbot_write_config(
    config_path = cfg,
    config_dir = tmp_dir,
    provider = "openai",
    model = "gpt-5-mini",
    streaming = "enabled"
  )

  out <- omicbot:::.omicbot_read_config(cfg)
  expect_identical(out$provider, "openai")
  expect_identical(out$model, "gpt-5-mini")
  expect_identical(out$streaming, "enabled")
})

test_that("read config defaults when file is missing or incomplete", {
  missing <- file.path(tempdir(), paste0("missing-", as.integer(runif(1, 1, 1e9)), ".json"))
  out_missing <- omicbot:::.omicbot_read_config(missing)
  expect_null(out_missing$provider)
  expect_null(out_missing$model)
  expect_identical(out_missing$streaming, "disabled")

  tmp <- tempfile(fileext = ".json")
  writeLines('{"provider":"openai","model":"gpt-5-mini"}', tmp)
  out_partial <- omicbot:::.omicbot_read_config(tmp)
  expect_identical(out_partial$streaming, "disabled")
})

test_that("provider and model option helpers return expected values", {
  providers <- omicbot:::.omicbot_provider_options()
  expect_true(all(c("openai", "google", "deepseek", "alibaba", "ollama") %in% providers))

  openai_models <- omicbot:::.omicbot_model_options("openai")
  expect_true(all(c("gpt-5.2", "gpt-5.2-codex", "gpt-5-mini") %in% openai_models))

  expect_error(omicbot:::.omicbot_model_options("unknown"), "Unsupported provider")
})
