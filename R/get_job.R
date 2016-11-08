#' Get a Job
#' 
#' Retrieves information about a specific reporting job that has been scheduled for a channel or content owner.
#'  
#' @param job_id Id of the job requested
#' @param \dots Additional arguments passed to \code{\link{tuber_GET}}.
#' 
#' @return data.frame with 5 columns: channelId, title, assignable, etag, id
#' @export
#' @references \url{https://developers.google.com/youtube/reporting/v1/reference/rest/v1/jobs/get}
#' 
#' @examples
#' \dontrun{
#' get_job()
#' }

get_job <- function (job_id = NULL, ...) 
{

	query <- querylist(jobId = job_id)

	res <- tubern_GET("jobs", ...)

	res
}

