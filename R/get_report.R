#' Get Reports
#'
#' Retrieves YouTube Analytics reports containing YouTube Analytics data.
#'
#' @param ids String. Channel or content owner identifier.
#' For channels: \code{"channel==MINE"} (for authenticated user's channel) or
#' \code{"channel==UCxxxxxxxxxxxxxxx"} (for specific channel ID).
#' For content owners: \code{"contentOwner==ownerName"}.
#'
#' @param metrics String. Comma-separated list of YouTube Analytics metrics,
#' such as \code{views} or \code{likes,dislikes}.
#' @param start_date String. Start date for the report.
#' Can be in YYYY-MM-DD format or relative date like "last_30_days", "this_month", "yesterday".
#' @param end_date String. End date for the report.
#' Can be in YYYY-MM-DD format or relative date. If NULL and start_date is relative, will be calculated automatically.
#' @param currency Optional. String. Default is USD. Specifies what earnings
#' metrics like \code{earnings, adEarnings, grossRevenue, playbackBasedCpm,
#' impressionBasedCpm} will be reported in.
#' @param dimensions String. Optional. Comma-separated list of YouTube Analytics
#' dimensions, such as \code{video} or \code{ageGroup,gender}.
#' @param filters String. Optional. Dimension value filters. Multiple filters
#' can be separated by semicolons. For video filtering:
#' \code{"video==videoId1,videoId2"} (comma-separated video IDs).
#' For country filtering: \code{"country==US"}.
#' Combined example: \code{"video==videoId1,videoId2;country==US"}.
#' Note: When filtering by video IDs, ensure the \code{dimensions} parameter
#' includes "video".
#' @param include_historical_channel_data Boolean. Default is FALSE.
#' ``Whether the API response should include channels' watch time and view data
#' from the time period prior to when the channels were linked to the content
#' owner.''
#' @param max_results Integer. Optional. The maximum number of rows to
#' include in the response.
#' @param sort String. Optional A comma-separated list of dimensions or metrics
#' that determine the sort order for YouTube
#' @param start_index Integer. Optional. ``The 1-based index of the first
#' entity to retrieve.''
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_GET}}.
#'
#' @return named list
#'
#' @export
#'
#' @references
#' \url{https://developers.google.com/youtube/analytics/reference/reports/query}
#'
#' @section Troubleshooting 404 Errors:
#' If you encounter a 404 "Not Found" error, check the following:
#' \itemize{
#'   \item Ensure YouTube Analytics API is enabled in your Google Cloud Console
#'   project
#'   \item Verify your authentication token is valid and has the correct scopes
#'   \item Check that the channel ID (if using specific channel ID) exists and
#'   you have access to it
#'   \item Use \code{"channel==MINE"} to access your own authenticated channel's
#'   data
#' }
#'
#' @examples
#' \dontrun{
#' # Basic channel report
#' get_report(ids = "channel==MINE", metrics = "views",
#'            start_date = "2020-01-01", end_date = "2020-01-31")
#'
#' # Report with video filtering (requires dimensions = "video")
#' get_report(ids = "channel==MINE",
#'            metrics = "views,likes,comments",
#'            dimensions = "video",
#'            filters = "video==videoId1,videoId2",
#'            start_date = "2020-01-01", end_date = "2020-01-31")
#'
#' # Report with country filtering
#' get_report(ids = "channel==MINE",
#'            metrics = "views",
#'            filters = "country==US",
#'            start_date = "2020-01-01", end_date = "2020-01-31")
#' }

get_report <- function(ids, metrics, start_date = NULL, end_date = NULL,
                        currency = NULL, dimensions = NULL, filters = NULL,
                        include_historical_channel_data = NULL,
                        max_results = NULL, sort = NULL,
                        start_index = NULL, ...) {

  # Validate required parameters
  if (!grepl("^(channel|contentOwner)==", ids)) {
    stop("ids parameter must be in format 'channel==MINE', ",
         "'channel==CHANNEL_ID', or 'contentOwner==OWNER_NAME'", call. = FALSE)
  }
  
  # Resolve date range (handles both relative and absolute dates)
  if (is.null(start_date)) {
    stop("start_date is required", call. = FALSE)
  }
  
  dates <- resolve_date_range(start_date, end_date)
  start_date <- dates$start_date
  end_date <- dates$end_date
  
  # Additional validation for resolved dates
  final_dates <- .validate_dates(start_date, end_date)
  start_date <- final_dates$start_date
  end_date <- final_dates$end_date
  
  # Validate metrics
  metrics <- .validate_metrics(metrics)
  metrics_param <- paste(metrics, collapse = ",")
  
  # Validate dimensions 
  dimensions <- .validate_dimensions(dimensions, filters)
  dimensions_param <- if (!is.null(dimensions)) paste(dimensions, collapse = ",") else NULL
  
  # Validate filters
  filters <- .validate_filters(filters, dimensions)
  
  # Validate currency
  if (!is.null(currency) && !currency %in% c("USD", "EUR", "GBP", "JPY", "KRW", "INR", "CAD", "AUD")) {
    warning("Currency '", currency, "' may not be supported. Common currencies: USD, EUR, GBP, JPY", 
            call. = FALSE)
  }
  
  # Validate max_results
  if (!is.null(max_results)) {
    if (!is.numeric(max_results) || max_results < 1 || max_results > 200) {
      stop("max_results must be between 1 and 200", call. = FALSE)
    }
  }
  
  # Validate start_index
  if (!is.null(start_index)) {
    if (!is.numeric(start_index) || start_index < 1) {
      stop("start_index must be a positive integer", call. = FALSE)
    }
  }

  querylist <- list(ids = URLencode(ids),
                    startDate = start_date,
                    endDate = end_date,
                    metrics = metrics_param,
                    currency = currency,
                    dimensions = dimensions_param,
                    filters = filters,
                    maxResults = max_results,
                    sort = sort,
                    includeHistoricalChannelData =
                      include_historical_channel_data,
                    startIndex = start_index)

  res <- tubern_GET("reports", querylist, ...)

  res
}
