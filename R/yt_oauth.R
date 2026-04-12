#' Set up Authorization
#'
#' Simplified OAuth2 setup for YouTube Analytics API. This function will automatically
#' detect the required scope based on your needs and provide helpful setup guidance.
#'
#' The function looks for .httr-oauth in the working directory. If it doesn't find it,
#' it expects an application ID and a secret. The function launches a browser to allow
#' you to authorize the application.
#'
#' @param app_id Client ID from Google Cloud Console; required; no default
#' @param app_secret Client secret from Google Cloud Console; required; no default
#' @param scope Character. One of:
#'   \itemize{
#'     \item \code{"analytics"} - Basic analytics data (views, likes, etc.) - Default
#'     \item \code{"monetary"} - Includes revenue and monetization data
#'     \item \code{"auto"} - Automatically detect scope based on first API call
#'   }
#' @param token Path to file containing the token. Default is \code{.httr-oauth} in working directory.
#' @param setup_guide Logical. Show setup guide for first-time users (default: TRUE for interactive sessions)
#' @param \dots Additional arguments passed to \code{\link[httr]{oauth2.0_token}}
#'
#' @return Sets the google_token option and saves .httr-oauth in working directory
#'
#' @export
#'
#' @references \url{https://developers.google.com/youtube/analytics/reference/}
#'
#' @examples
#'  \dontrun{
#'    # Basic setup (will show setup guide first time)
#'    yt_oauth("your-client-id.apps.googleusercontent.com", "your-client-secret")
#'
#'    # Setup with monetary scope for revenue data
#'    yt_oauth("your-client-id.apps.googleusercontent.com", "your-client-secret",
#'             scope = "monetary")
#'
#'    # Skip setup guide
#'    yt_oauth("your-client-id.apps.googleusercontent.com", "your-client-secret",
#'             setup_guide = FALSE)
#' }

yt_oauth <- function (app_id = NULL, app_secret = NULL,
                      scope = "analytics", token = ".httr-oauth",
                      setup_guide = interactive(), ...) {

  assert_string(scope, .var.name = "scope")
  assert_string(token, .var.name = "token")
  assert_flag(setup_guide, .var.name = "setup_guide")

  if (setup_guide && !file.exists(token) && is.null(app_id)) {
    .show_oauth_setup_guide()
    return(invisible())
  }

  if (file.exists(token)) {
    google_token <- tryCatch(
      suppressWarnings(readRDS(token)),
      error = function(e) {
        tubern_abort(
          c(
            paste0("Unable to read token from: ", token),
            "The token file may be corrupted. Delete it and run yt_oauth() again."
          ),
          class = "auth"
        )
      }
    )

    google_token <- google_token[[1]]

    tryCatch({
      if (!is.null(google_token) && !is.null(google_token$credentials)) {
        tubern_inform("Using existing authentication token")
        options(google_token = google_token)
        return(invisible())
      }
    }, error = function(e) {
      tubern_warn("Existing token appears invalid, creating new one...")
    })
  }

  if (is.null(app_id) || is.null(app_secret)) {
    tubern_abort(
      c(
        "OAuth credentials required. Please provide app_id and app_secret.",
        "Need help? Run yt_oauth() with no parameters to see the setup guide."
      ),
      class = "auth"
    )
  }

  assert_string(app_id, .var.name = "app_id")
  assert_string(app_secret, .var.name = "app_secret")

  if (!grepl("\\.apps\\.googleusercontent\\.com$", app_id)) {
    tubern_warn("app_id should end with '.apps.googleusercontent.com'")
  }

  myapp <- oauth_app("google", key = app_id, secret = app_secret)

  scopes <- .get_oauth_scopes(scope)

  tubern_inform(paste("Setting up OAuth with scope:", scope))
  tubern_inform("Opening browser for authentication...")

  google_token <- tryCatch({
    oauth2.0_token(
      oauth_endpoints("google"),
      myapp,
      scope = scopes,
      ...
    )
  }, error = function(e) {
    tubern_abort(
      c(
        paste("OAuth setup failed:", conditionMessage(e)),
        "Check your app_id and app_secret, and ensure YouTube Analytics API is enabled."
      ),
      class = "auth"
    )
  })

  options(google_token = google_token)
  tubern_inform("Authentication successful!")

  tryCatch({
    yt_check_token()
    tubern_inform("Token validation successful")
  }, error = function(e) {
    tubern_warn(
      "Token created but validation failed. You may need to enable YouTube Analytics API in Google Cloud Console."
    )
  })
}

#' Get OAuth scopes based on scope parameter
#' @param scope Scope parameter from yt_oauth
#' @return Character vector of OAuth scope URLs
#' @keywords internal
#' @noRd
.get_oauth_scopes <- function(scope) {
  switch(scope,
    "analytics" = c(
      "https://www.googleapis.com/auth/yt-analytics.readonly",
      "https://www.googleapis.com/auth/youtube.readonly"
    ),
    "monetary" = c(
      "https://www.googleapis.com/auth/yt-analytics-monetary.readonly",
      "https://www.googleapis.com/auth/youtube.readonly"
    ),
    "auto" = c(
      "https://www.googleapis.com/auth/yt-analytics.readonly",
      "https://www.googleapis.com/auth/youtube.readonly"
    ),
    tubern_abort(
      "Invalid scope. Use 'analytics', 'monetary', or 'auto'",
      class = "parameter"
    )
  )
}

#' Show OAuth setup guide for first-time users
#' @keywords internal
#' @noRd
.show_oauth_setup_guide <- function() {
  cat("=== YouTube Analytics API Setup Guide ===\n\n")

  cat("To use tubern, you need to set up OAuth2 credentials:\n\n")

  cat("1. Go to Google Cloud Console: https://console.cloud.google.com\n")
  cat("2. Create a new project or select an existing one\n")
  cat("3. Enable the YouTube Analytics API:\n")
  cat("   - Go to 'APIs & Services' > 'Library'\n")
  cat("   - Search for 'YouTube Analytics API'\n")
  cat("   - Click 'Enable'\n\n")

  cat("4. Create OAuth2 credentials:\n")
  cat("   - Go to 'APIs & Services' > 'Credentials'\n")
  cat("   - Click '+ CREATE CREDENTIALS' > 'OAuth client ID'\n")
  cat("   - Choose 'Desktop application'\n")
  cat("   - Give it a name (e.g., 'tubern R client')\n")
  cat("   - Click 'Create'\n\n")

  cat("5. Copy your credentials and run:\n")
  cat("   yt_oauth('your-client-id.apps.googleusercontent.com', 'your-client-secret')\n\n")

  cat("Need help? Visit: https://developers.google.com/youtube/analytics/registering_an_application\n")
  cat("===========================================\n")
}
