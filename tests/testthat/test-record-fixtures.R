context("Recording API fixtures")

## Manual script to record API fixture for get_report

test_that("record get_report fixture", {
  skip_on_cran()
  # Requires an OAuth token in options(google_token)
  if (is.null(getOption("google_token"))) {
    skip("No OAuth token available to record fixtures")
  }
  httptest::capture_requests({
    # call the real API; requires valid OAuth token
    get_report(
      ids = "channel==MINE",
      metrics = "views",
      start_date = "2021-01-01",
      end_date = "2021-01-02"
    )
  })
})