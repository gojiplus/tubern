test_that(".validate_metrics rejects empty metrics", {
  expect_error(
    tubern:::.validate_metrics(NULL),
    class = "tubern_parameter_error"
  )
  expect_error(
    tubern:::.validate_metrics(character(0)),
    class = "tubern_parameter_error"
  )
})

test_that(".validate_metrics accepts valid metrics", {
  result <- tubern:::.validate_metrics("views")
  expect_equal(result, "views")

  result <- tubern:::.validate_metrics(c("views", "likes"))
  expect_equal(result, c("views", "likes"))
})

test_that(".validate_metrics handles comma-separated string", {
  result <- tubern:::.validate_metrics("views,likes,comments")
  expect_equal(result, c("views", "likes", "comments"))
})

test_that(".validate_metrics warns about unknown metrics with suggestions", {
  cnd <- tryCatch(
    tubern:::.validate_metrics("viewz"),
    tubern_parameter_warning = function(w) w
  )
  expect_true(grepl("Unrecognised metric", conditionMessage(cnd)))
  expect_true(grepl("did you mean", conditionMessage(cnd)))
})

test_that(".validate_metrics still sends the unknown metric on to the API", {
  expect_warning(out <- tubern:::.validate_metrics("viewz"))
  expect_equal(out, "viewz")
})

test_that(".validate_dimensions accepts valid dimensions", {
  result <- tubern:::.validate_dimensions("day")
  expect_equal(result, "day")

  result <- tubern:::.validate_dimensions(c("day", "country"))
  expect_equal(result, c("day", "country"))
})

test_that(".validate_dimensions handles NULL", {
  result <- tubern:::.validate_dimensions(NULL)
  expect_null(result)
})

test_that(".validate_dimensions rejects filter-only dimensions", {
  expect_error(
    tubern:::.validate_dimensions("continent"),
    class = "tubern_parameter_error"
  )
})

test_that(".validate_dimensions enforces requirements", {
  expect_error(
    tubern:::.validate_dimensions("province", filters = NULL),
    class = "tubern_parameter_error"
  )

  result <- tubern:::.validate_dimensions("province", filters = "country==US")
  expect_equal(result, "province")
})

test_that(".validate_dates requires both dates", {
  expect_error(
    tubern:::.validate_dates(NULL, "2023-01-31"),
    class = "tubern_parameter_error"
  )
  expect_error(
    tubern:::.validate_dates("2023-01-01", NULL),
    class = "tubern_parameter_error"
  )
})

test_that(".validate_dates validates format", {
  expect_error(
    tubern:::.validate_dates("2023/01/01", "2023-01-31"),
    class = "tubern_parameter_error"
  )
  expect_error(
    tubern:::.validate_dates("2023-01-01", "Jan 31, 2023"),
    class = "tubern_parameter_error"
  )
})

test_that(".validate_dates validates date order", {
  expect_error(
    tubern:::.validate_dates("2023-01-31", "2023-01-01"),
    class = "tubern_parameter_error"
  )
})

test_that(".validate_dates accepts valid dates", {
  result <- tubern:::.validate_dates("2023-01-01", "2023-01-31")
  expect_equal(result$start_date, "2023-01-01")
  expect_equal(result$end_date, "2023-01-31")
})

test_that(".validate_filters requires == syntax", {
  expect_error(
    tubern:::.validate_filters("country=US"),
    class = "tubern_parameter_error"
  )
})

test_that(".validate_filters accepts valid filters", {
  result <- tubern:::.validate_filters("country==US")
  expect_equal(result, "country==US")

  result <- tubern:::.validate_filters("country==US;video==abc123", dimensions = "video")
  expect_equal(result, "country==US;video==abc123")
})

test_that(".validate_filters handles NULL", {
  result <- tubern:::.validate_filters(NULL)
  expect_null(result)
})

test_that(".validate_filters warns when filtering by video without video dimension", {
  expect_warning(
    tubern:::.validate_filters("video==abc123", dimensions = NULL),
    "Filtering by video without dimensions='video'",
    class = "tubern_parameter_warning"
  )

  expect_warning(
    tubern:::.validate_filters("video==abc123,def456", dimensions = "day"),
    "Filtering by video without dimensions='video'",
    class = "tubern_parameter_warning"
  )

  expect_silent(
    tubern:::.validate_filters("video==abc123", dimensions = "video")
  )

  expect_silent(
    tubern:::.validate_filters("video==abc123", dimensions = c("video", "day"))
  )
})

test_that("get_available_metrics returns valid metrics", {
  metrics <- get_available_metrics()
  expect_type(metrics, "character")
  expect_true(length(metrics) > 0)
  expect_true("views" %in% names(metrics))
})

test_that("get_available_metrics filters by pattern", {
  metrics <- get_available_metrics("view")
  expect_true(all(grepl("view", names(metrics), ignore.case = TRUE) |
                  grepl("view", metrics, ignore.case = TRUE)))
})

test_that("get_available_dimensions returns valid dimensions", {
  dimensions <- get_available_dimensions()
  expect_type(dimensions, "character")
  expect_true(length(dimensions) > 0)
  expect_true("day" %in% names(dimensions))
})
