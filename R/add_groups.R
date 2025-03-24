#' Add Groups
#'
#' @param resource_details Named nested list. Required. Must provide:
#' etag, snippet title and contentDetails itemType
#' @param \dots Additional arguments passed to \code{\link[tubern]{tubern_POST}}.
#'
#' @return named list
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/groups/insert}
#'
#' @examples
#'
#' \dontrun{
#' add_groups(list(etag="vponEBg8hrR1yBUX0Hz66Uc5WMk/vyGp6PvFo4RvsFtPoIWeCReyIC8",
#' ContentDetails = list(itemType="youtube#channel"), snippet = list(title ="hello")))
#' }

add_groups <- function (resource_details, ...) {

  json_arg <- toJSON(resource_details, auto_unbox = TRUE)
  res      <- tubern_POST("groups", body = json_arg, encode = "json", ...)
  res
}
