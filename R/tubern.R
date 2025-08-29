#' \pkg{tubern} provides access to the YouTube Analytics and Reporting API
#'
#' @importFrom httr GET POST PUT DELETE authenticate config stop_for_status upload_file content oauth_endpoints oauth_app oauth2.0_token
#' @importFrom jsonlite toJSON
#' @importFrom utils URLencode
#' @name tubern
"_PACKAGE"

# Internal: base URL for YouTube Analytics API
.api_base <- "https://youtubeanalytics.googleapis.com/v2"

# Internal: send API request to YouTube Analytics
# @param method character: one of "GET", "POST", "PUT", "DELETE"
# @param path character: API endpoint path (relative to base)
# @param query list: query parameters
# @param body optional body for POST/PUT/DELETE
# @param ... additional args passed to httr functions (e.g., encode)
# @return parsed content as list
.api_request <- function(method, path, query = NULL, body = NULL, ...) {
  yt_check_token()
  url <- paste0(.api_base, "/", path)
  fun <- switch(method,
                GET = GET,
                POST = POST,
                PUT = PUT,
                DELETE = DELETE,
                stop("Unsupported HTTP method: ", method))
  req <- fun(url,
             query = query,
             body = body,
             config(token = getOption("google_token")),
             ...)
  stop_for_status(req)
  content(req)
}


#' Check if authentication token is in options
#'

yt_check_token <- function() {

  app_token <- getOption("google_token")
    if (is.null(app_token)) stop("Please get a token using yt_oauth()")

}

#'
#' Base POST AND GET functions. Not exported.

#'
#' GET
#'
#' @param path path to specific API request URL
#' @param query query list
#' @param \dots Additional arguments passed to \code{\link[httr]{GET}}.
#' @return list

tubern_GET <- function(path, query = NULL, ...) {
  .api_request("GET", path, query = query, ...)
}

#'
#' POST
#'
#' @param path path to specific API request URL
#' @param query query list
#' @param body passing image through body
#' @param \dots Additional arguments passed to \code{\link[httr]{POST}}.
#'
#' @return list

tubern_POST <- function(path, query = NULL, body = "", ...) {
  .api_request("POST", path, query = query, body = body, ...)
}

#'
#' PUT
#'
#' @param path path to specific API request URL
#' @param query query list
#' @param body passing image through body
#' @param \dots Additional arguments passed to \code{\link[httr]{PUT}}.
#'
#' @return list

tubern_PUT <- function(path, query = NULL, body = "", ...) {
  .api_request("PUT", path, query = query, body = body, ...)
}

#'
#' DELETE
#'
#' @param path path to specific API request URL
#' @param query query list
#' @param body passing image through body
#' @param \dots Additional arguments passed to \code{\link[httr]{DELETE}}.
#'
#' @return list

tubern_DELETE <- function(path, query = NULL, body = "", ...) {
  .api_request("DELETE", path, query = query, body = body, ...)
}
