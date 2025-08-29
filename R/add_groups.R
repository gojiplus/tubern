#' Add Groups
#'
#' Creates a new channel group.
#'
#' @param resource_details Named nested list. Required. Must provide:
#' snippet with title (required), and optionally description and contentDetails with itemType
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_POST}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/reference/groups/insert}
#'
#' @examples
#'
#' \dontrun{
#' add_groups(list(
#'   snippet = list(
#'     title = "My Channel Group",
#'     description = "A group for organizing channels"
#'   ),
#'   contentDetails = list(itemType = "youtube#channel")
#' ))
#' }

add_groups <- function (resource_details, ...) {

  json_arg <- toJSON(resource_details, auto_unbox = TRUE)
  res      <- tubern_POST("groups", body = json_arg, encode = "json", ...)
  res
}
