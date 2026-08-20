# Offline tests for defects found by auditing the package against the
# YouTube Analytics API v2 reference. Nothing here touches the network.

fake_response <- function(status, content = raw(0)) {
  structure(
    list(
      url = "https://youtubeanalytics.googleapis.com/v2/groups",
      status_code = as.integer(status),
      headers = structure(list(), class = c("insensitive", "list")),
      all_headers = list(), cookies = data.frame(),
      content = content, date = Sys.time(), times = numeric(0),
      request = NULL, handle = NULL
    ),
    class = "response"
  )
}

test_that("get_revenue_report only asks for metrics the API defines", {
  # adEarnings and impressionBasedCpm are the pre-v2 names; the API (and this
  # package's own metric whitelist) call them estimatedAdRevenue and cpm. The
  # stale names made every call abort during validation.
  valid <- names(get_available_metrics())
  captured <- new.env(parent = emptyenv())
  local_mocked_bindings(
    tubern_GET = function(path, query, ...) {
      captured$query <- query
      list(rows = list())
    },
    .package = "tubern"
  )

  get_revenue_report("2024-01-01", end_date = "2024-01-31")
  asked <- strsplit(captured$query$metrics, ",", fixed = TRUE)[[1]]
  expect_true(all(asked %in% valid),
    info = paste(
      "not in whitelist:",
      paste(setdiff(asked, valid), collapse = ", ")
    )
  )
  expect_true("estimatedAdRevenue" %in% asked)
  expect_true("cpm" %in% asked)

  get_revenue_report("2024-01-01", end_date = "2024-01-31", include_cpm = FALSE)
  asked <- strsplit(captured$query$metrics, ",", fixed = TRUE)[[1]]
  expect_true(all(asked %in% valid))
  expect_false("cpm" %in% asked)
})

test_that("a relative end_date resolves to the END of that window", {
  # resolve_date_range() documents end_date as accepting a relative string, but
  # ran it through the start-of-range parser, silently truncating the range.
  end_of <- get(".get_end_date_for_range", envir = asNamespace("tubern"))
  for (range in c(
    "this_month", "last_month", "this_year", "last_year",
    "last_quarter", "yesterday", "last_7_days"
  )) {
    got <- resolve_date_range("2020-01-01", range)$end_date
    expect_equal(got, format(end_of(range), "%Y-%m-%d"),
      info = paste("end_date =", range)
    )
  }
})

test_that("an absolute end_date is still taken literally", {
  expect_equal(
    resolve_date_range("2024-01-01", "2024-01-31")$end_date,
    "2024-01-31"
  )
})

test_that("a 204 No Content response is a success, not an error", {
  # groups.delete and groupItems.delete document HTTP 204 with an empty body on
  # success. Treating only 200 as success routed them into the error path, where
  # parsing an empty body raised an untyped error.
  options(google_token = structure(list(credentials = list(access_token = "x")),
    class = "Token2.0"
  ))
  on.exit(options(google_token = NULL), add = TRUE)

  # Restore and relock on the way out. Left in place, the stub outlived this
  # test and answered 204 for every later POST/DELETE in the session -- with a
  # token present, test-groups-live.R's add_groups() then returned list() and
  # the lifecycle test either failed or, worse, passed against the fake.
  imports <- parent.env(asNamespace("tubern"))
  originals <- mget(c("DELETE", "POST"), envir = imports)
  on.exit(
    {
      for (verb in names(originals)) {
        assign(verb, originals[[verb]], envir = imports)
        lockBinding(verb, imports)
      }
    },
    add = TRUE
  )

  for (verb in c("DELETE", "POST")) {
    unlockBinding(verb, imports)
    assign(verb, function(url, ...) fake_response(204), envir = imports)
  }

  expect_no_error(suppressMessages(delete_group(id = "ABC")))
  expect_no_error(suppressMessages(delete_group_item(id = "XYZ")))
})

test_that("the 204 test leaves the real HTTP verbs in place", {
  # Guards the restore above. Without it this file quietly poisons every test
  # that runs after it, and the damage is invisible precisely because the fake
  # returns success.
  imports <- parent.env(asNamespace("tubern"))
  for (verb in c("DELETE", "POST")) {
    expect_identical(get(verb, envir = imports),
      getExportedValue("httr", verb),
      info = verb
    )
    expect_true(bindingIsLocked(verb, imports), info = verb)
  }
})

test_that("parsing an error body that is not a list does not itself error", {
  parse <- get(".parse_api_error", envir = asNamespace("tubern"))
  expect_equal(parse(204L, raw(0))$message, parse(204L, NULL)$message)
  expect_no_error(parse(500L, raw(0)))
  expect_no_error(parse(400L, "plain text body"))
})

test_that("with_retry re-runs the expression instead of re-forcing a promise", {
  retry <- get("with_retry", envir = asNamespace("tubern"))
  calls <- 0
  flaky <- function() {
    calls <<- calls + 1
    if (calls < 2) {
      stop(rlang::error_cnd(c("tubern_api_error", "tubern_error"),
        message = "503", status_code = 503L
      ))
    }
    "ok"
  }
  expect_no_warning(
    expect_equal(suppressMessages(retry(flaky(), base_delay = 0)), "ok")
  )
  expect_equal(calls, 2)
})

test_that("with_retry passes a NULL result through instead of retrying it", {
  # A successful call that legitimately yields NULL must not be mistaken for
  # the internal retry signal.
  retry <- get("with_retry", envir = asNamespace("tubern"))
  calls <- 0
  give_null <- function() {
    calls <<- calls + 1 # nolint: assignment_linter.
    NULL
  }
  expect_null(suppressMessages(retry(give_null(), base_delay = 0)))
  expect_equal(calls, 1)
})

test_that("ids is percent-encoded exactly once", {
  captured <- new.env(parent = emptyenv())
  local_mocked_bindings(
    tubern_GET = function(path, query, ...) {
      captured$query <- query
      list(rows = list())
    },
    .package = "tubern"
  )

  get_report(
    ids = "contentOwner==My Owner", metrics = "views",
    start_date = "2024-01-01", end_date = "2024-01-31"
  )
  # httr encodes query values itself, so the value handed to it must be raw.
  expect_equal(captured$query$ids, "contentOwner==My Owner")
  expect_false(grepl("%25", httr::modify_url("https://x", query = captured$query),
    fixed = TRUE
  ))
})
