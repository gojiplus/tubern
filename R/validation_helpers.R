#' YouTube Analytics API Validation Helpers
#'
#' Internal validation functions for metrics, dimensions, and parameters
#' @name validation_helpers
NULL

# Valid metrics for YouTube Analytics API v2
.valid_metrics <- list(
  # View metrics
  views = "Number of times videos were viewed",
  redViews = "Number of times videos were viewed in red (YouTube Red)",
  
  # Engagement metrics  
  likes = "Number of likes",
  dislikes = "Number of dislikes",
  comments = "Number of comments",
  shares = "Number of times videos were shared",
  subscribersGained = "Number of subscribers gained",
  subscribersLost = "Number of subscribers lost",
  
  # Watch time metrics
  estimatedMinutesWatched = "Total minutes watched",
  averageViewDuration = "Average duration of video views",
  averageViewPercentage = "Average percentage of video watched",
  
  # Revenue metrics (requires monetary scope)
  estimatedRevenue = "Estimated revenue",
  adEarnings = "Revenue from ads",
  monetizedPlaybacks = "Number of monetized playbacks",
  playbackBasedCpm = "Cost per mille based on playbacks",
  impressionBasedCpm = "Cost per mille based on impressions",
  grossRevenue = "Gross revenue",
  
  # Ad performance metrics
  adImpressions = "Number of ad impressions",
  cardClickRate = "Click rate for cards",
  cardTeaserClickRate = "Click rate for card teasers",
  cardImpressions = "Number of card impressions",
  cardTeaserImpressions = "Number of card teaser impressions"
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
  
  # Sharing dimensions
  sharingService = "Service used for sharing"
)

# Filter-only dimensions
.filter_only_dimensions <- c("continent", "subContinent", "group")

# Dimensions that require specific filters
.dimension_requirements <- list(
  province = "country==US"
)

#' Validate metrics parameter
#' 
#' @param metrics Character vector or comma-separated string of metrics
#' @return Character vector of validated metrics
#' @keywords internal
#' @noRd
.validate_metrics <- function(metrics) {
  if (is.null(metrics) || length(metrics) == 0) {
    stop("At least one metric must be specified", call. = FALSE)
  }
  
  # Handle comma-separated string
  if (length(metrics) == 1 && grepl(",", metrics)) {
    metrics <- trimws(strsplit(metrics, ",")[[1]])
  }
  
  # Check for invalid metrics
  invalid_metrics <- metrics[!metrics %in% names(.valid_metrics)]
  if (length(invalid_metrics) > 0) {
    # Find close matches
    suggestions <- character(0)
    for (invalid in invalid_metrics) {
      distances <- adist(invalid, names(.valid_metrics))
      closest <- names(.valid_metrics)[which.min(distances)]
      if (min(distances) <= 3) {
        suggestions <- c(suggestions, paste0("'", invalid, "' -> '", closest, "'"))
      }
    }
    
    error_msg <- paste0("Invalid metric(s): ", paste(invalid_metrics, collapse = ", "))
    if (length(suggestions) > 0) {
      error_msg <- paste0(error_msg, "\n\nDid you mean:\n", paste(suggestions, collapse = "\n"))
    }
    error_msg <- paste0(error_msg, "\n\nValid metrics: ", paste(names(.valid_metrics), collapse = ", "))
    stop(error_msg, call. = FALSE)
  }
  
  return(metrics)
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
  
  # Handle comma-separated string
  if (length(dimensions) == 1 && grepl(",", dimensions)) {
    dimensions <- trimws(strsplit(dimensions, ",")[[1]])
  }
  
  # Check for invalid dimensions
  all_valid <- c(names(.valid_dimensions), .filter_only_dimensions)
  invalid_dims <- dimensions[!dimensions %in% all_valid]
  if (length(invalid_dims) > 0) {
    # Find close matches
    suggestions <- character(0)
    for (invalid in invalid_dims) {
      distances <- adist(invalid, all_valid)
      closest <- all_valid[which.min(distances)]
      if (min(distances) <= 3) {
        suggestions <- c(suggestions, paste0("'", invalid, "' -> '", closest, "'"))
      }
    }
    
    error_msg <- paste0("Invalid dimension(s): ", paste(invalid_dims, collapse = ", "))
    if (length(suggestions) > 0) {
      error_msg <- paste0(error_msg, "\n\nDid you mean:\n", paste(suggestions, collapse = "\n"))
    }
    error_msg <- paste0(error_msg, "\n\nValid dimensions: ", paste(names(.valid_dimensions), collapse = ", "))
    stop(error_msg, call. = FALSE)
  }
  
  # Check filter-only dimensions
  filter_only_used <- dimensions[dimensions %in% .filter_only_dimensions]
  if (length(filter_only_used) > 0) {
    stop("The following dimensions can only be used as filters: ", 
         paste(filter_only_used, collapse = ", "), call. = FALSE)
  }
  
  # Check dimension requirements
  for (dim in dimensions) {
    if (dim %in% names(.dimension_requirements)) {
      required_filter <- .dimension_requirements[[dim]]
      if (is.null(filters) || !grepl(required_filter, filters)) {
        stop("Dimension '", dim, "' requires filter: ", required_filter, call. = FALSE)
      }
    }
  }
  
  return(dimensions)
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
    stop("Both start_date and end_date are required", call. = FALSE)
  }
  
  # Check date format
  date_pattern <- "^\\d{4}-\\d{2}-\\d{2}$"
  if (!grepl(date_pattern, start_date)) {
    stop("start_date must be in YYYY-MM-DD format, got: ", start_date, call. = FALSE)
  }
  if (!grepl(date_pattern, end_date)) {
    stop("end_date must be in YYYY-MM-DD format, got: ", end_date, call. = FALSE)
  }
  
  # Try to parse dates
  start_parsed <- tryCatch(as.Date(start_date), error = function(e) NULL)
  end_parsed <- tryCatch(as.Date(end_date), error = function(e) NULL)
  
  if (is.null(start_parsed)) {
    stop("Invalid start_date: ", start_date, call. = FALSE)
  }
  if (is.null(end_parsed)) {
    stop("Invalid end_date: ", end_date, call. = FALSE)
  }
  
  # Check date order
  if (start_parsed > end_parsed) {
    stop("start_date must be before or equal to end_date", call. = FALSE)
  }
  
  # Check if dates are too far in the future
  if (end_parsed > Sys.Date()) {
    warning("end_date is in the future, YouTube Analytics data may not be available", 
            call. = FALSE)
  }
  
  return(list(start_date = start_date, end_date = end_date))
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
  
  # Basic filter format check
  if (!grepl("==", filters)) {
    stop("Filters must be in format 'dimension==value' or 'dimension==value1,value2'", 
         call. = FALSE)
  }
  
  # Extract filter dimensions
  filter_parts <- strsplit(filters, ";")[[1]]
  filter_dims <- sapply(filter_parts, function(x) {
    trimws(strsplit(x, "==")[[1]][1])
  })
  
  # Check if filtered dimensions exist in all valid dimensions
  all_valid <- c(names(.valid_dimensions), .filter_only_dimensions)
  invalid_filter_dims <- filter_dims[!filter_dims %in% all_valid]
  if (length(invalid_filter_dims) > 0) {
    stop("Invalid filter dimension(s): ", paste(invalid_filter_dims, collapse = ", "), 
         call. = FALSE)
  }
  
  # Check video filter dimension requirement
  if ("video" %in% filter_dims && !is.null(dimensions) && !"video" %in% dimensions) {
    message("Note: When filtering by video, consider adding 'video' to dimensions to see individual video results")
  }
  
  return(filters)
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
    matches <- grepl(pattern, names(dimensions), ignore.case = TRUE) |
               grepl(pattern, unlist(dimensions), ignore.case = TRUE)
    dimensions <- dimensions[matches]
  }
  unlist(dimensions)
}