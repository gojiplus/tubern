context("Groups endpoints")

test_that("add_groups constructs correct API call", {
  resource_details <- list(
    etag = "etag123",
    snippet = list(title = "hello"),
    contentDetails = list(itemType = "youtube#channel")
  )
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- add_groups(resource_details)
  expect_equal(res$method, "POST")
  expect_equal(res$path, "groups")
  expect_null(res$query)
  expect_equal(res$body, jsonlite::toJSON(resource_details, auto_unbox = TRUE))
})

test_that("list_groups constructs correct API call", {
  filter <- c(mine = "True")
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- list_groups(filter = filter)
  expect_equal(res$method, "GET")
  expect_equal(res$path, "groups")
  expect_equal(res$query, as.list(filter))
  expect_null(res$body)
})

test_that("update_group constructs correct API call", {
  resource_details <- list(id = "grp123", snippet = list(title = "updated"))
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- update_group(resource_details)
  expect_equal(res$method, "PUT")
  expect_equal(res$path, "groups")
  expect_null(res$query)
  expect_equal(res$body, jsonlite::toJSON(resource_details, auto_unbox = TRUE))
})

test_that("delete_group constructs correct API call", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    list(method = method, path = path, query = query, body = body)
  }
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub, ns = "tubern")
  res <- delete_group(id = "grp123")
  expect_equal(res$method, "DELETE")
  expect_equal(res$path, "groups")
  expect_equal(res$query, list(id = "grp123"))
  expect_equal(res$body, "")
})