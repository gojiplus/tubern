## End-to-end tests against the live YouTube Analytics API, covering the whole
## path: request -> response -> yt_to_dataframe() -> usable numbers.
##
## Nothing here ran before. skip_if_no_token() only consulted
## getOption("google_token"), which nothing but yt_oauth() sets, so the two
## pre-existing "live" tests skipped on every machine -- and the one that
## existed asserted only expect_type(x, "list"), which an error body satisfies.
##
## These are gated on TUBERN_E2E as well as a token: they spend real quota, and
## a contributor with a stale .httr-oauth should not start issuing requests
## because they ran the suite.
##
## The assertions are identities rather than golden numbers. A channel's view
## count changes; that its per-day figures sum to its undimensioned total does
## not.

WINDOW <- c("2015-01-01", "2026-06-30")

e2e_report <- function(...) {
  get_report(ids = "channel==MINE", ...)
}

test_that("a real response has the documented envelope", {
  skip_if_not_e2e()
  r <- e2e_report(
    metrics = "views,estimatedMinutesWatched", dimensions = "day",
    start_date = WINDOW[1], end_date = WINDOW[2]
  )

  expect_type(r, "list")
  expect_identical(r$kind, "youtubeAnalytics#resultTable")
  expect_true(is.list(r$columnHeaders))
  expect_true(is.list(r$rows))

  # One header per requested dimension and metric, in the order requested.
  expect_length(r$columnHeaders, 3L)
  expect_identical(
    vapply(r$columnHeaders, function(h) h$name, character(1)),
    c("day", "views", "estimatedMinutesWatched")
  )
  for (h in r$columnHeaders) {
    expect_true(all(c("name", "columnType", "dataType") %in% names(h)))
    expect_true(h$columnType %in% c("DIMENSION", "METRIC"))
    expect_true(h$dataType %in% c("STRING", "INTEGER", "FLOAT"))
  }
  # Every row is as wide as the header.
  expect_true(all(lengths(r$rows) == length(r$columnHeaders)))
})

test_that("yt_to_dataframe() turns that into a frame of the right shape and types", {
  skip_if_not_e2e()
  r <- e2e_report(
    metrics = "views,estimatedMinutesWatched", dimensions = "day",
    start_date = WINDOW[1], end_date = WINDOW[2]
  )
  df <- yt_to_dataframe(r)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), length(r$rows))
  expect_equal(ncol(df), length(r$columnHeaders))
  expect_identical(names(df), c("day", "views", "estimated_minutes_watched"))

  # rows arrive as a list of lists, so do.call(rbind, ...) builds a list-matrix.
  # If the type coercion ever stops running, these become list columns and every
  # downstream sum() breaks -- assert the columns are atomic, not just present.
  for (n in names(df)) expect_false(is.list(df[[n]]), info = n)

  expect_s3_class(df$day, "Date")
  expect_type(df$views, "double")
  expect_type(df$estimated_minutes_watched, "double")
  expect_false(anyNA(df$views))
  expect_true(all(df$views >= 0))
})

test_that("per-day figures sum to the undimensioned total", {
  skip_if_not_e2e()
  # The identity that makes the numbers mean something: if parsing dropped,
  # duplicated or misaligned a row, this stops holding.
  total <- as.numeric(
    e2e_report(
      metrics = "views",
      start_date = WINDOW[1], end_date = WINDOW[2]
    )$rows[[1]][[1]]
  )
  daily <- yt_to_dataframe(
    e2e_report(
      metrics = "views", dimensions = "day",
      start_date = WINDOW[1], end_date = WINDOW[2]
    )
  )

  expect_equal(sum(daily$views), total)
  expect_true(all(daily$day >= as.Date(WINDOW[1])))
  expect_true(all(daily$day <= as.Date(WINDOW[2])))
  expect_false(anyDuplicated(daily$day) > 0)
})

test_that("sort and max_results are honoured", {
  skip_if_not_e2e()
  df <- yt_to_dataframe(
    e2e_report(
      metrics = "views", dimensions = "day",
      start_date = WINDOW[1], end_date = WINDOW[2],
      sort = "-views", max_results = 5
    )
  )
  expect_lte(nrow(df), 5L)
  expect_false(is.unsorted(rev(df$views)))
})

test_that("metrics come back as columns in the order requested", {
  skip_if_not_e2e()
  a <- yt_to_dataframe(e2e_report(
    metrics = "views,estimatedMinutesWatched",
    start_date = WINDOW[1], end_date = WINDOW[2]
  ))
  b <- yt_to_dataframe(e2e_report(
    metrics = "estimatedMinutesWatched,views",
    start_date = WINDOW[1], end_date = WINDOW[2]
  ))
  expect_identical(names(a), c("views", "estimated_minutes_watched"))
  expect_identical(names(b), c("estimated_minutes_watched", "views"))
  # Same underlying quantities, just transposed.
  expect_equal(a$views, b$views)
  expect_equal(a$estimated_minutes_watched, b$estimated_minutes_watched)
})

test_that("the month dimension survives conversion without being mangled", {
  skip_if_not_e2e()
  # The API returns "2023-02", which is not a parseable date. .parse_column_types()
  # tries as.Date() on any column called month and must leave it alone when that
  # fails, rather than turning the column into NA.
  #
  # Note the window: the month dimension requires BOTH bounds to be the first of
  # a month. 2023-01-01..2023-12-31 is rejected by the API, which is why this
  # test does not use WINDOW.
  r <- e2e_report(
    metrics = "views", dimensions = "month",
    start_date = "2023-01-01", end_date = "2023-12-01"
  )
  df <- yt_to_dataframe(r)

  expect_type(df$month, "character")
  expect_false(anyNA(df$month))
  expect_true(all(grepl("^\\d{4}-\\d{2}$", df$month)))
  expect_equal(sum(df$views), sum(vapply(r$rows, function(x) as.numeric(x[[2]]), numeric(1))))
})

test_that("a window with no data yields an empty frame, not an error", {
  skip_if_not_e2e()
  r <- e2e_report(
    metrics = "views", dimensions = "day",
    start_date = "2019-01-01", end_date = "2019-01-07"
  )
  expect_length(r$rows, 0L)

  df <- expect_no_error(suppressMessages(yt_to_dataframe(r)))
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0L)
  expect_false(is.null(df))
})

test_that("yt_to_tibble() matches yt_to_dataframe() apart from class", {
  skip_if_not_e2e()
  skip_if_not_installed("tibble")
  r <- e2e_report(
    metrics = "views", dimensions = "day",
    start_date = WINDOW[1], end_date = WINDOW[2]
  )
  df <- yt_to_dataframe(r)
  tb <- yt_to_tibble(r)

  expect_s3_class(tb, "tbl_df")
  expect_identical(names(tb), names(df))
  expect_equal(nrow(tb), nrow(df))
  expect_equal(tb$views, df$views)
})

test_that("the metrics 0.5.1 removed are in fact rejected by the API", {
  skip_if_not_e2e()
  # 0.5.1 dropped these from .valid_metrics on the strength of the reference
  # page alone. Removing a metric that works would be the same defect the
  # release set out to fix, only inverted, so pin it against the live endpoint:
  # the API answers 400 "The query is not supported."
  for (m in c("videoThumbnailImpressions", "videoThumbnailImpressionsClickRate")) {
    # Rejected locally, before a request is made.
    expect_error(e2e_report(metrics = m, start_date = WINDOW[1], end_date = WINDOW[2]),
      "Invalid metric",
      info = m
    )
  }

  # And rejected by the API when the local check is bypassed, which is the part
  # that proves the local rejection is right rather than merely consistent.
  tok <- getOption("google_token")
  for (m in c("videoThumbnailImpressions", "videoThumbnailImpressionsClickRate")) {
    resp <- live_get(tok, list(
      ids = "channel==MINE", startDate = WINDOW[1],
      endDate = WINDOW[2], metrics = m
    ))
    expect_equal(resp, 400L, info = m)
  }
})

test_that("dimensions 0.5.1 added are accepted by the API", {
  skip_if_not_e2e()
  # Paired with the metric each report actually requires. Pairing them all with
  # "views" produces a 400 that says nothing about whether the dimension exists.
  tok <- getOption("google_token")
  ok <- function(q) {
    live_get(tok, c(list(
      ids = "channel==MINE", startDate = "2015-01-01",
      endDate = "2026-06-30"
    ), q))
  }
  expect_equal(ok(list(metrics = "views", dimensions = "creatorContentType")), 200L)
  expect_equal(ok(list(
    metrics = "views", dimensions = "insightPlaybackLocationDetail",
    filters = "insightPlaybackLocationType==EMBEDDED",
    sort = "-views", maxResults = 10
  )), 200L)
  expect_equal(ok(list(
    metrics = "membershipsCancellationSurveyResponses",
    dimensions = "membershipsCancellationSurveyReason"
  )), 200L)
  # dma does NOT require country==US, contrary to the release review's claim.
  expect_equal(ok(list(metrics = "views", dimensions = "dma")), 200L)
})

test_that("the reporting wrappers all return convertible responses", {
  skip_if_not_e2e()
  wrappers <- list(
    get_channel_overview = function() get_channel_overview("2023-01-01", "2023-12-31"),
    get_top_videos = function() get_top_videos("2023-01-01", "2023-12-31"),
    get_audience_demographics = function() get_audience_demographics("2023-01-01", "2023-12-31"),
    get_geographic_performance = function() get_geographic_performance("2023-01-01", "2023-12-31"),
    get_daily_performance = function() get_daily_performance("2023-01-01", "2023-12-31")
  )
  for (nm in names(wrappers)) {
    r <- tryCatch(wrappers[[nm]](), error = function(e) e)
    if (inherits(r, "error")) {
      fail(paste0(nm, " errored: ", conditionMessage(r)))
      next
    }
    expect_true(is.list(r), info = nm)
    expect_false(is.null(r$columnHeaders), info = nm)
    df <- suppressMessages(yt_to_dataframe(r))
    expect_s3_class(df, "data.frame")
    if (nrow(df) > 0) for (n in names(df)) expect_false(is.list(df[[n]]), info = paste(nm, n))
  }
})

test_that("get_revenue_report needs the monetary scope and says so", {
  skip_if_not_e2e()
  # Kept separate: this token carries yt-analytics.readonly, not
  # yt-analytics-monetary.readonly, so the API answers 401. That is the correct
  # outcome for this credential, and the point is that the failure is a clean
  # typed error rather than a parse crash.
  r <- tryCatch(get_revenue_report("2023-01-01", "2023-12-31"),
    error = function(e) e
  )
  if (inherits(r, "error")) {
    expect_s3_class(r, "tubern_error")
  } else {
    expect_true(is.list(r))
  }
})
