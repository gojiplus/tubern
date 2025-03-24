#' \pkg{tubern} provides access to the YouTube Analytics and Reporting API
#'
#' @importFrom httr GET POST PUT DELETE authenticate config stop_for_status upload_file content oauth_endpoints oauth_app oauth2.0_token
#' @importFrom jsonlite toJSON
#' @importFrom utils URLencode
#' @name tubern
"_PACKAGE"


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

  yt_check_token()

  req <- GET("https://www.googleapis.com/",
             path = paste0("youtube/analytics/v1/", path),
             query = query, config(token = getOption("google_token")), ...)

  stop_for_status(req)
  res <- content(req)

  res
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

  yt_check_token()

  req <- POST("https://www.googleapis.com/",
              path = paste0("youtube/analytics/v1/", path),
              body = body, query = query,
              config(token = getOption("google_token")), ...)
  stop_for_status(req)
  res <- content(req)

  res
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

  yt_check_token()

  req <- PUT("https://www.googleapis.com/",
             path = paste0("youtube/analytics/v1/", path),
             body = body, query = query,
             config(token = getOption("google_token")), ...)
  stop_for_status(req)
  res <- content(req)

  res
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

  yt_check_token()

  req <- DELETE("https://www.googleapis.com/",
                path = paste0("youtube/analytics/v1/", path),
                body = body, query = query,
                config(token = getOption("google_token")), ...)
  stop_for_status(req)
  res <- content(req)

  res
}
