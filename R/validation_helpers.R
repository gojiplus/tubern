#' YouTube Analytics API Validation Helpers
#'
#' Internal validation functions for metrics, dimensions, and parameters
#' using checkmate for robust parameter validation.
#' @name validation_helpers
#' @importFrom checkmate assert_character assert_string assert_flag assert_int assert_number assert_list check_string
NULL

# Valid metrics for YouTube Analytics API v2
.valid_metrics <- list(
  # View metrics
  views = "Number of times videos were viewed",
  redViews = "Number of times videos were viewed by YouTube Premium members",
  engagedViews = "Number of views that went past the initial seconds",
  viewerPercentage = "Percentage of viewers who were logged in when watching",

  # Thumbnail impression metrics are deliberately absent. They exist only as
  # video_thumbnail_impressions / video_thumbnail_impressions_ctr in the bulk
  # Reporting API, and are not on the targeted-query metrics reference this
  # package builds requests against:
  #   https://developers.google.com/youtube/analytics/metrics
  # Accepting them here let a request through that reports.query then rejected.

  # Engagement metrics
  likes = "Number of likes",
  dislikes = "Number of dislikes",
  comments = "Number of comments",
  shares = "Number of times videos were shared",
  subscribersGained = "Number of subscribers gained",
  subscribersLost = "Number of subscribers lost",
  videosAddedToPlaylists = "Number of times videos were added to playlists",
  videosRemovedFromPlaylists = "Number of times videos were removed from playlists",

  # Watch time metrics
  estimatedMinutesWatched = "Total minutes watched",
  estimatedRedMinutesWatched = "Minutes watched by YouTube Premium members",
  averageViewDuration = "Average duration of video views in seconds",
  averageViewPercentage = "Average percentage of video watched",

  # Playlist metrics
  playlistViews = "Number of times videos were viewed within playlist context",
  playlistStarts = "Number of times playlist playback was initiated",
  playlistSaves = "Number of times users saved the playlist",
  viewsPerPlaylistStart = "Average number of video views per playlist start",
  averageTimeInPlaylist = "Average time in seconds viewers spent in playlist",
  playlistAverageViewDuration = "Average duration of playlist video views",
  playlistEstimatedMinutesWatched = "Total minutes watched in playlist context",

  # Revenue metrics (requires monetary scope)
  estimatedRevenue = "Estimated total revenue",
  estimatedAdRevenue = "Estimated revenue from ads",
  estimatedRedPartnerRevenue = "Estimated revenue from YouTube Premium subscriptions",
  monetizedPlaybacks = "Number of monetized playbacks",
  playbackBasedCpm = "Cost per mille based on playbacks",
  cpm = "Cost per mille based on impressions",
  grossRevenue = "Gross revenue before revenue sharing",

  # Ad performance metrics
  adImpressions = "Number of ad impressions",

  # Card metrics
  cardImpressions = "Number of card impressions",
  cardClicks = "Number of card clicks",
  cardClickRate = "Click-through rate for cards",
  cardTeaserImpressions = "Number of card teaser impressions",
  cardTeaserClicks = "Number of card teaser clicks",
  cardTeaserClickRate = "Click-through rate for card teasers",

  # Annotation metrics
  annotationImpressions = "Number of annotation impressions",
  annotationClickableImpressions = "Number of clickable annotation impressions",
  annotationClicks = "Number of annotation clicks",
  annotationClickThroughRate = "Click-through rate for annotations",
  annotationClosableImpressions = "Number of closable annotation impressions",
  annotationCloses = "Number of annotation closes",
  annotationCloseRate = "Rate at which annotations were closed",

  # Membership metrics
  membershipsCancellationSurveyResponses =
    "Number of completed membership cancellation surveys",

  # Livestream metrics
  averageConcurrentViewers = "Average number of concurrent viewers during live stream",
  peakConcurrentViewers = "Peak number of concurrent viewers during live stream",

  # Audience retention metrics
  audienceWatchRatio = "Ratio of views at each moment compared to initial views",
  relativeRetentionPerformance = "Retention performance relative to similar videos",
  startedWatching = "Number of views that started at this point",
  stoppedWatching = "Number of views that stopped at this point",
  totalSegmentImpressions = "Total number of impressions for this segment"
)

# Valid dimensions for YouTube Analytics API v2
.valid_dimensions <- list(
  # Core dimensions
  channel = "Channel identifier",
  video = "Video identifier",
  playlist = "Playlist identifier",

  # Time dimensions
  day = "Daily aggregation",
  month = "Monthly aggregation",

  # Geographic dimensions
  country = "Two-letter country code",
  province = "Province/state (US only)",
  city = "City",

  # Demographic dimensions
  ageGroup = "Age group of viewers",
  gender = "Gender of viewers",

  # Device dimensions
  deviceType = "Type of device used",
  operatingSystem = "Operating system",

  # Traffic source dimensions
  insightTrafficSourceType = "Traffic source type",
  insightTrafficSourceDetail = "Detailed traffic source",

  # Content dimensions
  creatorContentType = "Type of creator content",
  liveOrOnDemand = "Live or on-demand content",
  youtubeProduct = "YouTube product",

  # Playback dimensions
  insightPlaybackLocationType = "Playback location type",
  insightPlaybackLocationDetail = "Embedded player page or URL (embedded views only)",

  # Sharing dimensions
  sharingService = "Service used for sharing",

  # Geographic dimensions
  dma = "Nielsen Designated Market Area (three-digit identifier)",

  # Viewer dimensions
  subscribedStatus = "Whether the viewer was subscribed to the channel",

  # Audience retention dimensions
  elapsedVideoTimeRatio = "Ratio of elapsed video time to length, 0.01 to 1.0",

  # Livestream dimensions
  livestreamPosition = "Minute during the live stream",

  # Advertising dimensions
  adType = "Advertising format",

  # Membership dimensions
  membershipsCancellationSurveyReason = "Reason given for cancelling a membership"
)

# Filter-only dimensions. These are documented as filters and cannot be
# requested as report dimensions, so they are held apart rather than added to
# .valid_dimensions above.
#
# uploaderType and claimedStatus are here rather than above despite the
# reference filing them under a "Content owner dimensions" heading. The
# per-report tables settle it: across every content owner report they appear
# only in Filters rows, never in a Dimensions row --
#   https://developers.google.com/youtube/analytics/content_owner_reports
# The prose ("must filter data using ... the claimedStatus and uploaderType
# dimensions") calls them dimensions while describing them as filters, which is
# what led to listing them as requestable here.
.filter_only_dimensions <- c(
  "continent", "subContinent", "group",
  "audienceType",
  "uploaderType", "claimedStatus"
)

# Dimensions that require specific filters
.dimension_requirements <- list(
  province = "country==US"
)

#' Find close matches for a string
#'
#' @param x String to match
#' @param choices Valid choices to match against
#' @param max_dist Maximum edit distance for suggestions
#' @return Character vector of suggestions
#' @keywords internal
#' @noRd
.find_suggestions <- function(x, choices, max_dist = 3) {
  distances <- adist(x, choices)
  close_matches <- choices[distances <= max_dist]
  if (length(close_matches) > 0) {
    paste0("'", x, "' -> '", close_matches[which.min(distances[distances <= max_dist])], "'")
  } else {
    character(0)
  }
}

# Names that are positively known to be wrong, and why
#
# Absence from `.valid_metrics` means "this package has not heard of it",
# which is not the same as "this is not a metric" -- the lists here are a
# hand-made snapshot and YouTube keeps adding names. These entries are the
# other thing: names we can say are wrong and give a reason for. They are
# rejected outright, because a message naming the actual mistake beats a
# round trip that returns "not supported".
#
# Both of these exist in the bulk Reporting API, under its snake_case
# spelling, and are absent from the targeted-query reference. Reaching for
# them in `get_report()` is a real and easy confusion between the two APIs.
.known_invalid_metrics <- c(
  videoThumbnailImpressions = paste(
    "exists in the bulk Reporting API as 'video_thumbnail_impressions'",
    "and is not available to reports.query"
  ),
  videoThumbnailImpressionsClickRate = paste(
    "exists in the bulk Reporting API as 'video_thumbnail_impressions_ctr'",
    "and is not available to reports.query"
  )
)

# Same idea for dimensions.
.known_invalid_dimensions <- c(
  subscriberStatus = paste(
    "exists in the bulk Reporting API as 'subscribed_status';",
    "reports.query spells it 'subscribedStatus'"
  )
)

#' Reject a name we can affirmatively say is wrong
#'
#' @param names Character vector of names supplied by the caller
#' @param registry Named character vector mapping a bad name to its reason
#' @param what Singular noun for the message, e.g. "metric"
#' @return Invisibly NULL; called for the error
#' @keywords internal
#' @noRd
.abort_known_invalid <- function(names, registry, what) {
  hits <- names[names %in% base::names(registry)]
  if (!length(hits)) {
    return(invisible(NULL))
  }

  lines <- vapply(
    hits,
    function(h) paste0("  ", h, ": ", registry[[h]]),
    character(1)
  )
  tubern_abort(
    paste(
      c(paste0("Invalid ", what, "(s):"), lines),
      collapse = "\n"
    ),
    class = "parameter"
  )
}

#' Warn about names this package does not recognise, and carry on
#'
#' The lists in this file are transcribed by hand from Google's prose
#' documentation. There is no machine-readable source for them: the discovery
#' document types `metrics` and `dimensions` as plain strings with the pattern
#' `[0-9a-zA-Z,]+` and enumerates nothing. So the lists are a snapshot, and
#' YouTube adds names -- `adImpressions` was called `impressions` until Google
#' renamed it.
#'
#' Refusing to send a name that is missing from a stale snapshot is the worse
#' of the two errors. A false rejection blocks a request the API would have
#' answered, and the user cannot work around it without editing the package;
#' a false acceptance costs one round trip and a clear message from the server,
#' which is the authority anyway. So an unrecognised name is a warning with a
#' spelling suggestion, and the request still goes out.
#'
#' This applies only to list membership. Rules about names we *do* know --
#' a filter-only dimension used as a dimension, a dimension whose filter is
#' missing -- stay errors, because those are documented constraints rather
#' than gaps in a snapshot.
#'
#' @param unknown Character vector of unrecognised names
#' @param choices Character vector of names this package knows
#' @param what Singular noun for the message, e.g. "metric"
#' @param helper Name of the accessor that lists valid values
#' @return Invisibly NULL; called for the warning
#' @keywords internal
#' @noRd
.warn_unrecognised <- function(unknown, choices, what, helper) {
  suggestions <- unlist(lapply(unknown, .find_suggestions, choices))

  msg <- paste0(
    "Unrecognised ", what, "(s): ", paste(unknown, collapse = ", "),
    "\n\nThese are not in this package's list of known ", what, "s, which is",
    "\ntranscribed from Google's documentation and may be out of date.",
    "\nThe request will be sent as given and the API will decide."
  )
  if (length(suggestions) > 0) {
    msg <- paste0(msg, "\n\nIf this is a typo, did you mean:\n",
                  paste(suggestions, collapse = "\n"))
  }
  msg <- paste0(msg, "\n\nUse ", helper, "() to see the ", what,
                "s this package knows about.")

  tubern_warn(msg, class = "parameter")
  invisible(NULL)
}

#' Validate metrics parameter
#'
#' @param metrics Character vector or comma-separated string of metrics
#' @return Character vector of validated metrics
#' @keywords internal
#' @noRd
.validate_metrics <- function(metrics) {
  if (is.null(metrics) || length(metrics) == 0) {
    tubern_abort(
      "At least one metric must be specified",
      class = "parameter"
    )
  }

  assert_character(metrics, min.len = 1, .var.name = "metrics")

  if (length(metrics) == 1 && grepl(",", metrics)) {
    metrics <- trimws(strsplit(metrics, ",")[[1]])
  }

  .abort_known_invalid(metrics, .known_invalid_metrics, "metric")

  unknown_metrics <- metrics[!metrics %in% names(.valid_metrics)]
  if (length(unknown_metrics) > 0) {
    .warn_unrecognised(
      unknown_metrics, names(.valid_metrics), "metric", "get_available_metrics"
    )
  }

  metrics
}

#' Validate dimensions parameter
#'
#' @param dimensions Character vector or comma-separated string of dimensions
#' @param filters Character string of filters (to check requirements)
#' @return Character vector of validated dimensions
#' @keywords internal
#' @noRd
.validate_dimensions <- function(dimensions, filters = NULL) {
  if (is.null(dimensions)) return(NULL)

  if (length(dimensions) == 1 && grepl(",", dimensions)) {
    dimensions <- trimws(strsplit(dimensions, ",")[[1]])
  }

  assert_character(dimensions, min.len = 1, .var.name = "dimensions")

  .abort_known_invalid(dimensions, .known_invalid_dimensions, "dimension")

  all_valid <- c(names(.valid_dimensions), .filter_only_dimensions)
  unknown_dims <- dimensions[!dimensions %in% all_valid]

  if (length(unknown_dims) > 0) {
    .warn_unrecognised(
      unknown_dims, all_valid, "dimension", "get_available_dimensions"
    )
  }

  filter_only_used <- dimensions[dimensions %in% .filter_only_dimensions]
  if (length(filter_only_used) > 0) {
    tubern_abort(
      paste0(
        "The following dimensions can only be used as filters: ",
        paste(filter_only_used, collapse = ", ")
      ),
      class = "parameter",
      filter_only_dimensions = filter_only_used
    )
  }

  for (dim in dimensions) {
    if (dim %in% names(.dimension_requirements)) {
      required_filter <- .dimension_requirements[[dim]]
      if (is.null(filters) || !grepl(required_filter, filters)) {
        tubern_abort(
          paste0("Dimension '", dim, "' requires filter: ", required_filter),
          class = "parameter",
          dimension = dim,
          required_filter = required_filter
        )
      }
    }
  }

  dimensions
}

#' Validate date parameters
#'
#' @param start_date Character string in YYYY-MM-DD format
#' @param end_date Character string in YYYY-MM-DD format
#' @return List with validated start_date and end_date
#' @keywords internal
#' @noRd
.validate_dates <- function(start_date, end_date) {
  if (is.null(start_date) || is.null(end_date)) {
    tubern_abort(
      "Both start_date and end_date are required",
      class = "parameter"
    )
  }

  assert_string(start_date, .var.name = "start_date")
  assert_string(end_date, .var.name = "end_date")

  date_pattern <- "^\\d{4}-\\d{2}-\\d{2}$"
  if (!grepl(date_pattern, start_date)) {
    tubern_abort(
      paste0("start_date must be in YYYY-MM-DD format, got: '", start_date, "'"),
      class = "parameter"
    )
  }
  if (!grepl(date_pattern, end_date)) {
    tubern_abort(
      paste0("end_date must be in YYYY-MM-DD format, got: '", end_date, "'"),
      class = "parameter"
    )
  }

  start_parsed <- tryCatch(as.Date(start_date), error = function(e) NULL)
  end_parsed <- tryCatch(as.Date(end_date), error = function(e) NULL)

  if (is.null(start_parsed)) {
    tubern_abort(
      paste0("Invalid start_date: '", start_date, "'"),
      class = "parameter"
    )
  }
  if (is.null(end_parsed)) {
    tubern_abort(
      paste0("Invalid end_date: '", end_date, "'"),
      class = "parameter"
    )
  }

  if (start_parsed > end_parsed) {
    tubern_abort(
      "start_date must be before or equal to end_date",
      class = "parameter",
      start_date = start_date,
      end_date = end_date
    )
  }

  if (end_parsed > Sys.Date()) {
    tubern_warn(
      "end_date is in the future, YouTube Analytics data may not be available",
      class = "parameter"
    )
  }

  list(start_date = start_date, end_date = end_date)
}

#' Validate filters parameter
#'
#' @param filters Character string of filters
#' @param dimensions Character vector of dimensions (for validation)
#' @return Character string of validated filters
#' @keywords internal
#' @noRd
.validate_filters <- function(filters, dimensions = NULL) {
  if (is.null(filters)) return(NULL)

  assert_string(filters, .var.name = "filters")

  if (!grepl("==", filters)) {
    tubern_abort(
      "Filters must be in format 'dimension==value' or 'dimension==value1,value2'",
      class = "parameter"
    )
  }

  filter_parts <- strsplit(filters, ";")[[1]]
  filter_dims <- vapply(filter_parts, function(x) {
    trimws(strsplit(x, "==")[[1]][1])
  }, character(1))

  all_valid <- c(names(.valid_dimensions), .filter_only_dimensions)
  unknown_filter_dims <- filter_dims[!filter_dims %in% all_valid]

  if (length(unknown_filter_dims) > 0) {
    .warn_unrecognised(
      unknown_filter_dims, all_valid, "filter dimension", "get_available_dimensions"
    )
  }

  if ("video" %in% filter_dims && (is.null(dimensions) || !"video" %in% dimensions)) {
    tubern_warn(
      c(
        "Filtering by video without dimensions='video' returns aggregated channel stats.",
        "To see per-video breakdown, add dimensions = 'video' to your call.",
        "Example: get_report(..., dimensions = 'video', filters = 'video==id1,id2')"
      ),
      class = "parameter"
    )
  }

  filters
}

#' Get available metrics with descriptions
#'
#' @param pattern Optional regex pattern to filter metrics
#' @return Named character vector of metrics and descriptions
#' @export
#' @examples
#' # Get all metrics
#' get_available_metrics()
#'
#' # Get only view-related metrics
#' get_available_metrics("view")
get_available_metrics <- function(pattern = NULL) {
  metrics <- .valid_metrics
  if (!is.null(pattern)) {
    assert_string(pattern, .var.name = "pattern")
    matches <- grepl(pattern, names(metrics), ignore.case = TRUE) |
               grepl(pattern, unlist(metrics), ignore.case = TRUE)
    metrics <- metrics[matches]
  }
  unlist(metrics)
}

#' Get available dimensions with descriptions
#'
#' @param pattern Optional regex pattern to filter dimensions
#' @return Named character vector of dimensions and descriptions
#' @export
#' @examples
#' # Get all dimensions
#' get_available_dimensions()
#'
#' # Get only geographic dimensions
#' get_available_dimensions("country|city")
get_available_dimensions <- function(pattern = NULL) {
  dimensions <- .valid_dimensions
  if (!is.null(pattern)) {
    assert_string(pattern, .var.name = "pattern")
    matches <- grepl(pattern, names(dimensions), ignore.case = TRUE) |
               grepl(pattern, unlist(dimensions), ignore.case = TRUE)
    dimensions <- dimensions[matches]
  }
  unlist(dimensions)
}
