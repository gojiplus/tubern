#' Delete Group
#'
#' @param id  String. Required.
#' ``The id parameter specifies the YouTube group ID of the group that is being deleted.''
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_PUT}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/groups/delete}
#'
#' @examples
#'
#' \dontrun{
#' delete_group(id="ABZZzGSIAAA")
#' }

delete_group <- function (id, ...) {

  querylist <- list(id = id)
  res      <- tubern_DELETE("groups", query = querylist, ...)
  res
}
