context("Get Basic Report")

test_that("get_details runs successfully", {

  skip_on_cran()

  # Try to load token file, skip if not available or corrupted
  token_file <- "token_file.rds.enc"
  if (!file.exists(token_file)) {
    skip("No token file available")
  }
  
  google_token <- tryCatch({
    readRDS(token_file)
  }, error = function(e) {
    skip("Token file corrupted or unreadable")
  })
  
  if (is.null(google_token)) {
    skip("No OAuth token available")
  }
  
  options(google_token = google_token[[1]])

  get_info <- get_report(ids = "channel==MINE", metrics = "views",
                         start_date = "2010-04-01", end_date = "2017-04-01")
  expect_that(get_info, is_a("list"))
})
