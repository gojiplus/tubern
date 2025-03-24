#' Add Group Item
#'
#' @param resource_details Named nested list. Required. Must provide:
#' groupId, resource.id
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_POST}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/groupItems/insert}
#'
#' @examples
#'
#' \dontrun{
#' add_group_item(list(groupId = "", resouce.id ="hello"))
#' }

add_group_item <- function (resource_details, ...) {

  json_arg <- toJSON(resource_details, auto_unbox = TRUE)
  res      <- tubern_POST("groupItems", body = json_arg, encode = "json", ...)
  res
}
