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

  assert_string(ids, .var.name = "ids")

  if (!grepl("^(channel|contentOwner)==", ids)) {
    tubern_abort(
      c(
        "ids parameter must be in format:",
        "'channel==MINE', 'channel==CHANNEL_ID', or 'contentOwner==OWNER_NAME'"
      ),
      class = "parameter"
    )
  }

  if (grepl("^channel==UC", ids) && !grepl("^channel==MINE$", ids)) {
    tubern_warn(
      c(
        "Using a specific channel ID may result in 404 errors.",
        "YouTube Analytics API only allows access to your own channel's data.",
        "Use 'channel==MINE' to access your authenticated channel's analytics.",
        "Only YouTube Partner content owners can access other channels' data."
      ),
      class = "parameter"
    )
  }

  if (is.null(start_date)) {
    tubern_abort("start_date is required", class = "parameter")
  }

  dates <- resolve_date_range(start_date, end_date)
  start_date <- dates$start_date
  end_date <- dates$end_date

  final_dates <- .validate_dates(start_date, end_date)
  start_date <- final_dates$start_date
  end_date <- final_dates$end_date

  metrics <- .validate_metrics(metrics)
  metrics_param <- paste(metrics, collapse = ",")

  dimensions <- .validate_dimensions(dimensions, filters)
  dimensions_param <- if (!is.null(dimensions)) paste(dimensions, collapse = ",") else NULL

  filters <- .validate_filters(filters, dimensions)

  if (!is.null(currency)) {
    assert_string(currency, .var.name = "currency")
    valid_currencies <- c("USD", "EUR", "GBP", "JPY", "KRW", "INR", "CAD", "AUD")
    if (!currency %in% valid_currencies) {
      tubern_warn(
        paste0("Currency '", currency, "' may not be supported. Common currencies: ",
               paste(valid_currencies, collapse = ", ")),
        class = "parameter"
      )
    }
  }

  if (!is.null(max_results)) {
    assert_int(max_results, lower = 1, upper = 200, .var.name = "max_results")
  }

  if (!is.null(start_index)) {
    assert_int(start_index, lower = 1, .var.name = "start_index")
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

  tubern_GET("reports", querylist, ...)
}
