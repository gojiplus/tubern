#' List Groups
#'
#' @param filter Named Vector. Required. Only One of the two: id or mine.
#' id ``The Named parameter specifies a comma-separated list of the YouTube group ID(s) for the resource(s) that are being retrieved.''
#' mine String. Can be 'True' or 'False.' ``Set this parameter's value to true to retrieve all groups owned by the authenticated user.''
#' @param page_token String. Optional. ``Identifies a specific page in the result set that should be returned.''
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_GET}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/groups/list}
#'
#' @examples
#' \dontrun{
#' list_groups(filter = c(mine = 'True'))
#' }

list_groups <- function (filter, page_token, ...) {

  querylist <- list()
  querylist <- c(querylist, filter)

  res <- tubern_GET("groups", querylist, ...)

  res
}
