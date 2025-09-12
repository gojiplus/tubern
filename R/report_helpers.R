#' Common Report Helper Functions
#'
#' Pre-configured functions for common YouTube Analytics report types
#' @name report_helpers
NULL

#' Get channel overview report
#' 
#' Retrieves key channel performance metrics for a specified time period.
#' 
#' @param ids Channel identifier (default: "channel==MINE")
#' @param date_range Date range string like "last_30_days" or start date for custom range
#' @param end_date End date (only needed if date_range is a specific start date)
#' @param include_engagement Logical. Include likes, dislikes, comments, shares (default: TRUE)
#' @param include_subscribers Logical. Include subscriber metrics (default: TRUE)
#' @param ... Additional arguments passed to get_report()
#' @return API response with channel overview data
#' @export
#' @examples
#' \dontrun{
#' # Channel performance for last 30 days
#' get_channel_overview("last_30_days")
#' 
#' # Channel performance for specific date range
#' get_channel_overview("2024-01-01", end_date = "2024-01-31")
#' 
#' # Basic metrics only
#' get_channel_overview("this_month", include_engagement = FALSE, include_subscribers = FALSE)
#' }
get_channel_overview <- function(date_range, end_date = NULL, ids = "channel==MINE", 
                                include_engagement = TRUE, include_subscribers = TRUE, ...) {
  
  # Build metrics based on options
  metrics <- c("views", "estimatedMinutesWatched")
  
  if (include_engagement) {
    metrics <- c(metrics, "likes", "dislikes", "comments", "shares")
  }
  
  if (include_subscribers) {
    metrics <- c(metrics, "subscribersGained", "subscribersLost")
  }
  
  get_report(
    ids = ids,
    metrics = paste(metrics, collapse = ","),
    start_date = date_range,
    end_date = end_date,
    ...
  )
}

#' Get top videos report
#' 
#' Retrieves performance metrics for individual videos, sorted by views.
#' 
#' @param date_range Date range string or start date
#' @param end_date End date (only needed if date_range is a specific start date)  
#' @param ids Channel identifier (default: "channel==MINE")
#' @param max_results Number of top videos to return (default: 10)
#' @param metrics Vector of metrics to include (default: views, likes, comments)
#' @param ... Additional arguments passed to get_report()
#' @return API response with top videos data
#' @export
#' @examples
#' \dontrun{
#' # Top 10 videos by views in last 30 days
#' get_top_videos("last_30_days")
#' 
#' # Top 25 videos with more metrics
#' get_top_videos("this_month", max_results = 25, 
#'                metrics = c("views", "likes", "comments", "shares", "estimatedMinutesWatched"))
#' }
get_top_videos <- function(date_range, end_date = NULL, ids = "channel==MINE",
                          max_results = 10, metrics = c("views", "likes", "comments"), ...) {
  
  get_report(
    ids = ids,
    metrics = paste(metrics, collapse = ","),
    dimensions = "video",
    start_date = date_range,
    end_date = end_date,
    sort = "-views",  # Sort by views descending
    max_results = max_results,
    ...
  )
}

#' Get audience demographics report
#' 
#' Retrieves demographic breakdown of your audience by age and gender.
#' 
#' @param date_range Date range string or start date
#' @param end_date End date (only needed if date_range is a specific start date)
#' @param ids Channel identifier (default: "channel==MINE")  
#' @param dimension Demographic dimension: "ageGroup", "gender", or both (default: both)
#' @param metrics Vector of metrics to include (default: views, estimatedMinutesWatched)
#' @param ... Additional arguments passed to get_report()
#' @return API response with demographic data
#' @export
#' @examples
#' \dontrun{
#' # Full demographic breakdown
#' get_audience_demographics("last_90_days")
#' 
#' # Age groups only
#' get_audience_demographics("this_month", dimension = "ageGroup")
#' 
#' # Gender breakdown only  
#' get_audience_demographics("this_quarter", dimension = "gender")
#' }
get_audience_demographics <- function(date_range, end_date = NULL, ids = "channel==MINE",
                                    dimension = c("ageGroup", "gender"), 
                                    metrics = c("views", "estimatedMinutesWatched"), ...) {
  
  # Handle dimension parameter
  if (length(dimension) > 1) {
    dimensions <- paste(dimension, collapse = ",")
  } else {
    dimensions <- dimension
  }
  
  get_report(
    ids = ids,
    metrics = paste(metrics, collapse = ","),
    dimensions = dimensions,
    start_date = date_range,
    end_date = end_date,
    ...
  )
}

#' Get geographic performance report
#' 
#' Retrieves performance metrics broken down by country or other geographic dimensions.
#' 
#' @param date_range Date range string or start date
#' @param end_date End date (only needed if date_range is a specific start date)
#' @param ids Channel identifier (default: "channel==MINE")
#' @param dimension Geographic dimension: "country", "province", or "city" (default: "country")
#' @param metrics Vector of metrics to include (default: views, estimatedMinutesWatched)
#' @param max_results Number of results to return (default: 25)
#' @param ... Additional arguments passed to get_report()
#' @return API response with geographic data
#' @export
#' @examples
#' \dontrun{
#' # Top countries by views
#' get_geographic_performance("last_30_days")
#' 
#' # US states/provinces (requires US-only data)
#' get_geographic_performance("this_month", dimension = "province", 
#'                           filters = "country==US")
#' }
get_geographic_performance <- function(date_range, end_date = NULL, ids = "channel==MINE",
                                     dimension = "country", 
                                     metrics = c("views", "estimatedMinutesWatched"),
                                     max_results = 25, ...) {
  
  get_report(
    ids = ids,
    metrics = paste(metrics, collapse = ","),
    dimensions = dimension,
    start_date = date_range,
    end_date = end_date,
    sort = "-views",
    max_results = max_results,
    ...
  )
}


#' Get daily performance time series
#' 
#' Retrieves day-by-day performance metrics for trend analysis.
#' 
#' @param date_range Date range string or start date  
#' @param end_date End date (only needed if date_range is a specific start date)
#' @param ids Channel identifier (default: "channel==MINE")
#' @param metrics Vector of metrics to include (default: views, estimatedMinutesWatched)
#' @param ... Additional arguments passed to get_report()
#' @return API response with daily time series data
#' @export
#' @examples
#' \dontrun{
#' # Daily views for last 30 days
#' get_daily_performance("last_30_days")
#' 
#' # Daily performance with engagement metrics
#' get_daily_performance("this_month", metrics = c("views", "likes", "comments", "shares"))
#' }
get_daily_performance <- function(date_range, end_date = NULL, ids = "channel==MINE",
                                metrics = c("views", "estimatedMinutesWatched"), ...) {
  
  get_report(
    ids = ids,
    metrics = paste(metrics, collapse = ","),
    dimensions = "day",
    start_date = date_range,
    end_date = end_date,
    sort = "day",  # Sort chronologically
    ...
  )
}

#' Get revenue report (requires monetary scope)
#' 
#' Retrieves revenue and monetization metrics.
#' 
#' @param date_range Date range string or start date
#' @param end_date End date (only needed if date_range is a specific start date)
#' @param ids Channel identifier (default: "channel==MINE")
#' @param currency Currency code (default: "USD")
#' @param include_cpm Logical. Include CPM metrics (default: TRUE)
#' @param ... Additional arguments passed to get_report()
#' @return API response with revenue data
#' @export
#' @examples
#' \dontrun{
#' # Revenue report for last month
#' get_revenue_report("last_month")
#' 
#' # Revenue in different currency
#' get_revenue_report("this_quarter", currency = "EUR")
#' }
get_revenue_report <- function(date_range, end_date = NULL, ids = "channel==MINE",
                             currency = "USD", include_cpm = TRUE, ...) {
  
  metrics <- c("estimatedRevenue", "adEarnings", "monetizedPlaybacks")
  
  if (include_cpm) {
    metrics <- c(metrics, "playbackBasedCpm", "impressionBasedCpm")
  }
  
  get_report(
    ids = ids,
    metrics = paste(metrics, collapse = ","),
    start_date = date_range,
    end_date = end_date,
    currency = currency,
    ...
  )
}