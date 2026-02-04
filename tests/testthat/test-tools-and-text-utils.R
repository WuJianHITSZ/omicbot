test_that("read/write/list file tools basic behavior", {
  tmp_dir <- tempfile("omicbot-tools-")
  dir.create(tmp_dir, recursive = TRUE)
  file_path <- file.path(tmp_dir, "notes.txt")

  msg <- omicbot:::.omicbot_tool_write_file(file_path, "hello")
  expect_match(msg, "Wrote")
  expect_identical(omicbot:::.omicbot_tool_read_file(file_path), "hello")

  msg2 <- omicbot:::.omicbot_tool_write_file(file_path, "world", append = TRUE)
  expect_match(msg2, "Wrote")
  expect_true("notes.txt" %in% omicbot:::.omicbot_tool_list_files(tmp_dir))
})

test_that("search_files finds matching content", {
  tmp_dir <- tempfile("omicbot-search-")
  dir.create(tmp_dir, recursive = TRUE)
  writeLines(c("one", "FindMe", "three"), file.path(tmp_dir, "a.txt"))
  writeLines(c("none"), file.path(tmp_dir, "b.txt"))

  hits <- omicbot:::.omicbot_tool_search_files("FindMe", path = tmp_dir)
  expect_true(length(hits) >= 1)
  expect_true(any(grepl("a.txt:2:FindMe$", hits)))
})
