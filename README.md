
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bushtucker

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/bushtucker)](https://CRAN.R-project.org/package=bushtucker)
[![pkgdown](https://github.com/chrisbrownlie/bushtucker/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/chrisbrownlie/bushtucker/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

{bushtucker} is a data package which provides datasets about the 24
seasons of the UK TV show “I’m A Celebrity, Get Me Out Of Here”,
spanning from 2002 to 2024 and broadcast on ITV.

The show follows a group of UK celebrities camping in an Australian
rainforest (or Welsh castle for seasons 20-21, due to COVID) for several
weeks, completing physical and mental endurance challenges to earn meals
and treats. These challenges are called ‘Bushtucker Trials’, hence the
name of the package.

More information on the format can be found on [the show’s Wikipedia
pages](https://en.wikipedia.org/wiki/I'm_a_Celebrity...Get_Me_Out_of_Here!_(British_TV_series)),
which is also where the data in this package comes from.

## Installation

You can install the development version of bushtucker like so:

``` r
# install.packages("pak")
pak::pkg_install("chrisbrownlie/bushtucker")

# OR

# install.packages("remotes")
remotes::install_github("chrisbrownlie/bushtucker")
```

## Datasets

There are 6 key datasets included in this package:

- `seasons`: one row for each of the 24 seasons, includes info on
  location, presenters and dates
- `contestants`: one row per contestant per season, includes info on
  occupation, final position and trial performance
- `results`: one row per contestant per vote, includes the season and
  date, whether the contestant was eliminated during that vote, as well
  as the share of the vote they received (where available)
- `trials`: one row per trial, includes the season, name, episode, which
  contestant(s) took part and how they performed
- `challenges`: one row per challenge (Celebrity Chest, Dingo Dollar,
  Castle Coin or Deals on Wheels), includes the season, episode,
  contestant(s) that took part, whether the campmates got the question
  correct and the prize they received
- `ratings`: one row per episode, includes the total viewership and
  weekly ranking of the episode

Below you can see a snapshot of each dataset.

``` r
library(bushtucker)
library(pillar) # for glimpse()

seasons |>
  tail() |>
  glimpse()
#> Rows: 6
#> Columns: 11
#> $ season               <dbl> 19, 20, 21, 22, 23, 24
#> $ contestants          <dbl> 12, 12, 12, 12, 12, 12
#> $ location             <chr> "New South Wales, Australia", "Abergele, Wales", …
#> $ presenters           <chr> "Ant & Dec", "Ant & Dec", "Ant & Dec", "Ant & Dec…
#> $ episodes             <dbl> 22, 20, 19, 22, 22, 22
#> $ start_date           <date> 2019-11-17, 2020-11-15, 2021-11-21, 2022-11-06, 2…
#> $ end_date             <date> 2019-12-08, 2020-12-04, 2021-12-12, 2022-11-27, 2…
#> $ winner               <chr> "Jacqueline Jossa", "Giovanna Fletcher", "Danny M…
#> $ runner_up            <chr> "Andy Whyment", "Jordan North", "Simon Gregson",…
#> $ third_place          <chr> "Roman Kemp", "Vernon Kay", "Frankie Bridge", "M…
#> $ avg_viewers_millions <dbl> 10.59, 11.05, 7.61, 10.94, 8.36, 8.63

contestants |>
  tail() |>
  glimpse()
#> Rows: 6
#> Columns: 12
#> $ season            <dbl> 24, 24, 24, 24, 24, 24
#> $ first_name        <chr> "Maura", "Barry", "Melvin", "Tulisa", "Dean", "Jane"
#> $ nickname          <chr> NA, NA, NA, NA, NA, NA
#> $ last_name         <chr> "Higgins", "McGuigan", "Odoom", "Tulisa", "McCulloug…
#> $ famous_for        <chr> "Television personality & model", "Former profession…
#> $ position          <dbl> 7, 8, 9, 10, 11, 12
#> $ position_desc     <chr> "Eliminated 6th", "Eliminated 5th", "Eliminated 4th"…
#> $ date_eliminated   <date> 2024-12-05, 2024-12-05, 2024-12-03, 2024-12-02, 2024…
#> $ trials_attempted  <dbl> 4, 4, 1, 2, 7, 1
#> $ stars_available   <dbl> 25, 0, 12, 23, 0, 12
#> $ stars_won         <dbl> 18, 0, 12, 16, 0, 6
#> $ trial_performance <dbl> 0.7200000, NA, 1.0000000, 0.6956522, NA, 0.5000000

results |>
  tail() |>
  glimpse()
#> Rows: 6
#> Columns: 7
#> $ season     <dbl> 24, 24, 24, 24, 24, 24
#> $ day        <dbl> 22, 22, 22, 22, 22, 22
#> $ vote       <dbl> 9, 9, 9, 9, 9, 9
#> $ contestant <chr> "Maura", "Barry", "Melvin", "Tulisa", "Dean", "Jane"
#> $ result     <chr> NA, NA, NA, NA, NA, NA
#> $ position   <dbl> NA, NA, NA, NA, NA, NA
#> $ vote_share <dbl> NA, NA, NA, NA, NA, NA

trials |>
  tail() |>
  glimpse()
#> Rows: 6
#> Columns: 9
#> $ season          <dbl> 24, 24, 24, 24, 24, 24
#> $ number          <dbl> 20, 21, 22, 23, 24, 25
#> $ date            <date> 2024-12-05, 2024-12-05, 2024-12-06, 2024-12-07, 2024-1…
#> $ name            <chr> "Arcade of Agony: Battle Blocks", "Arcade of Agony: Fa…
#> $ live            <lgl> FALSE, FALSE, FALSE, FALSE, FALSE, FALSE
#> $ chosen_by       <chr> "showrunners", "showrunners", "contestants", "showrun…
#> $ contestant      <chr> "Coleen; Danny; Maura; Oti", "Alan; Barry; GK Barry; R…
#> $ stars_available <dbl> 0, 8, 6, 4, 6, 6
#> $ stars_won       <dbl> 0, 7, 6, 4, 6, 6

challenges |>
  tail() |>
  glimpse()
#> Rows: 6
#> Columns: 7
#> $ season           <dbl> 23, 23, 24, 24, 24, 24
#> $ episode          <dbl> 18, 21, 2, 8, 9, 16
#> $ date             <date> 2023-12-06, 2023-12-09, 2024-11-18, 2024-11-24, 2024-…
#> $ contestant       <chr> "Josie; Nigel", "Josie; Nigel; Sam; Tony", "Melvin; O…
#> $ prizes_available <chr> "Chocolate biscuits", "Ice cream", "Marshmallows", "…
#> $ prize            <chr> "Chocolate biscuits", "Ice cream", "Marshmallows", "B…
#> $ question         <chr> "correct", "not_asked", "correct", "correct", "correc…

ratings |>
  tail() |>
  glimpse()
#> Rows: 6
#> Columns: 6
#> $ season              <dbl> 24, 24, 24, 24, 24, 24
#> $ episode             <dbl> 17, 18, 19, 20, 21, 22
#> $ date                <date> 2024-12-03, 2024-12-04, 2024-12-05, 2024-12-06, 20…
#> $ viewership_millions <dbl> 8.37, 8.07, 7.92, 7.76, 8.49, 8.85
#> $ weekly_uk_tv_rank   <dbl> NA, NA, NA, NA, NA, NA
#> $ weekly_itv_rank     <dbl> 4, 6, 8, 9, 3, 1
```
