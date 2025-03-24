#' Update Groups
#'
#' @param resource_details Named nested list. Required. Must provide:
#' id, snippet title
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_PUT}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/groups/update}
#'
#' @examples
#'
#' \dontrun{
#' update_group(list(id="ABZZzGSIAAA", snippet = list(title ="hello")))
#' }

update_group <- function (resource_details, ...) {

  json_arg <- toJSON(resource_details, auto_unbox = TRUE)
  res      <- tubern_PUT("groups", body = json_arg, encode = "json", ...)
  res
}
