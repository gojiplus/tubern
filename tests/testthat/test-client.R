context("API client wrappers")

test_that("tubern_GET errors when no token is set", {
  old_token <- getOption("google_token")
  options(google_token = NULL)
  expect_error(
    tubern:::tubern_GET("reports"),
    "Please get a token using yt_oauth"
  )
  options(google_token = old_token)
})

test_that("API base URL constant is correct", {
  expect_identical(
    tubern:::.api_base,
    "https://youtubeanalytics.googleapis.com/v2"
  )
})