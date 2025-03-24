#' Set up Authorization
#'
#' The function looks for .httr-oauth in the working directory. If it doesn't find it, it expects an application ID and a secret.
#' If you want to remove the existing .httr-oauth, set remove_old_oauth to TRUE. By default, it is set to FALSE.
#' The function launches a browser to allow you to authorize the application
#'
#' @param app_id client id; required; no default
#' @param app_secret client secret; required; no default
#' @param scope Character. \code{analytics} or \code{monetary-analytics}. Required. Default is \code{monetary-analytics}.
#' The scopes are largely exchangeable but \code{monetary-analytics} yields extra authorizations that come in handy.
#' @param token path to file containing the token. If a path is given, the function will first try to read from it. Default is \code{.httr-oauth} in the local directory.
#' So if there is such a file, the function will first try to read from it.
#' @param \dots Additional arguments passed to \code{\link[httr]{oauth2.0_token}}
#'
#' @return sets the google_token option and also saves .httr_auth in the working directory (find out the working directory via getwd())
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/}
#' @references \url{https://developers.google.com/youtube/analytics/v1/reference/} for different scopes
#'
#' @examples
#'  \dontrun{
#'    yt_oauth("998136489867-5t3tq1g7hbovoj46dreqd6k5kd35ctjn.apps.googleusercontent.com",
#'             "MbOSt6cQhhFkwETXKur-L9rN")
#' }

yt_oauth <- function (app_id = NULL, app_secret = NULL,
                      scope = "analytics", token = ".httr-oauth", ...) {

  if (file.exists(token)) {

    google_token <- try(suppressWarnings(readRDS(token)), silent = TRUE)

    if ( inherits(google_token, "try-error")) {
          stop(sprintf("Unable to read token from:%s", token))
      }

    google_token <- google_token[[1]]

  } else if (is.null(app_id) | is.null(app_secret)) {

    stop("Please provide values for app_id and app_secret")

  } else {

    myapp <- oauth_app("google", key = app_id, secret = app_secret)

    if (scope == "analytics") {
      google_token <- oauth2.0_token(
                oauth_endpoints("google"),
                myapp,
                scope = "https://www.googleapis.com/auth/yt-analytics.readonly",
                ...)

    } else if (scope == "monetary-analytics") {
      google_token <- oauth2.0_token(
       oauth_endpoints("google"),
       myapp,
       scope = "https://www.googleapis.com/auth/yt-analytics-monetary.readonly",
       ...)
    }
  }

  options(google_token = google_token)
}
