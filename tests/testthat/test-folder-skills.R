test_that("folder skills are discovered and readable from config skills dir", {
  tmp_config <- tempfile("omicbot-config-")
  dir.create(tmp_config, recursive = TRUE)
  withr::local_envvar(
    RSTUDIO_CONFIG_HOME = NA,
    XDG_CONFIG_HOME = tmp_config
  )

  skill_dir <- file.path(tmp_config, "rstudio", "omicbot", "skills", "demo")
  dir.create(skill_dir, recursive = TRUE)
  writeLines(c("# Demo Skill", "", "Use this skill for demo workflows."), file.path(skill_dir, "SKILL.md"))

  skills <- omicbot::list_skills()
  expect_true("demo" %in% skills$name)
  expect_identical(omicbot:::.omicbot_tool_read_skill("demo"), "# Demo Skill\n\nUse this skill for demo workflows.")
})

test_that("install_skill copies a skill folder into the config skills dir", {
  tmp_config <- tempfile("omicbot-config-")
  dir.create(tmp_config, recursive = TRUE)
  withr::local_envvar(
    RSTUDIO_CONFIG_HOME = NA,
    XDG_CONFIG_HOME = tmp_config
  )

  src <- tempfile("source-skill-")
  dir.create(src, recursive = TRUE)
  writeLines(c("# Copied Skill", "", "Copied by install_skill()."), file.path(src, "SKILL.md"))

  dest <- omicbot::install_skill(src, name = "copied")
  expect_true(file.exists(file.path(dest, "SKILL.md")))
  expect_true(dir.exists(file.path(tmp_config, "rstudio", "omicbot", "skills", "copied")))
})

test_that("create_skill scaffolds a valid folder skill", {
  parent <- tempfile("skill-parent-")

  dest <- omicbot::create_skill(
    "newskill",
    path = parent,
    title = "New Skill",
    description = "Use this skill for new workflows.",
    tools = TRUE
  )

  expect_true(dir.exists(dest))
  expect_true(file.exists(file.path(dest, "SKILL.md")))
  expect_true(file.exists(file.path(dest, "tools.R")))
  expect_match(readLines(file.path(dest, "SKILL.md"), warn = FALSE)[[1]], "# New Skill", fixed = TRUE)

  tmp_config <- tempfile("omicbot-config-")
  dir.create(tmp_config, recursive = TRUE)
  withr::local_envvar(
    RSTUDIO_CONFIG_HOME = NA,
    XDG_CONFIG_HOME = tmp_config
  )
  installed <- omicbot::install_skill(dest)
  expect_true(file.exists(file.path(installed, "SKILL.md")))
  expect_true("newskill" %in% omicbot::list_skills()$name)
})

test_that("folder skill tools are loaded through tools.R", {
  tmp_config <- tempfile("omicbot-config-")
  dir.create(tmp_config, recursive = TRUE)
  withr::local_envvar(
    RSTUDIO_CONFIG_HOME = NA,
    XDG_CONFIG_HOME = tmp_config
  )

  skill_dir <- file.path(tmp_config, "rstudio", "omicbot", "skills", "toolskill")
  dir.create(skill_dir, recursive = TRUE)
  writeLines("# Tool Skill", file.path(skill_dir, "SKILL.md"))
  writeLines(
    c(
      "omicbot_skill_tools <- function(skill) {",
      "  list(ellmer::tool(function() 'ok', name = 'toolskill_ok', description = 'Return ok.'))",
      "}"
    ),
    file.path(skill_dir, "tools.R")
  )

  registered <- list()
  agent <- new.env(parent = emptyenv())
  agent$register_tool <- function(tool) {
    registered[[length(registered) + 1L]] <<- tool
    invisible(TRUE)
  }

  n_loaded <- omicbot::load_skills(agent)
  expect_true(n_loaded >= 1L)
  expect_length(registered, n_loaded)
})
