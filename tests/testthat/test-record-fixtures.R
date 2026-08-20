## Manual script to record API fixture for get_report

test_that("record get_report fixture", {
  skip_on_cran()
  # Recording is opt-in by an explicit variable, not by a token happening to
  # be reachable. A stale .httr-oauth in the package root is enough for
  # skip_if_no_token() to set options(google_token), and that alone was enough
  # to start this test: it called the live API, got a 401, and wrote the
  # failure to youtubeanalytics.googleapis.com/v2/reports-c996af.R -- beside
  # the real fixture in reports-c996af.json. httptest prefers the .R file, so
  # committing that would have replayed a 401 as the API's answer from then on.
  skip_if(
    !identical(Sys.getenv("TUBERN_RECORD"), "true"),
    "Set TUBERN_RECORD=true to re-record fixtures against the live API"
  )
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
