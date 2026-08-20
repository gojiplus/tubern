#' Enhanced Error Handling for tubern
#'
#' Custom error classes and improved error handling for YouTube Analytics API
#' using rlang for modern error handling patterns.
#' @name error_handling
#' @importFrom rlang abort warn inform caller_env
NULL

#' Abort with tubern-specific error class
#'
#' @param message Error message
#' @param class Additional error class (e.g., "auth", "quota", "parameter", "api")
#' @param ... Additional data to include in the error condition
#' @param call The call to include in the error (default: caller's environment)
#' @return Never returns; always throws an error
#' @keywords internal
#' @noRd
tubern_abort <- function(message, class = NULL, ..., call = caller_env()) {
  full_class <- c(
    if (!is.null(class)) paste0("tubern_", class, "_error"),
    "tubern_error"
  )
  abort(message, class = full_class, ..., call = call)
}

#' Warn with tubern-specific warning class
#'
#' @param message Warning message
#' @param class Additional warning class
#' @param ... Additional data to include in the warning condition
#' @keywords internal
#' @noRd
tubern_warn <- function(message, class = NULL, ...) {
  full_class <- c(
    if (!is.null(class)) paste0("tubern_", class, "_warning"),
    "tubern_warning"
  )
  warn(message, class = full_class, ...)
}

#' Inform with tubern-specific message class
#'
#' @param message Informational message
#' @param class Additional message class
#' @param ... Additional data to include in the message condition
#' @keywords internal
#' @noRd
tubern_inform <- function(message, class = NULL, ...) {
  full_class <- c(
    if (!is.null(class)) paste0("tubern_", class, "_message"),
    "tubern_message"
  )
  inform(message, class = full_class, ...)
}

#' Execute with retry for transient errors
#'
#' Implements exponential backoff retry logic for transient API errors.
#'
#' @param expr Expression to evaluate
#' @param max_tries Maximum number of attempts (default: 3)
#' @param base_delay Base delay in seconds between retries (default: 1)
#' @param max_delay Maximum delay in seconds (default: 60)
#' @param retry_on HTTP status codes to retry on (default: 429, 500, 502, 503, 504)
#' @return Result of the expression if successful
#' @keywords internal
#' @noRd
with_retry <- function(expr,
                       max_tries = 3,
                       base_delay = 1,
                       max_delay = 60,
                       retry_on = c(429L, 500L, 502L, 503L, 504L)) {
  # Re-evaluate the caller's expression on each attempt. Forcing the same
  # promise repeatedly warns ("restarting interrupted promise evaluation") and
  # memoises a successful result, so a retry would replay a stale value.
  call_expr <- substitute(expr)
  call_env <- parent.frame()

  # A distinct sentinel, so that a genuine NULL result is not read as a retry.
  retry_signal <- new.env(parent = emptyenv())

  attempt <- 1
  last_error <- NULL


  while (attempt <= max_tries) {
    result <- tryCatch(
      {
        eval(call_expr, call_env)
      },
      tubern_quota_error = function(e) {
        if (attempt < max_tries) {
          delay <- min(base_delay * (2^(attempt - 1)), max_delay)
          tubern_inform(
            sprintf(
              "Rate limited. Retrying in %.1f seconds (attempt %d/%d)...",
              delay, attempt, max_tries
            ),
            class = "retry"
          )
          Sys.sleep(delay)
        }
        last_error <<- e # nolint: assignment_linter.
        retry_signal
      },
      tubern_api_error = function(e) {
        status <- e$status_code
        if (!is.null(status) && status %in% retry_on && attempt < max_tries) {
          delay <- min(base_delay * (2^(attempt - 1)), max_delay)
          tubern_inform(
            sprintf(
              "Transient error (HTTP %d). Retrying in %.1f seconds (attempt %d/%d)...",
              status, delay, attempt, max_tries
            ),
            class = "retry"
          )
          Sys.sleep(delay)
          last_error <<- e # nolint: assignment_linter.
          return(retry_signal)
        }
        stop(e)
      },
      error = function(e) {
        stop(e)
      }
    )

    if (!identical(result, retry_signal)) {
      return(result)
    }

    attempt <- attempt + 1
  }

  if (!is.null(last_error)) {
    stop(last_error)
  }

  tubern_abort("Maximum retry attempts exceeded", class = "api")
}

#' Enhanced API request function with better error handling
#'
#' @param method HTTP method
#' @param path API endpoint path
#' @param query Query parameters
#' @param body Request body
#' @param ... Additional parameters
#' @param retry Logical. Whether to use retry logic (default: TRUE)
#' @return API response
#' @keywords internal
#' @noRd
.api_request_enhanced <- function(method, path, query = NULL, body = NULL, ..., retry = TRUE) {
  yt_check_token()

  if (!method %in% c("GET", "POST", "PUT", "DELETE")) {
    tubern_abort(paste("Unsupported HTTP method:", method), class = "parameter")
  }

  make_request <- function() {
    req <- request(.api_base)
    req <- req_url_path_append(req, path)
    if (length(query)) req <- req_url_query(req, !!!query)
    req <- req_method(req, method)
    req <- req_auth_bearer_token(req, yt_access_token())
    req <- req_user_agent(req, paste0(
      "tubern/", utils::packageVersion("tubern"),
      " (https://github.com/gojiplus/tubern)"
    ))
    if (!is.null(body)) req <- req_body_json(req, body)
    # Status handling stays with .handle_api_response(), which raises the
    # package's own condition classes; httr2 would otherwise raise its
    # httr2_http_* conditions before that code ever runs.
    req <- req_error(req, is_error = function(resp) FALSE)

    resp <- tryCatch(
      req_perform(req),
      httr2_failure = function(e) {
        tubern_abort(
          paste("Network error:", conditionMessage(e)),
          class = "network"
        )
      }
    )

    .handle_api_response(resp, query = query)
  }

  if (retry) {
    with_retry(make_request())
  } else {
    make_request()
  }
}

#' Parse a response body as JSON
#'
#' httr::content() parsed JSON with simplifyVector = FALSE, so everything
#' downstream of here expects nested lists rather than data frames.
#' resp_body_json() defaults the same way; passing it explicitly keeps the
#' two from drifting apart if that default ever changes. An empty body is
#' NULL rather than an error, because resp_body_raw() aborts on one and a
#' 204 has nothing to parse.
#'
#' @param resp httr2 response object
#' @return Parsed list, or NULL for an empty body
#' @keywords internal
#' @noRd
.resp_parsed <- function(resp) {
  if (!resp_has_body(resp)) {
    return(NULL)
  }
  resp_body_json(resp, simplifyVector = FALSE)
}

#' Handle API response and convert errors to rlang conditions
#'
#' @param req httr2 response object
#' @param query The request's query list, used to explain a rejected
#'   dimension/metric combination
#' @return Parsed content if successful
#' @keywords internal
#' @noRd
.handle_api_response <- function(req, query = NULL) {
  status <- resp_status(req)

  # Any 2xx is a success. groups.delete and groupItems.delete document HTTP 204
  # with an empty body, which has nothing to parse.
  if (status >= 200 && status < 300) {
    if (status == 204) {
      return(list())
    }
    return(.resp_parsed(req))
  }

  error_content <- tryCatch(.resp_parsed(req), error = function(e) NULL)

  error_info <- .parse_api_error(status, error_content, query = query)

  tubern_abort(
    error_info$message,
    class = error_info$class,
    status_code = status,
    response = req,
    api_error = error_content
  )
}

#' Parse API error response into message and class
#'
#' @param status_code HTTP status code
#' @param error_content Parsed error content from response
#' @param query The request's query list, if available
#' @return List with message and class
#' @keywords internal
#' @noRd
.parse_api_error <- function(status_code, error_content, query = NULL) {
  # An error body is not always a parsed list: an empty body comes back from
  # an empty body as raw(0), and `$` on an atomic vector is an error.
  error_details <- NULL
  if (is.list(error_content) && !is.null(error_content$error$errors)) {
    error_details <- error_content$error$errors[[1]]
  }

  result <- switch(as.character(status_code),
    "400" = {
      api_msg <- error_details$message
      msg <- if (!is.null(api_msg)) {
        paste("Bad request:", api_msg)
      } else {
        "Bad request. Check your parameters."
      }

      # "The query is not supported." is the answer to a request whose parts
      # are each valid but whose combination is not. YouTube Analytics is a
      # fixed set of reports, each with its own legal dimensions, metrics and
      # filters -- so `views` is a real metric and `ageGroup` a real dimension
      # while `views` by `ageGroup` is not a report that exists. The API says
      # only "not supported", which reads like a fault in the package rather
      # than a combination that was never offered, so name the parts back.
      if (!is.null(api_msg) && grepl("not supported", api_msg, ignore.case = TRUE)) {
        used <- character()
        if (!is.null(query$dimensions)) {
          used <- c(used, paste0("  dimensions: ", query$dimensions))
        }
        if (!is.null(query$metrics)) {
          used <- c(used, paste0("  metrics:    ", query$metrics))
        }
        if (!is.null(query$filters)) {
          used <- c(used, paste0("  filters:    ", query$filters))
        }

        msg <- paste(
          c(
            msg,
            "",
            "This combination is not one of the reports the API offers.",
            "Each part may be valid on its own and still not be valid together.",
            if (length(used)) c("", "You asked for:", used),
            "",
            "The reports, and the dimensions and metrics legal in each, are at",
            "https://developers.google.com/youtube/analytics/channel_reports"
          ),
          collapse = "\n"
        )
      }

      list(message = msg, class = "parameter")
    },
    "401" = list(
      message = paste(
        "Authentication failed.",
        "Run yt_oauth() to refresh your token or check your OAuth scopes."
      ),
      class = "auth"
    ),
    "403" = {
      reason <- error_details$reason
      if (!is.null(reason) && grepl("quotaExceeded|rateLimitExceeded", reason)) {
        list(
          message = paste(
            "API quota exceeded.",
            "Reduce request scope or wait before trying again.",
            "Check quota limits at https://console.cloud.google.com"
          ),
          class = "quota"
        )
      } else {
        list(
          message = "Access forbidden. Check your permissions and API settings.",
          class = "auth"
        )
      }
    },
    "404" = list(
      message = paste(
        "Resource not found. Possible causes:",
        "- YouTube Analytics API not enabled in Google Cloud project",
        "- Using a specific channel ID (channel==UCxxx) instead of 'channel==MINE'",
        "  Note: You can only access analytics for your own authenticated channel",
        "  unless you are a YouTube Partner content owner",
        "- Channel/content owner ID doesn't exist",
        "- Incorrect authentication scopes",
        sep = "\n"
      ),
      class = "api"
    ),
    "429" = list(
      message = "Too many requests. Please slow down and try again.",
      class = "quota"
    ),
    "500" = list(
      message = "YouTube API server error. Please try again later.",
      class = "api"
    ),
    "502" = list(
      message = "YouTube API bad gateway error. Please try again.",
      class = "api"
    ),
    "503" = list(
      message = "YouTube API service unavailable. Please try again later.",
      class = "api"
    ),
    "504" = list(
      message = "YouTube API gateway timeout. Please try again.",
      class = "api"
    ),
    list(
      message = paste("HTTP", status_code, "error occurred"),
      class = "api"
    )
  )

  result
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
  tryCatch(
    {
      get_report(
        ids = "channel==MINE",
        metrics = "views",
        start_date = format(Sys.Date() - 1, "%Y-%m-%d"),
        end_date = format(Sys.Date() - 1, "%Y-%m-%d"),
        max_results = 1
      )
      tubern_inform("API access is working normally.")
    },
    tubern_quota_error = function(e) {
      tubern_inform(c(
        "Quota exceeded. Consider:",
        "- Reducing the date range of your requests",
        "- Using fewer metrics or dimensions",
        "- Implementing caching for repeated requests",
        "- Checking your Google Cloud Console quota limits"
      ))
    },
    tubern_auth_error = function(e) {
      tubern_inform(c(
        "Authentication issue. Try:",
        "- Running yt_oauth() again",
        "- Checking your OAuth scopes",
        "- Verifying your Google Cloud project settings"
      ))
    },
    error = function(e) {
      tubern_inform(paste("API check failed:", conditionMessage(e)))
    }
  )
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

  cat("1. Authentication Status:\n")
  token <- getOption("google_token")
  if (is.null(token)) {
    cat("   X No authentication token found\n")
    cat("   -> Run yt_oauth() to authenticate\n\n")
  } else {
    cat("   OK Authentication token present\n")

    tryCatch(
      {
        yt_check_token()
        cat("   OK Token validation passed\n")
      },
      error = function(e) {
        cat("   X Token validation failed\n")
        cat("   -> Run yt_oauth() to refresh your token\n")
      }
    )
    cat("\n")
  }

  cat("2. Network Connectivity:\n")
  tryCatch(
    {
      test_req <- req_perform(
        req_error(request("https://www.googleapis.com"), is_error = function(resp) FALSE)
      )
      if (resp_status(test_req) == 200) {
        cat("   OK Network connection to Google APIs working\n")
      } else {
        cat("   X Network connection issues detected\n")
      }
    },
    error = function(e) {
      cat("   X Network connection failed:", conditionMessage(e), "\n")
      cat("   -> Check your internet connection and proxy settings\n")
    }
  )
  cat("\n")

  cat("3. YouTube Analytics API Access:\n")
  if (!is.null(token)) {
    tryCatch(
      {
        check_api_quota()
      },
      error = function(e) {
        cat("   X API access test failed\n")
        cat("   -> Error:", conditionMessage(e), "\n")
      }
    )
  } else {
    cat("   - Skipped (no authentication token)\n")
  }
  cat("\n")

  cat("4. Package Information:\n")
  cat("   tubern version:", as.character(packageVersion("tubern")), "\n")
  cat("   R version:", R.version.string, "\n")

  cat("\n=== End Diagnostic Report ===\n")
}
