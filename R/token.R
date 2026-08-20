#' OAuth token storage and access
#'
#' The token lives in `options(google_token)` as an httr2 token, and the
#' client that minted it lives in `options(tubern.oauth_client)` so an
#' expired token can be refreshed without asking the user to authenticate
#' again. Both are set by [yt_oauth()].
#'
#' @name tubern-token
#' @keywords internal
NULL

# Google's OAuth endpoints. Named constants because they appear in the flow,
# in the refresh, and in the setup guide.
.oauth_auth_url <- "https://accounts.google.com/o/oauth2/auth"
.oauth_token_url <- "https://oauth2.googleapis.com/token"

#' Build the OAuth client for a set of app credentials
#'
#' @param app_id Client ID from Google Cloud Console
#' @param app_secret Client secret from Google Cloud Console
#' @return An httr2 OAuth client
#' @keywords internal
#' @noRd
.oauth_client <- function(app_id, app_secret) {
  oauth_client(
    id = app_id,
    secret = app_secret,
    token_url = .oauth_token_url,
    name = "tubern"
  )
}

#' Is this token expired, or close enough to it?
#'
#' A token that expires while the request is in flight is no more useful
#' than one that has already expired, so treat the last minute as expired.
#'
#' @param token An httr2 token
#' @return Logical
#' @keywords internal
#' @noRd
.token_expired <- function(token) {
  expires_at <- token$expires_at
  if (is.null(expires_at)) {
    return(FALSE)
  }
  as.numeric(expires_at) - as.numeric(Sys.time()) < 60
}

#' Get a usable access token, refreshing it if it has expired
#'
#' @return The bearer token as a string
#' @keywords internal
#' @noRd
yt_access_token <- function() {
  yt_check_token()
  token <- getOption("google_token")

  if (.token_expired(token) && !is.null(token$refresh_token)) {
    client <- getOption("tubern.oauth_client")
    if (is.null(client)) {
      tubern_abort(
        c(
          "The access token has expired and cannot be refreshed.",
          "Run yt_oauth() again to authenticate."
        ),
        class = "auth"
      )
    }
    token <- tryCatch(
      oauth_flow_refresh(client, refresh_token = token$refresh_token),
      error = function(e) {
        tubern_abort(
          c(
            paste("Could not refresh the access token:", conditionMessage(e)),
            "Run yt_oauth() again to authenticate."
          ),
          class = "auth"
        )
      }
    )
    options(google_token = token)
  }

  access <- token$access_token
  if (is.null(access) || !nzchar(access)) {
    tubern_abort(
      "The stored token carries no access token. Run yt_oauth() again.",
      class = "auth"
    )
  }
  access
}

#' Save a token without overwriting somebody else's cache
#'
#' `.httr-oauth` is httr's shared cache, and other packages in the same
#' working directory read it expecting httr tokens. Writing an httr2 token
#' over one would break their authentication, so refuse rather than clobber.
#'
#' @param token An httr2 token
#' @param path Path to write to
#' @return Invisibly, the path
#' @keywords internal
#' @noRd
.save_token_file <- function(token, path) {
  if (file.exists(path)) {
    existing <- tryCatch(suppressWarnings(readRDS(path)), error = function(e) NULL)
    is_httr_cache <- inherits(existing, "Token2.0") ||
      (is.list(existing) && length(existing) > 0 &&
         inherits(existing[[1]], "Token2.0"))
    if (is_httr_cache) {
      tubern_abort(
        c(
          paste0(path, " holds an httr token cache, which other packages read."),
          "Refusing to overwrite it. Pass a different `token` path.",
          "The default is .tubern-oauth."
        ),
        class = "auth"
      )
    }
  }
  saveRDS(token, path)
  invisible(path)
}

#' Read a saved token, if the file holds one this version understands
#'
#' Versions before 0.6.0 stored an httr `Token2.0` in `.httr-oauth`. Those
#' cannot be used by httr2 and are reported as such rather than failing
#' later with something obscure about a missing access token.
#'
#' @param path Path to the token file
#' @return An httr2 token, or NULL
#' @keywords internal
#' @noRd
.read_token_file <- function(path) {
  saved <- tryCatch(
    suppressWarnings(readRDS(path)),
    error = function(e) {
      tubern_abort(
        c(
          paste0("Unable to read token from: ", path),
          "The token file may be corrupted. Delete it and run yt_oauth() again."
        ),
        class = "auth"
      )
    }
  )

  if (inherits(saved, "httr2_token")) {
    return(saved)
  }

  # An httr cache is a list of Token2.0 objects keyed by hash.
  looks_like_httr <- inherits(saved, "Token2.0") ||
    (is.list(saved) && length(saved) > 0 && inherits(saved[[1]], "Token2.0"))
  if (looks_like_httr) {
    tubern_inform(
      c(
        paste0("The token in ", path, " was created by an older version."),
        "tubern now authenticates with httr2, so it cannot be reused.",
        "Authenticating again; the new token replaces it."
      )
    )
    return(NULL)
  }

  NULL
}
