context("API client wrappers")

test_that("tubern_GET errors when no token is set", {
  old_token <- getOption("google_token")
  options(google_token = NULL)
  expect_error(
    tubern:::tubern_GET("reports"),
    class = "tubern_auth_error"
  )
  options(google_token = old_token)
})

test_that("API base URL constant is correct", {
  expect_identical(
    tubern:::.api_base,
    "https://youtubeanalytics.googleapis.com/v2"
  )
})

test_that("yt_check_token throws tubern_auth_error when no token", {
  old_token <- getOption("google_token")
  options(google_token = NULL)
  expect_error(
    tubern:::yt_check_token(),
    class = "tubern_auth_error"
  )
  options(google_token = old_token)
})
