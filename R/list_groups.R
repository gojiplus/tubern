#' List Groups
#'
#' @param filter Named Vector. Required. Only one of the two: id or mine.
#' id: Comma-separated list of YouTube group ID(s) to retrieve.
#' mine: Set to TRUE to retrieve all groups owned by the authenticated user.
#' @param page_token String. Optional. Identifies a specific page in the result set that should be returned.
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_GET}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/reference/groups/list}
#'
#' @examples
#' \dontrun{
#' list_groups(filter = c(mine = TRUE))
#' }

list_groups <- function (filter, page_token = NULL, ...) {

  querylist <- as.list(filter)
  if (!is.null(page_token)) {
    querylist$pageToken <- page_token
  }

  res <- tubern_GET("groups", querylist, ...)

  res
}
