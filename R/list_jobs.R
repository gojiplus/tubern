#' List Jobs
#' 
#' Lists reporting jobs that have been scheduled for a channel or content owner. 
#'  
#' @param \dots Additional arguments passed to \code{\link{tuber_GET}}.
#' 
#' @return data.frame with 5 columns: channelId, title, assignable, etag, id
#' @export
#' @references \url{https://developers.google.com/youtube/reporting/v1/reference/rest/v1/jobs/list}
#' @examples
#' \dontrun{
#' list_jobs()
#' }

list_jobs <- function (...) 
{

	res <- tubern_GET("jobs", ...)

	res
}

