#' \pkg{tubern} provides access to the YouTube Analytics and Reporting API
#'
#' @importFrom httr GET POST PUT DELETE authenticate config stop_for_status
#' @importFrom httr upload_file content oauth_endpoints oauth_app oauth2.0_token
#' @importFrom jsonlite toJSON
#' @importFrom utils URLencode adist packageVersion write.csv
#' @importFrom stats median
#' @importFrom graphics barplot points
#' @importFrom rlang abort warn inform caller_env
#' @importFrom checkmate assert_character assert_string assert_flag assert_int
#' @importFrom checkmate assert_number assert_list check_string
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
  .api_request_enhanced(method, path, query, body, ...)
}


#' Check if authentication token is in options
#'

yt_check_token <- function() {
  app_token <- getOption("google_token")
  if (is.null(app_token)) {
    tubern_abort(
      "No authentication token found. Run yt_oauth() to authenticate.",
      class = "auth"
    )
  }
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

tubern_GET <- function(path, query = NULL, ...) { # nolint: object_name_linter.
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

tubern_POST <- function(path, query = NULL, body = "", ...) { # nolint: object_name_linter.
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

tubern_PUT <- function(path, query = NULL, body = "", ...) { # nolint: object_name_linter.
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

tubern_DELETE <- function(path, query = NULL, body = "", ...) { # nolint: object_name_linter.
  .api_request("DELETE", path, query = query, body = body, ...)
}
