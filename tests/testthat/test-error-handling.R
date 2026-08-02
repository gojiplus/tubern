test_that("tubern_abort creates proper error class", {
  err <- tryCatch(
    tubern:::tubern_abort("test error", class = "auth"),
    error = function(e) e
  )
  expect_s3_class(err, "tubern_auth_error")
  expect_s3_class(err, "tubern_error")
  expect_s3_class(err, "rlang_error")
})

test_that("tubern_abort includes custom class in message", {
  err <- tryCatch(
    tubern:::tubern_abort("custom message", class = "quota"),
    error = function(e) e
  )
  expect_s3_class(err, "tubern_quota_error")
})

test_that("tubern_warn creates warning with proper class", {
  expect_warning(
    tubern:::tubern_warn("test warning", class = "parameter"),
    class = "tubern_parameter_warning"
  )
})

test_that(".parse_api_error handles 400 errors", {
  result <- tubern:::.parse_api_error(400, NULL)
  expect_equal(result$class, "parameter")
  expect_true(grepl("Bad request", result$message))
})

test_that(".parse_api_error handles 401 errors", {
  result <- tubern:::.parse_api_error(401, NULL)
  expect_equal(result$class, "auth")
  expect_true(grepl("Authentication", result$message))
})

test_that(".parse_api_error handles 403 quota errors", {
  error_content <- list(
    error = list(
      errors = list(
        list(reason = "quotaExceeded", message = "Quota exceeded")
      )
    )
  )
  result <- tubern:::.parse_api_error(403, error_content)
  expect_equal(result$class, "quota")
})

test_that(".parse_api_error handles 403 permission errors", {
  result <- tubern:::.parse_api_error(403, NULL)
  expect_equal(result$class, "auth")
  expect_true(grepl("forbidden", result$message, ignore.case = TRUE))
})

test_that(".parse_api_error handles 404 errors", {
  result <- tubern:::.parse_api_error(404, NULL)
  expect_equal(result$class, "api")
  expect_true(grepl("not found", result$message, ignore.case = TRUE))
})

test_that(".parse_api_error 404 message mentions channel access restrictions", {
  result <- tubern:::.parse_api_error(404, NULL)
  expect_true(grepl("channel==MINE", result$message))
  expect_true(grepl("your own authenticated channel", result$message, ignore.case = TRUE))
  expect_true(grepl("YouTube Partner content owner", result$message, ignore.case = TRUE))
})

test_that(".parse_api_error handles 429 errors", {
  result <- tubern:::.parse_api_error(429, NULL)
  expect_equal(result$class, "quota")
})

test_that(".parse_api_error handles 500 errors", {
  result <- tubern:::.parse_api_error(500, NULL)
  expect_equal(result$class, "api")
  expect_true(grepl("server error", result$message, ignore.case = TRUE))
})

test_that(".parse_api_error handles unknown errors", {
  result <- tubern:::.parse_api_error(418, NULL)
  expect_equal(result$class, "api")
  expect_true(grepl("418", result$message))
})

test_that("error classes can be caught specifically", {
  caught <- FALSE
  tryCatch(
    tubern:::tubern_abort("auth error", class = "auth"),
    tubern_auth_error = function(e) {
      caught <<- TRUE
    }
  )
  expect_true(caught)
})

test_that("error classes can be caught generically", {
  caught <- FALSE
  tryCatch(
    tubern:::tubern_abort("some error", class = "parameter"),
    tubern_error = function(e) {
      caught <<- TRUE
    }
  )
  expect_true(caught)
})
