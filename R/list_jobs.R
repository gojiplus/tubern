#' List Jobs
#' 
#' Lists reporting jobs that have been scheduled for a channel or content owner. 
#'  
#' @param page_size The requested page size. If no value is specified, the API server chooses an appropriate default, optional
#' @param page_token specific page in the result set that should be returned, optional
#' @param \dots Additional arguments passed to \code{\link{tuber_GET}}.
#' 
#' @return data.frame with 5 columns: channelId, title, assignable, etag, id
#' @export
#' @references \url{https://developers.google.com/youtube/reporting/v1/reference/rest/v1/jobs/list}
#' @examples
#' \dontrun{
#' list_jobs()
#' }

list_jobs <- function (page_size = NULL, page_token=NULL, ...) 
{

	querylist <- list(pageSize = page_size, pageToken = page_token)

	res <- tubern_GET("jobs", querylist, ...)

	res
}

