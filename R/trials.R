#' IACGMOOH bushtucker trials data
#'
#' Data on each of the viewer votes in the first 24 seasons of the
#' UK TV show "I'm A Celebrity, Get Me Out Of Here"
#'
#' @format ## `trials`
#' A data frame with 506 rows and 8 columns:
#' \describe{
#'   \item{season}{(\emph{numeric}) Season of the show}
#'   \item{number}{(\emph{numeric}) Number of the trial (i.e. 1 = the first trial of the season,
#'   2 = second trial of the season, etc.)}
#'   \item{date}{(\emph{Date}) Date of the trial}
#'   \item{name}{(\emph{character}) Name of the trial}
#'   \item{live}{(\emph{logical}) TRUE if the trial was broadcast live, FALSE otherwise}
#'   \item{contestant}{(\emph{character}) First name(s) of the contestant(s) that took part in the trial.
#'   Where there are multiple contestants, they are separated by a semi-colon.}
#'   \item{stars_available}{(\emph{numeric}) Maximum number of stars available to win in this trial}
#'   \item{stars_won}{(\emph{numeric}) Number of stars that the contestant(s) won in the trial}
#' }
#' @inherit contestants source
"trials"
