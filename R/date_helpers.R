#' Date Helper Functions for tubern
#'
#' Convenience functions for handling dates in YouTube Analytics API requests
#' @name date_helpers
NULL

#' Parse relative date strings to actual dates
#' 
#' @param date_string Character string like "last_30_days", "this_month", "2024-01-01", etc.
#' @return Date object
#' @keywords internal
#' @noRd
.parse_date_string <- function(date_string) {
  if (is.null(date_string)) return(NULL)
  
  # Handle absolute dates first
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", date_string)) {
    return(as.Date(date_string))
  }
  
  # Handle relative dates
  today <- Sys.Date()
  
  date_obj <- switch(tolower(date_string),
    # Days
    "yesterday" = today - 1,
    "today" = today,
    "last_7_days" = today - 7,
    "last_14_days" = today - 14,
    "last_30_days" = today - 30,
    "last_60_days" = today - 60,
    "last_90_days" = today - 90,
    
    # Weeks
    "this_week" = today - as.numeric(format(today, "%w")),
    "last_week" = today - as.numeric(format(today, "%w")) - 7,
    
    # Months
    "this_month" = as.Date(paste0(format(today, "%Y-%m"), "-01")),
    "last_month" = {
      first_this_month <- as.Date(paste0(format(today, "%Y-%m"), "-01"))
      seq(first_this_month, length = 2, by = "-1 month")[2]
    },
    "this_year" = as.Date(paste0(format(today, "%Y"), "-01-01")),
    "last_year" = as.Date(paste0(as.numeric(format(today, "%Y")) - 1, "-01-01")),
    
    # Quarters
    "this_quarter" = {
      quarter <- ceiling(as.numeric(format(today, "%m")) / 3)
      quarter_start_month <- (quarter - 1) * 3 + 1
      as.Date(paste0(format(today, "%Y"), "-", 
                     sprintf("%02d", quarter_start_month), "-01"))
    },
    "last_quarter" = {
      quarter <- ceiling(as.numeric(format(today, "%m")) / 3)
      if (quarter == 1) {
        # Last quarter of previous year
        as.Date(paste0(as.numeric(format(today, "%Y")) - 1, "-10-01"))
      } else {
        quarter_start_month <- (quarter - 2) * 3 + 1
        as.Date(paste0(format(today, "%Y"), "-", 
                       sprintf("%02d", quarter_start_month), "-01"))
      }
    },
    
    tubern_abort(
      paste0("Unrecognized date string: '", date_string, "'.",
             " Use YYYY-MM-DD format or relative dates like 'last_30_days', 'this_month', etc."),
      class = "parameter"
    )
  )
  
  return(date_obj)
}

#' Get end date for relative date ranges
#' 
#' @param start_date_string Character string for start date
#' @return Date object for appropriate end date
#' @keywords internal
#' @noRd
.get_end_date_for_range <- function(start_date_string) {
  if (is.null(start_date_string)) return(NULL)
  
  # Handle absolute dates - return same date
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", start_date_string)) {
    return(as.Date(start_date_string))
  }
  
  today <- Sys.Date()
  
  end_date <- switch(tolower(start_date_string),
    # Days
    "yesterday" = today - 1,
    "today" = today,
    "last_7_days" = today - 1,  # Last 7 days up to yesterday
    "last_14_days" = today - 1,
    "last_30_days" = today - 1,
    "last_60_days" = today - 1,
    "last_90_days" = today - 1,
    
    # Weeks
    "this_week" = today,
    "last_week" = today - as.numeric(format(today, "%w")) - 1,
    
    # Months
    "this_month" = today,
    "last_month" = {
      first_this_month <- as.Date(paste0(format(today, "%Y-%m"), "-01"))
      first_this_month - 1
    },
    "this_year" = today,
    "last_year" = as.Date(paste0(as.numeric(format(today, "%Y")) - 1, "-12-31")),
    
    # Quarters
    "this_quarter" = today,
    "last_quarter" = {
      quarter <- ceiling(as.numeric(format(today, "%m")) / 3)
      if (quarter == 1) {
        # End of last quarter of previous year
        as.Date(paste0(as.numeric(format(today, "%Y")) - 1, "-12-31"))
      } else {
        quarter_end_month <- (quarter - 2) * 3 + 3
        last_day <- switch(as.character(quarter_end_month),
          "3" = "31", "6" = "30", "9" = "30", "12" = "31"
        )
        as.Date(paste0(format(today, "%Y"), "-", 
                       sprintf("%02d", quarter_end_month), "-", last_day))
      }
    },
    
    # Default: return today
    today
  )
  
  return(end_date)
}

#' Resolve date range with support for relative dates
#' 
#' @param start_date Start date (can be relative like "last_30_days" or absolute like "2024-01-01") 
#' @param end_date End date (can be relative or absolute). If NULL and start_date is relative, will be calculated automatically
#' @return List with resolved start_date and end_date as YYYY-MM-DD strings
#' @export
#' @examples
#' # Relative date ranges
#' resolve_date_range("last_30_days")
#' resolve_date_range("this_month")
#' resolve_date_range("last_quarter")
#' 
#' # Absolute date ranges  
#' resolve_date_range("2024-01-01", "2024-01-31")
resolve_date_range <- function(start_date, end_date = NULL) {
  # Parse start date
  start_parsed <- .parse_date_string(start_date)
  
  # If end_date is not provided and start_date is relative, calculate end_date
  if (is.null(end_date) && !grepl("^\\d{4}-\\d{2}-\\d{2}$", start_date)) {
    end_parsed <- .get_end_date_for_range(start_date)
  } else if (!is.null(end_date)) {
    # A relative end_date names a window; the end of the range is its last day,
    # not its first, so .parse_date_string() (a start-of-range mapper) is only
    # correct for absolute YYYY-MM-DD input.
    end_parsed <- if (grepl("^\\d{4}-\\d{2}-\\d{2}$", end_date)) {
      .parse_date_string(end_date)
    } else {
      .get_end_date_for_range(end_date)
    }
  } else {
    end_parsed <- start_parsed  # Same as start if absolute and no end specified
  }
  
  if (start_parsed > end_parsed) {
    tubern_abort(
      paste0("Resolved start_date (", format(start_parsed, "%Y-%m-%d"),
             ") is after end_date (", format(end_parsed, "%Y-%m-%d"), ")"),
      class = "parameter"
    )
  }
  
  if (end_parsed > Sys.Date()) {
    tubern_warn(
      "End date is in the future. YouTube Analytics data is typically delayed by 1-2 days.",
      class = "parameter"
    )
  }
  
  # Return as formatted strings
  list(
    start_date = format(start_parsed, "%Y-%m-%d"),
    end_date = format(end_parsed, "%Y-%m-%d")
  )
}

#' Get common date ranges
#' 
#' @return Named list of common date ranges
#' @export  
#' @examples
#' get_common_date_ranges()
get_common_date_ranges <- function() {
  list(
    "Last 7 days" = "last_7_days",
    "Last 30 days" = "last_30_days", 
    "Last 90 days" = "last_90_days",
    "This month" = "this_month",
    "Last month" = "last_month",
    "This quarter" = "this_quarter",
    "Last quarter" = "last_quarter", 
    "This year" = "this_year",
    "Last year" = "last_year",
    "Yesterday" = "yesterday",
    "This week" = "this_week",
    "Last week" = "last_week"
  )
}