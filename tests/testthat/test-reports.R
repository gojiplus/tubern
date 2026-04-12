context("Reports endpoint")

## Test get_report against recorded fixture

test_that("get_report returns parsed list from fixture", {
  skip_on_cran()
  # Skip if no fixture is available
  fixture <- file.path(
    "tests", "testthat", "__httptest__", "GET-reports.json"
  )
  if (!file.exists(fixture)) {
    skip("No captured fixture for get_report. Run recording script to generate it.")
  }
  httptest::with_mock_api({
    res <- get_report(
      ids = "channel==MINE",
      metrics = "views",
      start_date = "2021-01-01",
      end_date = "2021-01-02"
    )
    expect_type(res, "list")
  })
})