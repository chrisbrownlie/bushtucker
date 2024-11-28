#' IACGMOOH celebrity challenges data
#'
#' Data on each of the celebrity challenges (Celebrity Chest, Dingo Dollar,
#' Castle Coin or Deals on Wheels) in the first 24 seasons of the
#' UK TV show "I'm A Celebrity, Get Me Out Of Here"
#'
#' @format ## `challenges`
#' A data frame with 134 rows and 7 columns:
#' \describe{
#'   \item{season}{(\emph{numeric}) Season of the show}
#'   \item{episode}{(\emph{numeric}) Episode in which the challenge occurred}
#'   \item{date}{(\emph{Date}) Date the challenge took place (where available)}
#'   \item{contestant}{(\emph{character}) First name(s) of the contestant(s) that took part in the challenge.
#'   Where there are multiple contestants, they are separated by a semi-colon.}
#'   \item{prizes_available}{(\emph{character}) The prize(s) which were on offer for completion of the
#'   challenge. For some challenges the competing contestants were given a choice between one or more
#'   prize options - in these cases the options are separated by a semi-colon.}
#'   \item{prize}{(\emph{character}) The prize(s) which was on offer, either because the contestants
#'   chose it, or because it was the only prize on offer.}
#'   \item{question}{(\emph{character}) Outcome of the question that gets asked to the non-participating
#'   celebrities. One of: 'correct' if the non-participants answered correctly and won the prize;
#'   'incorrect' if the non-participants answered incorrectly and forfeited the prize; or 'not_asked'
#'   if no question was asked to non-participants (the outcome of some challenges is decided by other
#'   means).}
#' }
#' @inherit contestants source
"challenges"
