# The old names must keep working, and must keep returning what they did.
# A deprecation shim that quietly changes behaviour is worse than a clean
# break, because nobody looks.

fake_report <- function() {
  list(
    columnHeaders = list(list(name = "views", dataType = "INTEGER")),
    rows = list(list(5))
  )
}

test_that("renamed functions still answer to their old names", {
  for (old in c("add_groups", "yt_to_dataframe", "yt_to_tibble", "diagnose_tubern")) {
    expect_true(old %in% getNamespaceExports("tubern"), info = old)
  }
})

test_that("an old name warns and returns what the new one returns", {
  expect_warning(
    old <- yt_to_dataframe(fake_report()),
    class = "tubern_deprecated_warning"
  )
  new <- yt_as_data_frame(fake_report())
  expect_identical(old, new)
})

test_that("the new names do not warn", {
  expect_no_warning(yt_as_data_frame(fake_report()))
})
