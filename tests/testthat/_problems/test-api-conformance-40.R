# Extracted from test-api-conformance.R:40

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "tubern", path = "..")
attach(test_env, warn.conflicts = FALSE)

# prequel ----------------------------------------------------------------------
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
API_FILTER_ONLY <- c("continent", "subContinent", "group", "audienceType")

# test -------------------------------------------------------------------------
validate <- getFromNamespace(".validate_dimensions", "tubern")
for (d in API_DIMENSIONS) {
    expect_no_error(validate(d), message = paste("rejected documented dimension:", d))
  }
