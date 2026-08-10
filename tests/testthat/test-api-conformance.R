## The package validates every request against its own registry in
## R/validation_helpers.R and calls tubern_abort() on anything it does not
## recognise, before a request is ever made. That registry is a set of claims
## about the API, and it had drifted: documented dimensions were rejected
## outright, including subscribedStatus, insightPlaybackLocationDetail and
## adType. Asking for one failed inside tubern with "Invalid dimension(s)" and a
## "did you mean" suggestion -- the package blocked documented API functionality
## and blamed the caller.
##
## It could drift because the existing tests only assert that INVALID names are
## rejected. Nothing asserted that valid ones are accepted, so entries could rot
## silently. These are the converse.
##
## The lists below are pinned from the API reference, checked 2026-08-02:
##   https://developers.google.com/youtube/analytics/dimensions
##   https://developers.google.com/youtube/analytics/content_owner_reports
##   https://developers.google.com/youtube/analytics/metrics
##
## What this can and cannot do: both the pin and the registry are static source
## in this package, so a name Google adds tomorrow cannot make anything here go
## red -- nothing in an offline test suite can detect that. What it does enforce
## is that the registry and the pin never disagree, so the pin is a single place
## to review against the reference, and any edit to the registry that is not
## also an edit here fails.

# Dimensions that can be requested as report dimensions.
API_DIMENSIONS <- c(
  "day", "month", "video", "channel", "playlist",
  "country", "province", "city", "dma",
  "ageGroup", "gender", "subscribedStatus",
  "deviceType", "operatingSystem", "youtubeProduct",
  "insightTrafficSourceType", "insightTrafficSourceDetail",
  "insightPlaybackLocationType", "insightPlaybackLocationDetail",
  "creatorContentType", "liveOrOnDemand", "sharingService",
  "elapsedVideoTimeRatio", "livestreamPosition",
  "adType", "membershipsCancellationSurveyReason"
)

# Documented as filters only -- valid names, but not requestable as dimensions.
#
# uploaderType and claimedStatus sit here even though the dimensions reference
# files them under a "Content owner dimensions" heading. The per-report tables
# settle it: across every content owner report they appear only in Filters rows,
# never in a Dimensions row. The prose calls them dimensions while describing
# them as filters, which is exactly how they came to be listed as requestable.
API_FILTER_ONLY <- c(
  "continent", "subContinent", "group", "audienceType",
  "uploaderType", "claimedStatus"
)

test_that("every dimension the API documents is accepted", {
  validate <- getFromNamespace(".validate_dimensions", "tubern")
  # province is documented as requiring country==US, and the package enforces
  # that through .dimension_requirements, so it is supplied here rather than
  # treated as a rejection.
  requirements <- getFromNamespace(".dimension_requirements", "tubern")
  for (d in API_DIMENSIONS) {
    filters <- if (!is.null(requirements[[d]])) requirements[[d]] else NULL
    expect_no_error(
      validate(d, filters = filters),
      message = paste("rejected documented dimension:", d)
    )
  }
})

test_that("a dimension with a documented filter requirement still enforces it", {
  validate <- getFromNamespace(".validate_dimensions", "tubern")
  expect_error(validate("province"), "requires filter")
  expect_no_error(validate("province", filters = "country==US"))
})

test_that("filter-only dimensions are known but refused as dimensions", {
  validate <- getFromNamespace(".validate_dimensions", "tubern")
  for (d in API_FILTER_ONLY) {
    # Known: the error names the filter-only restriction rather than claiming
    # the dimension does not exist.
    expect_error(validate(d), "only be used as filters", info = d)
  }
})

test_that("a name we can name the mistake for is still rejected", {
  validate <- getFromNamespace(".validate_dimensions", "tubern")
  # subscriberStatus is on the known-invalid list: it is the bulk Reporting
  # API's spelling, so we can say what the mistake is rather than guess.
  expect_error(validate("subscriberStatus"), "Invalid dimension")
  expect_error(validate("subscriberStatus"), "subscribedStatus")
})

test_that("a name we merely do not know warns, with a suggestion, and passes through", {
  validate <- getFromNamespace(".validate_dimensions", "tubern")
  # Absence from the registry means "not heard of", which is not the same as
  # "not a dimension" -- the registry is a hand-made snapshot. Blocking here
  # would make every dimension YouTube adds unreachable until tubern ships.
  expect_warning(out <- validate("dayy"), "Unrecognised dimension")
  expect_warning(validate("dayy"), "did you mean")
  expect_equal(out, "dayy")
})

test_that("metrics the API documents are accepted", {
  validate <- getFromNamespace(".validate_metrics", "tubern")
  for (m in c(
    "views", "redViews", "engagedViews", "estimatedMinutesWatched",
    "averageViewDuration", "averageViewPercentage", "likes", "dislikes",
    "comments", "shares", "subscribersGained", "subscribersLost",
    "estimatedRevenue", "estimatedAdRevenue", "estimatedRedPartnerRevenue",
    "grossRevenue", "cpm", "playbackBasedCpm", "adImpressions",
    "monetizedPlaybacks", "membershipsCancellationSurveyResponses",
    "cardImpressions", "cardClickRate", "audienceWatchRatio",
    "relativeRetentionPerformance", "averageConcurrentViewers"
  )) {
    expect_no_error(validate(m), message = paste("rejected documented metric:", m))
  }
})

test_that("bulk-Reporting-API-only metrics are refused", {
  # These exist as video_thumbnail_impressions / _ctr in the bulk Reporting API
  # and are absent from the targeted-query metrics reference. Accepting them
  # let a request through that reports.query then rejected, which is the failure
  # local validation exists to prevent. They stay hard errors because we can
  # say *why* they are wrong; a name merely missing from the registry only
  # warns, since that cannot be told apart from a name YouTube has just added.
  validate <- getFromNamespace(".validate_metrics", "tubern")
  expect_error(validate("videoThumbnailImpressions"), "Invalid metric")
  expect_error(validate("videoThumbnailImpressions"), "bulk Reporting API")
  expect_error(validate("videoThumbnailImpressionsClickRate"), "Invalid metric")
})

test_that("a metric the registry has not heard of warns rather than blocking", {
  validate <- getFromNamespace(".validate_metrics", "tubern")
  expect_warning(out <- validate("someMetricAddedNextYear"), "Unrecognised metric")
  expect_equal(out, "someMetricAddedNextYear")
})

test_that("the registry covers the pinned API lists exactly", {
  # The drift guard. Note this is setequal on the whole sets, not on their
  # intersection: intersecting first discards every registry-only entry, so the
  # earlier version of this test passed happily with a bogus name in the
  # registry. It detected a missing name and nothing else.
  known <- c(
    names(getFromNamespace(".valid_dimensions", "tubern")),
    getFromNamespace(".filter_only_dimensions", "tubern")
  )
  expect_setequal(known, c(API_DIMENSIONS, API_FILTER_ONLY))
})

test_that("the drift guard notices a registry entry with no pinned counterpart", {
  # Guarding the guard: the assertion above is only worth having if an extra
  # registry entry actually fails it. This is the mutation the old test survived.
  pinned <- c(API_DIMENSIONS, API_FILTER_ONLY)
  expect_failure(expect_setequal(c(pinned, "bogusDimension"), pinned))
  expect_failure(expect_setequal(pinned[-1], pinned))
})
