test_that("yt_to_dataframe handles parse_dates=FALSE correctly", {
  mock_response <- mock_api_response(
    rows = list(
      c("2023-01-01", "100"),
      c("2023-01-02", "200")
    ),
    column_headers = list(
      list(name = "day", dataType = "STRING"),
      list(name = "views", dataType = "INTEGER")
    ),
    query = list(
      startDate = "2023-01-01",
      endDate = "2023-01-02",
      metrics = "views",
      dimensions = "day"
    )
  )

  df_with_dates <- yt_to_dataframe(mock_response, parse_dates = TRUE)
  expect_s3_class(df_with_dates$day, "Date")

  df_without_dates <- yt_to_dataframe(mock_response, parse_dates = FALSE)
  expect_type(df_without_dates$day, "character")
})

test_that("yt_to_dataframe handles clean_names correctly", {
  mock_response <- mock_api_response(
    rows = list(c("123.45")),
    column_headers = list(
      list(name = "averageViewDuration", dataType = "FLOAT")
    ),
    query = list()
  )

  df_clean <- yt_to_dataframe(mock_response, clean_names = TRUE)
  expect_true("average_view_duration" %in% names(df_clean))

  df_original <- yt_to_dataframe(mock_response, clean_names = FALSE)
  expect_true("averageViewDuration" %in% names(df_original))
})

test_that("yt_to_dataframe returns NULL for invalid input", {
  expect_warning(result <- yt_to_dataframe(NULL))
  expect_null(result)

  expect_warning(result <- yt_to_dataframe("not a list"))
  expect_null(result)
})

test_that("yt_to_dataframe returns empty data.frame for empty rows", {
  mock_response <- list(
    columnHeaders = list(list(name = "views", dataType = "INTEGER")),
    rows = list()
  )

  expect_message(result <- yt_to_dataframe(mock_response))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("yt_extract_summary returns correct structure", {
  mock_response <- mock_api_response()

  summary <- yt_extract_summary(mock_response)
  expect_type(summary, "list")
  expect_equal(summary$total_rows, 2)
  expect_equal(summary$columns, 2)
})

test_that("yt_extract_summary handles empty response", {
  mock_response <- list(rows = NULL)
  summary <- yt_extract_summary(mock_response)
  expect_equal(summary$total_rows, 0)
})

test_that("yt_export_csv errors on empty data", {
  mock_response <- list(
    columnHeaders = list(list(name = "views", dataType = "INTEGER")),
    rows = list()
  )
  expect_error(
    yt_export_csv(mock_response),
    class = "tubern_parameter_error"
  )
})

test_that("yt_quick_plot errors on empty data", {
  mock_response <- list(
    columnHeaders = list(list(name = "views", dataType = "INTEGER")),
    rows = list()
  )
  expect_error(
    yt_quick_plot(mock_response),
    class = "tubern_parameter_error"
  )
})

test_that(".clean_column_names converts camelCase to snake_case", {
  result <- tubern:::.clean_column_names("averageViewDuration")
  expect_equal(result, "average_view_duration")

  result <- tubern:::.clean_column_names("estimatedMinutesWatched")
  expect_equal(result, "estimated_minutes_watched")
})

test_that(".parse_column_types handles INTEGER type", {
  df <- data.frame(views = "100", stringsAsFactors = FALSE)
  headers <- list(list(name = "views", dataType = "INTEGER"))

  result <- tubern:::.parse_column_types(df, headers, parse_dates = FALSE)
  expect_type(result$views, "double")
  expect_equal(result$views, 100)
})

test_that(".parse_column_types handles FLOAT type", {
  df <- data.frame(rate = "0.5", stringsAsFactors = FALSE)
  headers <- list(list(name = "rate", dataType = "FLOAT"))

  result <- tubern:::.parse_column_types(df, headers, parse_dates = FALSE)
  expect_type(result$rate, "double")
  expect_equal(result$rate, 0.5)
})
