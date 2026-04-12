context("Get Report")

test_that("get_report validates ids parameter format", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    mock_api_response()
  }
  with_api_stub(stub, {
    expect_error(
      get_report(ids = "invalid", metrics = "views",
                 start_date = "2023-01-01", end_date = "2023-01-31"),
      class = "tubern_parameter_error"
    )
  })
})

test_that("get_report validates metrics parameter", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    mock_api_response()
  }
  with_api_stub(stub, {
    expect_error(
      get_report(ids = "channel==MINE", metrics = "invalid_metric",
                 start_date = "2023-01-01", end_date = "2023-01-31"),
      class = "tubern_parameter_error"
    )
  })
})

test_that("get_report requires start_date", {
  expect_error(
    get_report(ids = "channel==MINE", metrics = "views"),
    class = "tubern_parameter_error"
  )
})

test_that("get_report validates date format", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    mock_api_response()
  }
  with_api_stub(stub, {
    expect_error(
      get_report(ids = "channel==MINE", metrics = "views",
                 start_date = "2023/01/01", end_date = "2023-01-31"),
      class = "tubern_parameter_error"
    )
  })
})

test_that("get_report constructs correct query with valid parameters", {
  captured_query <- NULL
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    captured_query <<- query
    mock_api_response()
  }
  with_api_stub(stub, {
    get_report(ids = "channel==MINE", metrics = "views",
               start_date = "2023-01-01", end_date = "2023-01-31")
    expect_equal(captured_query$metrics, "views")
    expect_equal(captured_query$startDate, "2023-01-01")
    expect_equal(captured_query$endDate, "2023-01-31")
  })
})

test_that("get_report handles multiple metrics", {
  captured_query <- NULL
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    captured_query <<- query
    mock_api_response()
  }
  with_api_stub(stub, {
    get_report(ids = "channel==MINE", metrics = "views,likes,comments",
               start_date = "2023-01-01", end_date = "2023-01-31")
    expect_equal(captured_query$metrics, "views,likes,comments")
  })
})

test_that("get_report validates max_results bounds", {
  stub <- function(method, path, query = NULL, body = NULL, ...) {
    mock_api_response()
  }
  with_api_stub(stub, {
    expect_error(
      get_report(ids = "channel==MINE", metrics = "views",
                 start_date = "2023-01-01", end_date = "2023-01-31",
                 max_results = 300),
      "max_results"
    )
  })
})

test_that("get_report with real API works", {
  skip_on_cran()
  skip_if_no_token()

  get_info <- get_report(ids = "channel==MINE", metrics = "views",
                         start_date = "2010-04-01", end_date = "2017-04-01")
  expect_type(get_info, "list")
})
