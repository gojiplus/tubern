## Routing a relative end_date through .get_end_date_for_range() fixed a real
## defect -- .parse_date_string() maps a range to its FIRST day, so a relative
## end_date used to end the report at the start of its window. But
## .get_end_date_for_range() carried a `switch` default of `today`, so it
## answered every unrecognised string instead of rejecting it, and the fix
## handed typos a silent wrong answer:
##
##   resolve_date_range("2024-01-01", "last_mont")   # -> end_date = today
##
## which quietly widened the report by however long ago 2024 was. The previous
## code path rejected that string. A range the package does not know has to be
## reported, not guessed at.

test_that("an unrecognised relative end_date is rejected, not read as today", {
  expect_error(
    resolve_date_range("2024-01-01", "last_mont"),
    "Unrecognised date range"
  )
  expect_error(resolve_date_range("2024-01-01", "lastmonth"), "Unrecognised")
  expect_error(resolve_date_range("2024-01-01", "next_week"), "Unrecognised")
})

test_that("an unrecognised relative start_date is rejected too", {
  expect_error(resolve_date_range("last_mont"), "Unrecognised|Invalid|nrecognized")
})

test_that("the error names the ranges that would have worked", {
  err <- tryCatch(resolve_date_range("2024-01-01", "last_mont"),
                  error = function(e) conditionMessage(e))
  expect_match(err, "last_month", fixed = TRUE)
  expect_match(err, "YYYY-MM-DD", fixed = TRUE)
})

test_that("every documented range still resolves, in both directions", {
  # The guard against fixing the above by narrowing what the package accepts:
  # each name has to map to a start and an end, and the start cannot follow the
  # end. .parse_date_string() and .get_end_date_for_range() are separate switch
  # statements over the same set, so this is what keeps them aligned.
  ranges <- getFromNamespace(".known_date_ranges", "tubern")
  expect_gt(length(ranges), 10)
  for (r in ranges) {
    got <- expect_no_error(resolve_date_range(r), message = r)
    expect_match(got$start_date, "^\\d{4}-\\d{2}-\\d{2}$", info = r)
    expect_match(got$end_date, "^\\d{4}-\\d{2}-\\d{2}$", info = r)
    expect_lte(as.Date(got$start_date), as.Date(got$end_date), label = r)
  }
})

test_that("a relative end_date ends its window rather than starting it", {
  # The defect the end_date routing was introduced to fix, pinned so it cannot
  # regress while the typo handling is changed around it.
  got <- resolve_date_range("2024-01-01", "last_month")
  first_of_this_month <- as.Date(format(Sys.Date(), "%Y-%m-01"))
  expect_equal(as.Date(got$end_date), first_of_this_month - 1)
})

test_that("absolute end dates are untouched by any of this", {
  got <- resolve_date_range("2024-01-01", "2024-01-31")
  expect_equal(got$start_date, "2024-01-01")
  expect_equal(got$end_date, "2024-01-31")
})
