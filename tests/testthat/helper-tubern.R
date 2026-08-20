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
    # Fall back to the httr cache. Only yt_oauth() sets the option, and no test
    # calls it, so this check could never pass on any machine -- the two live
    # tests skipped everywhere, always, including where a working token was
    # sitting in the package root the whole time.
    token <- tryCatch(
      {
        cache <- ".httr-oauth"
        if (!file.exists(cache)) cache <- file.path("..", "..", ".httr-oauth")
        if (!file.exists(cache)) {
          NULL
        } else {
          cached <- readRDS(cache)
          keep <- Filter(function(x) inherits(x, "Token2.0"), cached)
          if (length(keep) == 0) NULL else keep[[1]]
        }
      },
      error = function(e) NULL
    )

    if (is.null(token)) {
      testthat::skip("No OAuth token available. Run yt_oauth() to test with real API.")
    }
    options(google_token = token)
  }
  invisible(NULL)
}

#' Skip unless end-to-end tests are explicitly enabled
#'
#' These call the live API and consume real quota, so a token alone is not
#' enough to opt in -- a contributor with a stale .httr-oauth should not start
#' issuing requests because they ran the suite.
#'
#' @return Invisibly NULL; skips unless TUBERN_E2E is set to a truthy value
#' @keywords internal
skip_if_not_e2e <- function() {
  flag <- tolower(Sys.getenv("TUBERN_E2E", ""))
  if (!flag %in% c("1", "true", "yes")) {
    testthat::skip("Set TUBERN_E2E=true to run live end-to-end tests.")
  }
  skip_if_no_token()
  invisible(NULL)
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
