% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ratings.R
\docType{data}
\name{ratings}
\alias{ratings}
\title{IACGMOOH ratings data}
\format{
\subsection{\code{ratings}}{

A data frame with 458 rows and 6 columns:
\describe{
\item{season}{(\emph{numeric}) Season of the show}
\item{episode}{(\emph{numeric}) Episode of the season}
\item{date}{(\emph{Date}) Date the episode was aired}
\item{viewership_millions}{(\emph{numeric}) The total reported viewership
for the episode in millions, including on ITV HD and ITV+1 where available}
\item{weekly_uk_tv_rank}{(\emph{numeric}) Available for seasons 1-9, this
is where the episode ranked among all shows on UK TV that week}
\item{weekly_itv_rank}{(\emph{numeric}) Available for seasons 10-24, this
is where the episode ranked among all shows on ITV that week}
}
}
}
\source{
https://www.barb.co.uk/viewing-data/weekly-top-30/
}
\usage{
ratings
}
\description{
Data on TV viewership and ratings for the first 24 seasons of the
UK TV show "I'm A Celebrity, Get Me Out Of Here". Viewership and rankings
data is linked on the season wikipedia pages but comes from BARB ratings
for each week.
}
\keyword{datasets}
