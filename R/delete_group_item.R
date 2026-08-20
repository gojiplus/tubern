#' Delete Group Item
#'
#' @param id  String. Required.
#' ``The id parameter specifies the YouTube group item ID for the group that is being deleted.''
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_DELETE}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/reference/groupItems/delete}
#'
#' @examples
#' \dontrun{
#' delete_group_item(id = "ABZZzGSIAAA")
#' }
delete_group_item <- function(id, ...) {
  assert_string(id, .var.name = "id")

  querylist <- list(id = id)
  tubern_DELETE("groupItems", query = querylist, ...)
}
