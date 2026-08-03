#' Data Transformation Utilities
#'
#' Functions to transform YouTube Analytics API responses into common R data formats
#' @name data_transformation
NULL

# Declare .data as global variable to avoid R CMD check NOTE
utils::globalVariables(".data")

#' Convert API response to data frame
#'
#' Transforms YouTube Analytics API response into a clean data.frame with proper column names and types.
#'
#' @param api_response List returned from get_report() or other API functions
#' @param clean_names Logical. Clean column names by removing special characters (default: TRUE)
#' @param parse_dates Logical. Parse date columns to Date objects (default: TRUE)
#' @return data.frame with transformed data, or NULL if no data available
#' @export
#' @examples
#' \dontrun{
#' # Get data and convert to data.frame
#' report <- get_channel_overview("last_30_days")
#' df <- yt_to_dataframe(report)
#'
#' # Keep original column names
#' df <- yt_to_dataframe(report, clean_names = FALSE)
#' }
yt_to_dataframe <- function(api_response, clean_names = TRUE, parse_dates = TRUE) {

  if (is.null(api_response) || !is.list(api_response)) {
    tubern_warn("Invalid API response provided")
    return(NULL)
  }

  if (is.null(api_response$rows) || length(api_response$rows) == 0) {
    tubern_inform("No data available in the API response")
    return(data.frame())
  }

  if (is.null(api_response$columnHeaders)) {
    tubern_warn("No column headers found in API response")
    return(NULL)
  }

  headers <- vapply(api_response$columnHeaders, function(x) x$name, character(1))

  # Convert rows to matrix then data.frame
  data_matrix <- do.call(rbind, api_response$rows)
  df <- as.data.frame(data_matrix)
  names(df) <- headers

  # Clean column names if requested
  if (clean_names) {
    names(df) <- .clean_column_names(names(df))
  }

  # Parse data types
  df <- .parse_column_types(df, api_response$columnHeaders, parse_dates)

  # Carry query metadata only when the response actually has it. reports.query
  # returns just kind/columnHeaders/rows -- there is no $query member -- so this
  # unconditionally attached a list of four NULLs to every frame it ever
  # produced, which reads like metadata and holds nothing.
  meta <- list(
    start_date = api_response$query$startDate,
    end_date = api_response$query$endDate,
    metrics = api_response$query$metrics,
    dimensions = api_response$query$dimensions
  )
  if (any(vapply(meta, Negate(is.null), logical(1)))) {
    attr(df, "query") <- meta
  }

  return(df)
}

#' Clean column names for R data.frame
#' @param names Character vector of column names
#' @return Character vector of cleaned names
#' @keywords internal
#' @noRd
.clean_column_names <- function(names) {
  # Convert camelCase to snake_case
  names <- gsub("([a-z])([A-Z])", "\\1_\\2", names)
  names <- tolower(names)

  # Replace remaining special characters with underscores
  names <- gsub("[^a-z0-9_]", "_", names)

  # Remove duplicate underscores
  names <- gsub("_+", "_", names)

  # Remove leading/trailing underscores
  names <- gsub("^_|_$", "", names)

  return(names)
}

#' Parse column types based on API metadata
#' @param df Data.frame to parse
#' @param column_headers Column headers from API response
#' @param parse_dates Whether to parse date columns
#' @return Data.frame with parsed column types
#' @keywords internal
#' @noRd
.parse_column_types <- function(df, column_headers, parse_dates) {

  for (i in seq_along(column_headers)) {
    col_name <- names(df)[i]
    col_type <- column_headers[[i]]$dataType

    if (col_type == "INTEGER") {
      df[[col_name]] <- as.numeric(df[[col_name]])
    } else if (col_type == "FLOAT") {
      df[[col_name]] <- as.numeric(df[[col_name]])
    } else if (col_type == "STRING") {
      df[[col_name]] <- as.character(df[[col_name]])
    }

    # Parse date columns if requested
    if (parse_dates && (col_name %in% c("day", "month") || grepl("date", col_name, ignore.case = TRUE))) {
      date_parsed <- tryCatch({
        as.Date(df[[col_name]])
      }, error = function(e) NULL)

      if (!is.null(date_parsed)) {
        df[[col_name]] <- date_parsed
      }
    }
  }

  return(df)
}

#' Convert API response to tibble (if tibble is available)
#'
#' @param api_response API response from YouTube Analytics
#' @param ... Additional arguments passed to yt_to_dataframe()
#' @return tibble or data.frame if tibble not available
#' @export
#' @examples
#' \dontrun{
#' report <- get_top_videos("last_7_days")
#' tbl <- yt_to_tibble(report)
#' }
yt_to_tibble <- function(api_response, ...) {
  df <- yt_to_dataframe(api_response, ...)

  if (is.null(df)) return(NULL)

  if (requireNamespace("tibble", quietly = TRUE)) {
    return(tibble::as_tibble(df))
  } else {
    tubern_inform("Install 'tibble' package for tibble output format")
    return(df)
  }
}

#' Extract summary statistics from API response
#'
#' @param api_response API response from YouTube Analytics
#' @return Named list with summary statistics
#' @export
#' @examples
#' \dontrun{
#' report <- get_channel_overview("last_30_days")
#' summary <- yt_extract_summary(report)
#' print(summary)
#' }
yt_extract_summary <- function(api_response) {
  if (is.null(api_response) || is.null(api_response$rows)) {
    return(list(total_rows = 0))
  }

  df <- yt_to_dataframe(api_response, clean_names = FALSE, parse_dates = FALSE)
  if (is.null(df) || nrow(df) == 0) {
    return(list(total_rows = 0))
  }

  summary_list <- list(
    total_rows = nrow(df),
    columns = ncol(df),
    column_names = names(df)
  )

  # Add numeric column summaries
  numeric_cols <- vapply(df, is.numeric, logical(1))
  if (any(numeric_cols)) {
    summary_list$numeric_summary <- lapply(df[numeric_cols], function(x) {
      list(
        total = sum(x, na.rm = TRUE),
        mean = mean(x, na.rm = TRUE),
        median = median(x, na.rm = TRUE),
        min = min(x, na.rm = TRUE),
        max = max(x, na.rm = TRUE)
      )
    })
  }

  return(summary_list)
}

#' Export data to CSV
#'
#' @param api_response API response from YouTube Analytics
#' @param filename Output filename (default: auto-generated based on timestamp)
#' @param ... Additional arguments passed to yt_to_dataframe()
#' @return Path to saved file
#' @export
#' @examples
#' \dontrun{
#' report <- get_daily_performance("last_30_days")
#' file_path <- yt_export_csv(report, "daily_performance.csv")
#' }
yt_export_csv <- function(api_response, filename = NULL, ...) {
  df <- yt_to_dataframe(api_response, ...)

  if (is.null(df) || nrow(df) == 0) {
    tubern_abort("No data to export", class = "parameter")
  }

  if (is.null(filename)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    filename <- paste0("youtube_analytics_", timestamp, ".csv")
  }

  # Ensure .csv extension
  if (!grepl("\\.csv$", filename, ignore.case = TRUE)) {
    filename <- paste0(filename, ".csv")
  }

  write.csv(df, filename, row.names = FALSE)
  tubern_inform(paste("Data exported to:", filename))
  return(filename)
}

#' Create a quick visualization of the data (if ggplot2 is available)
#'
#' @param api_response API response from YouTube Analytics
#' @param x_col Column name for x-axis (auto-detected if NULL)
#' @param y_col Column name for y-axis (auto-detected if NULL)
#' @param chart_type Type of chart: "line", "bar", "point" (default: auto)
#' @return ggplot object or base R plot if ggplot2 not available
#' @export
#' @examples
#' \dontrun{
#' # Daily views over time
#' daily_report <- get_daily_performance("last_30_days")
#' yt_quick_plot(daily_report)
#'
#' # Top videos by views
#' top_videos <- get_top_videos("last_7_days")
#' yt_quick_plot(top_videos, chart_type = "bar")
#' }
yt_quick_plot <- function(api_response, x_col = NULL, y_col = NULL, chart_type = "auto") {
  df <- yt_to_dataframe(api_response)

  if (is.null(df) || nrow(df) == 0) {
    tubern_abort("No data to plot", class = "parameter")
  }

  # Auto-detect columns if not specified
  if (is.null(x_col)) {
    # Look for date columns first, then dimension columns
    date_cols <- names(df)[vapply(df, function(x) inherits(x, "Date"), logical(1))]
    if (length(date_cols) > 0) {
      x_col <- date_cols[1]
    } else {
      # Use first non-numeric column
      x_col <- names(df)[!vapply(df, is.numeric, logical(1))][1]
    }
  }

  if (is.null(y_col)) {
    # Use first numeric column
    numeric_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    if (length(numeric_cols) > 0) {
      y_col <- numeric_cols[1]
    } else {
      tubern_abort("No numeric columns found for plotting", class = "parameter")
    }
  }

  # Auto-detect chart type
  if (chart_type == "auto") {
    if (inherits(df[[x_col]], "Date")) {
      chart_type <- "line"
    } else {
      chart_type <- "bar"
    }
  }

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    .create_ggplot(df, x_col, y_col, chart_type)
  } else {
    tubern_inform("Install 'ggplot2' package for better plots. Using base R plot.")
    .create_base_plot(df, x_col, y_col, chart_type)
  }
}

#' Create ggplot visualization
#' @keywords internal
#' @noRd
.create_ggplot <- function(df, x_col, y_col, chart_type) {
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[x_col]], y = .data[[y_col]]))

  if (chart_type == "line") {
    p <- p + ggplot2::geom_line() + ggplot2::geom_point()
  } else if (chart_type == "bar") {
    p <- p + ggplot2::geom_col()
  } else if (chart_type == "point") {
    p <- p + ggplot2::geom_point()
  }

  p <- p +
    ggplot2::labs(
      title = paste("YouTube Analytics:", y_col, "by", x_col),
      x = x_col,
      y = y_col
    ) +
    ggplot2::theme_minimal()

  if (!inherits(df[[x_col]], "Date") && chart_type == "bar") {
    p <- p + ggplot2::coord_flip()
  }

  return(p)
}

#' Create base R plot
#' @keywords internal
#' @noRd
.create_base_plot <- function(df, x_col, y_col, chart_type) {
  if (chart_type == "line" && inherits(df[[x_col]], "Date")) {
    plot(df[[x_col]], df[[y_col]], type = "l",
         xlab = x_col, ylab = y_col,
         main = paste("YouTube Analytics:", y_col, "by", x_col))
    points(df[[x_col]], df[[y_col]], pch = 16)
  } else if (chart_type == "bar") {
    barplot(df[[y_col]], names.arg = df[[x_col]],
            xlab = x_col, ylab = y_col,
            main = paste("YouTube Analytics:", y_col, "by", x_col),
            las = 2)
  } else {
    plot(df[[x_col]], df[[y_col]],
         xlab = x_col, ylab = y_col,
         main = paste("YouTube Analytics:", y_col, "by", x_col))
  }
}
