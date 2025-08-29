context("Group Items endpoints")

test_that("add_group_item constructs correct API call", {
  resource_details <- list(groupId = "g1", resourceId = "r1")
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- add_group_item(resource_details)
  expect_equal(res$method, "POST")
  expect_equal(res$path, "groupItems")
  expect_null(res$query)
  expect_equal(res$body, jsonlite::toJSON(resource_details, auto_unbox = TRUE))
})

test_that("list_group_items constructs correct API call", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- list_group_items(group_id = "g1")
  expect_equal(res$method, "GET")
  expect_equal(res$path, "groupItems")
  expect_equal(res$query, c(groupId = "g1"))
  expect_null(res$body)
})

test_that("delete_group_item constructs correct API call", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- delete_group_item(id = "gi123")
  expect_equal(res$method, "DELETE")
  expect_equal(res$path, "groupItems")
  expect_equal(res$query, list(id = "gi123"))
  expect_equal(res$body, "")
})