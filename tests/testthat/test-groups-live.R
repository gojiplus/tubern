test_that("group management lifecycle works", {
  skip_on_cran()
  skip_if_no_token()

  test_group_id <- NULL

  withr::defer({
    if (!is.null(test_group_id)) {
      try(delete_group(id = test_group_id), silent = TRUE)
    }
  })

  test_group <- add_groups(list(
    snippet = list(
      title = "tubern_test_group",
      description = "Test group created by tubern tests"
    ),
    contentDetails = list(itemType = "youtube#video")
  ))

  expect_true(!is.null(test_group$id))
  expect_equal(test_group$snippet$title, "tubern_test_group")
  test_group_id <- test_group$id

  groups <- list_groups(filter = c(mine = TRUE))
  expect_true(!is.null(groups$items))
  group_ids <- vapply(groups$items, function(x) x$id, character(1))
  expect_true(test_group_id %in% group_ids)

  updated <- update_group(list(
    id = test_group_id,
    snippet = list(title = "tubern_test_group_updated")
  ))
  expect_equal(updated$snippet$title, "tubern_test_group_updated")

  delete_group(id = test_group_id)
  test_group_id <- NULL

  groups_after <- list_groups(filter = c(mine = TRUE))
  if (!is.null(groups_after$items) && length(groups_after$items) > 0) {
    get_id <- function(x) x$id
    group_ids_after <- vapply(groups_after$items, get_id, character(1))
    expect_false(updated$id %in% group_ids_after)
  }
})
