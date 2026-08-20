#' Deprecated function names
#'
#' These are the names these functions had before 0.6.0. They still work and
#' still return what they always did, but each warns once per session and
#' will be removed in a future release.
#'
#' The renames were:
#'
#' \describe{
#'   \item{\code{add_groups()}}{\code{\link{add_group}()}, since it creates one
#'     group and its siblings are \code{delete_group()} and
#'     \code{update_group()}}
#'   \item{\code{yt_to_dataframe()}}{\code{\link{yt_as_data_frame}()}, since
#'     \code{as_} is the convention for coercion}
#'   \item{\code{yt_to_tibble()}}{\code{\link{yt_as_tibble}()}, likewise}
#'   \item{\code{diagnose_tubern()}}{\code{\link{yt_diagnose}()}, since the
#'     package name inside a function of that package says nothing}
#' }
#'
#' @param ... Passed to the replacement.
#' @return Whatever the replacement returns.
#' @name tubern-deprecated
NULL

# One warning per session per name. Repeating it on every call in a loop
# teaches people to filter warnings, which is the opposite of the point.
.deprecate <- function(old, new) {
  warn(
    paste0("`", old, "()` is deprecated. Use `", new, "()` instead."),
    class = "tubern_deprecated_warning",
    .frequency = "once",
    .frequency_id = paste0("tubern_deprecated_", old)
  )
}

#' @rdname tubern-deprecated
#' @export
add_groups <- function(...) {
  .deprecate("add_groups", "add_group")
  add_group(...)
}

#' @rdname tubern-deprecated
#' @export
yt_to_dataframe <- function(...) {
  .deprecate("yt_to_dataframe", "yt_as_data_frame")
  yt_as_data_frame(...)
}

#' @rdname tubern-deprecated
#' @export
yt_to_tibble <- function(...) {
  .deprecate("yt_to_tibble", "yt_as_tibble")
  yt_as_tibble(...)
}

#' @rdname tubern-deprecated
#' @export
diagnose_tubern <- function(...) {
  .deprecate("diagnose_tubern", "yt_diagnose")
  yt_diagnose(...)
}
