#' Delete Group
#'
#' @param id  String. Required.
#' ``The id parameter specifies the YouTube group ID of the group that is being deleted.''
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_DELETE}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/reference/groups/delete}
#'
#' @examples
#' \dontrun{
#' delete_group(id = "ABZZzGSIAAA")
#' }
delete_group <- function(id, ...) {
  assert_string(id, .var.name = "id")

  querylist <- list(id = id)
  tubern_DELETE("groups", query = querylist, ...)
}
