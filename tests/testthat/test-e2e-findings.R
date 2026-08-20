## Two defects the live end-to-end run found. Both are asserted offline here so
## CRAN and CI cover them; test-e2e-live.R re-checks the first against the real
## API when TUBERN_E2E is set.

test_that("get_audience_demographics() asks for a metric the report supports", {
  # The default was c("views", "estimatedMinutesWatched"). The viewer
  # demographics report supports neither: the API answers 400 "The query is not
  # supported" for those metrics against ageGroup/gender, so this function could
  # never succeed as documented. Confirmed live -- viewerPercentage returns 200
  # with ageGroup, gender, or both; views returns 400 with either.
  # The default is a plain string, so formals() gives it directly -- no eval().
  expect_identical(formals(get_audience_demographics)$metrics, "viewerPercentage")

  # And it is accepted by the local validator, so the request is actually built.
  validate <- getFromNamespace(".validate_metrics", "tubern")
  expect_no_error(validate("viewerPercentage"))
})

test_that("the demographics wrapper builds the query the API accepts", {
  # Assert on the assembled request rather than the constant, so a change to
  # how the wrapper passes metrics through is caught too.
  captured <- NULL
  testthat::local_mocked_bindings(
    tubern_GET = function(path, query, ...) {
      captured <<- list(path = path, query = query)
      list(kind = "youtubeAnalytics#resultTable", columnHeaders = list(), rows = list())
    },
    .package = "tubern"
  )
  suppressMessages(get_audience_demographics("2023-01-01", "2023-12-31"))

  expect_identical(captured$path, "reports")
  expect_identical(captured$query$metrics, "viewerPercentage")
  expect_identical(captured$query$dimensions, "ageGroup,gender")
})

test_that("yt_to_dataframe() does not attach empty query metadata", {
  # reports.query returns kind/columnHeaders/rows and no $query member, so the
  # old unconditional attr() put a list of four NULLs on every frame. An
  # attribute that is always empty is worse than no attribute: it invites code
  # that reads it.
  resp <- list(
    kind = "youtubeAnalytics#resultTable",
    columnHeaders = list(
      list(name = "day", columnType = "DIMENSION", dataType = "STRING"),
      list(name = "views", columnType = "METRIC", dataType = "INTEGER")
    ),
    rows = list(list("2023-02-25", 3L), list("2023-02-26", 3L))
  )
  df <- yt_to_dataframe(resp)
  expect_null(attr(df, "query"))
})

test_that("query metadata is carried when a response does supply it", {
  # The other half: the attribute is conditional, not deleted, so a response
  # that does carry a query still surfaces it.
  resp <- list(
    kind = "youtubeAnalytics#resultTable",
    columnHeaders = list(
      list(name = "views", columnType = "METRIC", dataType = "INTEGER")
    ),
    rows = list(list(7L)),
    query = list(
      startDate = "2023-01-01", endDate = "2023-12-31",
      metrics = "views", dimensions = NULL
    )
  )
  df <- yt_to_dataframe(resp)
  q <- attr(df, "query")
  expect_false(is.null(q))
  expect_identical(q$start_date, "2023-01-01")
  expect_identical(q$metrics, "views")
})

test_that("a real-shaped response converts to atomic columns", {
  # rows arrive as a list of lists with mixed element types, so
  # do.call(rbind, rows) builds a list-matrix. If the type coercion stops
  # running these silently become list columns and every downstream sum() fails
  # with a confusing error rather than a clear one.
  resp <- list(
    kind = "youtubeAnalytics#resultTable",
    columnHeaders = list(
      list(name = "day", columnType = "DIMENSION", dataType = "STRING"),
      list(name = "views", columnType = "METRIC", dataType = "INTEGER"),
      list(name = "estimatedMinutesWatched", columnType = "METRIC", dataType = "INTEGER")
    ),
    rows = list(list("2023-02-25", 3L, 2L), list("2023-02-26", 3L, 0L))
  )
  df <- yt_to_dataframe(resp)

  expect_identical(names(df), c("day", "views", "estimated_minutes_watched"))
  for (n in names(df)) expect_false(is.list(df[[n]]), info = n)
  expect_s3_class(df$day, "Date")
  expect_equal(sum(df$views), 6)
})

test_that("a month column is left alone rather than turned into NA", {
  # The API returns "2023-02" for the month dimension, which as.Date() cannot
  # parse. .parse_column_types() must leave it as character.
  resp <- list(
    kind = "youtubeAnalytics#resultTable",
    columnHeaders = list(
      list(name = "month", columnType = "DIMENSION", dataType = "STRING"),
      list(name = "views", columnType = "METRIC", dataType = "INTEGER")
    ),
    rows = list(list("2023-02", 6L), list("2023-08", 2L))
  )
  df <- yt_to_dataframe(resp)
  expect_type(df$month, "character")
  expect_false(anyNA(df$month))
  expect_identical(df$month, c("2023-02", "2023-08"))
})
