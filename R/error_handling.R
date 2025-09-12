#' Enhanced Error Handling for tubern
#'
#' Custom error classes and improved error handling for YouTube Analytics API
#' @name error_handling
NULL

#' Custom error class for YouTube Analytics API errors
#' 
#' @param message Error message
#' @param type Type of error (auth, quota, parameter, api)
#' @param call The call that generated the error
#' @param response Optional HTTP response object
#' @return An error object with class 'tubern_error'
#' @keywords internal
#' @noRd
tubern_error <- function(message, type = "general", call = NULL, response = NULL) {
  error <- list(
    message = message,
    type = type,
    call = call,
    response = response
  )
  class(error) <- c("tubern_error", "error", "condition")
  error
}

#' Enhanced API request function with better error handling
#' 
#' @param method HTTP method
#' @param path API endpoint path
#' @param query Query parameters
#' @param body Request body
#' @param ... Additional parameters
#' @return API response
#' @keywords internal
#' @noRd
.api_request_enhanced <- function(method, path, query = NULL, body = NULL, ...) {
  yt_check_token()
  
  url <- paste0(.api_base, "/", path)
  fun <- switch(method,
                GET = GET,
                POST = POST,
                PUT = PUT,
                DELETE = DELETE,
                stop("Unsupported HTTP method: ", method))
  
  # Make the request
  req <- tryCatch({
    fun(url,
        query = query,
        body = body,
        config(token = getOption("google_token")),
        ...)
  }, error = function(e) {
    stop(tubern_error(
      message = paste("Network error:", e$message),
      type = "network",
      call = sys.call(-1)
    ))
  })
  
  # Enhanced error handling based on HTTP status
  if (req$status_code != 200) {
    error_content <- tryCatch(content(req), error = function(e) NULL)
    
    error_message <- switch(as.character(req$status_code),
      "401" = "Authentication failed. Please check your OAuth token and scopes.",
      "403" = {
        if (!is.null(error_content) && 
            grepl("quotaExceeded|rateLimitExceeded", error_content$error$errors[[1]]$reason)) {
          "API quota exceeded. Try reducing the scope of your request or wait before trying again."
        } else {
          "Access forbidden. Check your permissions and API settings."
        }
      },
      "404" = paste(
        "Resource not found. This could mean:",
        "- YouTube Analytics API is not enabled in your Google Cloud project",
        "- The channel/content owner ID does not exist or you don't have access",
        "- Check your authentication scopes",
        sep = "\n"
      ),
      "400" = {
        if (!is.null(error_content) && !is.null(error_content$error$errors)) {
          error_details <- error_content$error$errors[[1]]
          if (!is.null(error_details$reason)) {
            switch(error_details$reason,
              "invalidParameter" = paste("Invalid parameter:", error_details$message),
              "invalidQuery" = paste("Invalid query:", error_details$message),
              "badRequest" = paste("Bad request:", error_details$message),
              paste("API error:", error_details$message)
            )
          } else {
            "Bad request. Check your parameters."
          }
        } else {
          "Bad request. Check your parameters."
        }
      },
      "429" = "Too many requests. Please slow down and try again.",
      "500" = "YouTube API server error. Please try again later.",
      paste("HTTP", req$status_code, "error occurred")
    )
    
    error_type <- switch(as.character(req$status_code),
      "401" = "auth",
      "403" = "quota", 
      "404" = "api",
      "400" = "parameter",
      "429" = "quota",
      "500" = "api",
      "api"
    )
    
    stop(tubern_error(
      message = error_message,
      type = error_type,
      call = sys.call(-1),
      response = req
    ))
  }
  
  content(req)
}

#' Check API quota status and provide guidance
#' 
#' @export
#' @return Message about current quota usage (if available)
#' @examples
#' \dontrun{
#' check_api_quota()
#' }
check_api_quota <- function() {
  tryCatch({
    # Make a minimal request to check quota status
    result <- get_report(
      ids = "channel==MINE", 
      metrics = "views",
      start_date = format(Sys.Date() - 1, "%Y-%m-%d"),
      end_date = format(Sys.Date() - 1, "%Y-%m-%d"),
      max_results = 1
    )
    message("API access is working normally.")
  }, error = function(e) {
    if (inherits(e, "tubern_error") && e$type == "quota") {
      message("Quota exceeded. Consider:")
      message("- Reducing the date range of your requests")
      message("- Using fewer metrics or dimensions") 
      message("- Implementing caching for repeated requests")
      message("- Checking your Google Cloud Console quota limits")
    } else if (inherits(e, "tubern_error") && e$type == "auth") {
      message("Authentication issue. Try:")
      message("- Running yt_oauth() again")
      message("- Checking your OAuth scopes")
      message("- Verifying your Google Cloud project settings")
    } else {
      message("API check failed: ", e$message)
    }
  })
}

#' Diagnose common tubern issues
#' 
#' @export
#' @return Diagnostic information about tubern setup
#' @examples
#' \dontrun{
#' diagnose_tubern()
#' }
diagnose_tubern <- function() {
  cat("=== tubern Diagnostic Report ===\n\n")
  
  # Check authentication
  cat("1. Authentication Status:\n")
  token <- getOption("google_token")
  if (is.null(token)) {
    cat("   X No authentication token found\n")
    cat("   -> Run yt_oauth() to authenticate\n\n")
  } else {
    cat("   OK Authentication token present\n")
    
    # Check token validity
    tryCatch({
      yt_check_token()
      cat("   OK Token validation passed\n")
    }, error = function(e) {
      cat("   X Token validation failed\n")
      cat("   -> Run yt_oauth() to refresh your token\n")
    })
    cat("\n")
  }
  
  # Check network connectivity
  cat("2. Network Connectivity:\n")
  tryCatch({
    # Try a simple HTTP request to Google
    test_req <- GET("https://www.googleapis.com")
    if (test_req$status_code == 200) {
      cat("   OK Network connection to Google APIs working\n")
    } else {
      cat("   X Network connection issues detected\n")
    }
  }, error = function(e) {
    cat("   X Network connection failed:", e$message, "\n")
    cat("   -> Check your internet connection and proxy settings\n")
  })
  cat("\n")
  
  # Check API access
  cat("3. YouTube Analytics API Access:\n")
  if (!is.null(token)) {
    tryCatch({
      check_api_quota()
    }, error = function(e) {
      cat("   X API access test failed\n")
      cat("   -> Error:", e$message, "\n")
    })
  } else {
    cat("   - Skipped (no authentication token)\n")
  }
  cat("\n")
  
  # Package information
  cat("4. Package Information:\n")
  cat("   tubern version:", as.character(packageVersion("tubern")), "\n")
  cat("   R version:", R.version.string, "\n")
  
  cat("\n=== End Diagnostic Report ===\n")
}