## Test get_report against the recorded fixture

test_that("get_report returns a parsed list from the recorded fixture", {
  skip_on_cran()
  skip_if_not_installed("httptest2")

  # The fixture httptest2 actually looks up: host and path mirror the request
  # URL. The previous version of this test checked for
  # "tests/testthat/__httptest__/GET-reports.json" while running *from*
  # tests/testthat, so the path resolved a level too deep, the file was never
  # found, and the test skipped on every machine it has ever run on.
  fixture <- file.path(
    "youtubeanalytics.googleapis.com", "v2", "reports-c996af.json"
  )
  skip_if_not(file.exists(fixture), "No recorded fixture for get_report")

  withr::local_options(google_token = fake_token())

  httptest2::with_mock_api({
    res <- get_report(
      ids = "channel==MINE",
      metrics = "views",
      start_date = "2021-01-01",
      end_date = "2021-01-02"
    )
    expect_type(res, "list")
    expect_equal(res$kind, "youtubeAnalytics#resultTable")
    expect_equal(res$columnHeaders[[1]]$name, "views")
  })
})
