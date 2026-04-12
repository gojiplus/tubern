#' Test Helpers for tubern
#'
#' Helper functions and utilities for testing

#' Skip test if no OAuth token is available
#'
#' Use this for integration tests that require real API access.
#' Tests using this will be skipped on CRAN and CI without tokens.
#'
#' @return Invisibly returns NULL; skips the test if no token is available
#' @keywords internal
skip_if_no_token <- function() {
  token <- getOption("google_token")
  if (is.null(token)) {
    testthat::skip("No OAuth token available. Run yt_oauth() to test with real API.")
  }
}

#' Create a mock API response for testing
#'
#' @param rows List of rows (each row is a vector of values)
#' @param column_headers List of column header definitions
#' @param query Optional query metadata
#' @return A list mimicking a YouTube Analytics API response
#' @keywords internal
mock_api_response <- function(rows = NULL,
                              column_headers = NULL,
                              query = list()) {
  if (is.null(column_headers)) {
    column_headers <- list(
      list(name = "day", dataType = "STRING"),
      list(name = "views", dataType = "INTEGER")
    )
  }

  if (is.null(rows)) {
    rows <- list(
      c("2023-01-01", "100"),
      c("2023-01-02", "200")
    )
  }

  list(
    kind = "youtubeAnalytics#resultTable",
    columnHeaders = column_headers,
    rows = rows,
    query = query
  )
}

#' Create a stub for API request that returns a mock response
#'
#' @param response The mock response to return
#' @return A function that can replace .api_request for testing
#' @keywords internal
create_api_stub <- function(response) {
  function(method, path, query = NULL, body = NULL, ...) {
    response
  }
}

#' Temporarily replace .api_request with a stub for testing
#'
#' @param stub_fn The stub function to use
#' @param code The code to execute with the stub in place
#' @return The result of evaluating the code
#' @keywords internal
with_api_stub <- function(stub_fn, code) {
  orig <- getFromNamespace(".api_request", ns = "tubern")
  on.exit(assignInNamespace(".api_request", orig, ns = "tubern"))
  assignInNamespace(".api_request", stub_fn, ns = "tubern")
  force(code)
}
