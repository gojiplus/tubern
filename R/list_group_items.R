#' List Group Items
#'
#' @param group_id String. Required. ID of the group
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_GET}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/groupItems/list}
#'
#' @examples
#' \dontrun{
#' list_group_items(group_id = "vponEBg8hrR1yBUX0Hz66Uc5WMk/vyGp6PvFo4RvsFtPoIWeCReyIC8")
#' }

list_group_items <- function (group_id, ...) {

  querylist <- c(groupId = group_id)

  res <- tubern_GET("groupItems", querylist, ...)

  res
}
