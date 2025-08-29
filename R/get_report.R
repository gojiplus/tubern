#' Get Reports
#'
#' Retrieves YouTube Analytics reports containing YouTube Analytics data.
#'
#' @param ids Named vector with two potential names: channel or contentOwner
#' If channel, potential values are: mine or channel_id
#' If contentOwner, potential values are: owner_id of the content
#'
#' @param metrics String. Comma-separated list of YouTube Analytics metrics, such as \code{views} or \code{likes,dislikes}.
#' @param start_date String. Start date for the report. Must be in YYYY-MM-DD format.
#' @param end_date String. End date for the report. Must be in YYYY-MM-DD format.
#' @param currency Optional. String. Default is USD. Specifies what earnings metrics like
#' \code{earnings, adEarnings, grossRevenue, playbackBasedCpm, impressionBasedCpm} will be reported in.
#' @param dimensions String. Optional. Comma-separated list of YouTube Analytics dimensions, such as \code{video} or \code{ageGroup,gender}.
#' @param filters String. Optional. Dimension value filters. For instance, ``\code{video==pd1FJh59zxQ,Zhawgd0REhA;country==IT}
#' restricts the result set to include data for the given videos in Italy''
#' @param include_historical_channel_data Boolean. Default is FALSE.
#' ``Whether the API response should include channels' watch time and view data from the time period prior
#' to when the channels were linked to the content owner.''
#' @param max_results Integer. Optional. The maximum number of rows to include in the response.
#' @param sort String. Optional A comma-separated list of dimensions or metrics that determine the sort order for YouTube
#' @param start_index Integer. Optional. ``The 1-based index of the first entity to retrieve.''
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_GET}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/reference/reports/query}
#'
#' @examples
#' \dontrun{
#' get_report(ids = "channel==MINE", metrics = "views",
#' start_date = "2010-04-01", end_date ="2017-01-01")
#' }

get_report <- function (ids, metrics, start_date = NULL, end_date = NULL,
                        currency = NULL, dimensions = NULL, filters = NULL,
                        include_historical_channel_data = NULL,
                        max_results = NULL, sort = NULL,
                        start_index = NULL, ...) {

  querylist <- list(ids = URLencode(ids),
                    startDate = start_date,
                    endDate = end_date,
                    metrics = metrics,
                    currency = currency,
                    dimensions = dimensions,
                    filters = filters,
                    maxResults = max_results,
                    sort = sort,
                    includeHistoricalChannelData = include_historical_channel_data,
                    startIndex = start_index)

  res <- tubern_GET("reports", querylist, ...)

  res
}
