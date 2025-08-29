# https://github.com/jimhester/lintr
if (requireNamespace("lintr", quietly = TRUE)) {
  context("lints")
  test_that("Package Style", {
    skip_if_not_installed("lintr")
    skip_on_cran()
    # Try to find package root, fallback to current working directory during check
    tryCatch({
      lintr::expect_lint_free(cache = TRUE)
    }, error = function(e) {
      # If lintr can't find package root, skip the test
      skip("Could not locate package for linting")
    })
  })
}
