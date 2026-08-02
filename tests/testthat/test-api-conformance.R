## The package validates every request against its own registry in
## R/validation_helpers.R and calls tubern_abort() on anything it does not
## recognise, before a request is ever made. That registry is a set of claims
## about the API, and it had drifted: ten documented dimensions were rejected
## outright, including subscribedStatus, insightPlaybackLocationDetail, adType
## and claimedStatus. Asking for one failed inside tubern with "Invalid
## dimension(s)" and a "did you mean" suggestion -- the package blocked
## documented API functionality and blamed the caller.
##
## It could drift because the existing tests only assert that INVALID names are
## rejected. Nothing asserted that valid ones are accepted, so entries could rot
## silently. These are the converse.
##
## The lists below are pinned from the API reference, checked 2026-08-02:
##   https://developers.google.com/youtube/analytics/dimensions
##   https://developers.google.com/youtube/analytics/metrics
## When Google adds a name, this fails and the diff is explicit, rather than a
## user meeting a confusing error.

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
  "adType", "membershipsCancellationSurveyReason",
  "uploaderType", "claimedStatus"
)

# Documented as filters only -- valid names, but not requestable as dimensions.
API_FILTER_ONLY <- c("continent", "subContinent", "group", "audienceType")

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

test_that("a genuine typo is still rejected, with a suggestion", {
  validate <- getFromNamespace(".validate_dimensions", "tubern")
  expect_error(validate("subscriberStatus"), "Invalid dimension")
  expect_error(validate("nonsenseDimension"), "Invalid dimension")
})

test_that("every metric in the registry validates", {
  validate <- getFromNamespace(".validate_metrics", "tubern")
  registry <- names(getFromNamespace(".valid_metrics", "tubern"))
  expect_gt(length(registry), 50)
  for (m in registry) {
    expect_no_error(validate(m), message = paste("registry metric rejected:", m))
  }
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

test_that("the registry covers the pinned API lists exactly", {
  # The drift guard. A name added to the API and not here, or removed here and
  # not there, shows up as a failing diff rather than a user's error.
  known <- c(
    names(getFromNamespace(".valid_dimensions", "tubern")),
    getFromNamespace(".filter_only_dimensions", "tubern")
  )
  expect_setequal(intersect(known, c(API_DIMENSIONS, API_FILTER_ONLY)),
                  c(API_DIMENSIONS, API_FILTER_ONLY))
})
