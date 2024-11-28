#' IACGMOOH voting results data
#'
#' Data on each of the viewer votes in the first 24 seasons of the
#' UK TV show "I'm A Celebrity, Get Me Out Of Here"
#'
#' @format ## `results`
#' A data frame with 2,611 rows and 7 columns:
#' \describe{
#'   \item{season}{(\emph{numeric}) Season of the show}
#'   \item{day}{(\emph{numeric}) Day of the vote (i.e. number of days after the season started)}
#'   \item{vote}{(\emph{numeric}) Number of the vote (i.e. 1 = the first vote of the season,
#'   2 = second vote of the season, etc. - useful for situations like the final where there are
#'   two votes on the same day.)}
#'   \item{contestant}{(\emph{character}) First name of a celebrity contestant competing in the vote}
#'   \item{result}{(\emph{character}) One of: 'safe' if the celebrity was NOT eliminated, 'eliminated' if they WERE
#'   eliminated, or NA if they did not take part (i.e. had been eliminated or withdrew in an earlier vote)}
#'   \item{position}{(\emph{numeric}) Where it is known, their position in this vote (i.e. 1 = received the most
#'   votes, 2 = second-most votes etc.)}
#'   \item{vote_share}{(\emph{numeric}) Where it is known, the proportion of all votes the celebrity received}
#' }
#' @inherit contestants source
"results"
