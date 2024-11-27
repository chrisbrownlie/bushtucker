## code to prepare `contestants` dataset goes here

library(rvest)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)

season_numbers <- seasons$season

contestants <- tibble::tibble()
results <- tibble::tibble()
ratings <- tibble::tibble()
dd_challenges <- tibble::tibble()

for (n in season_numbers) {
  cli::cli_alert_info("Starting for season {n}")
  # Read the wiki page HTML
  wiki_page <- str_c(
    "https://en.wikipedia.org/wiki/I%27m_a_Celebrity...Get_Me_Out_of_Here!_(British_TV_series)_series_",
    n
  ) |>
    read_html()

  cli::cli_alert("Wiki page read in")

  # Get all tables
  tables_raw <- wiki_page |>
    html_elements("table.wikitable")

  # Adjustments
  if (n %in% c(7, 8, 9)) {
    tables_raw <- tables_raw[-5]
  }

  # Seasons < 11 (apart from those above) have 5 key tables, seasons >= 11 have 10
  if (!length(tables_raw) %in% c(5, 8, 10)) {
    cli::cli_abort("Season {n} wiki page has {length(tables_raw)} tables on it")
  }

  table_names <- c("contestants", "daily_results", "trials", "trial_performance", "ratings")
  if (length(tables_raw) == 8) {
    table_names <- c("contestants", "daily_results", "trials", "trial_performance",
                     "dingo_dollar_challenges",
                     "other_challenges", "episodes",
                     "ratings")
  }
  if (length(tables_raw) == 10) {
    table_names <- c("contestants", "daily_results", "trials", "trial_performance",
                     "dingo_dollar_challenges",
                     "week1_eps", "week2_eps", "week3_eps", "after_the_jungle",
                     "ratings")
  }
  tables_raw <- tables_raw |>
    rlang::set_names(table_names)

  tables <- tables_raw |>
    html_table() |>
    rlang::set_names(table_names)


  cli::cli_alert("Tables extracted")
  cli::cli_alert("Beginning contestants table")

  # Tidy up contestants table
  contestants_overview <- tables[["contestants"]] |>
    rename(
      contestant = Celebrity,
      any_of(
        c(famous_for = "Famous for",
          famous_for = "Known for")
      ),
      status = Status
    ) |>
    mutate(
      season = n,
      position_desc = str_extract(status,
                                  "^.*?(?=( )?on \\d)"),
      position = n() - sum(position_desc == "Withdrew") + 1 - as.numeric(str_extract(status, "(?<=Eliminated )\\d+")),
      position = case_when(
        position_desc == "Winner" ~ 1,
        position_desc == "Runner-up" ~ 2,
        position_desc == "Third place" ~ 3,
        .default = position
      ),
      date_eliminated = str_extract(
        status,
        "(?<=on )[[:alnum:] ]+"
      ) |>
        lubridate::dmy(),
      first_name = str_extract(contestant, "^[\\w-]+"),
      last_name = str_extract(contestant, "[\\w-]+$"),
      nickname = str_extract(contestant, "(?<=\").*?(?=\")"),
      id_name = case_when(
        first_name == "Lord" ~ contestant,
        .default = coalesce(nickname, first_name)
      )
    ) |>
    select(
      season,
      contestant,
      first_name,
      id_name,
      last_name,
      nickname,
      famous_for,
      position,
      position_desc,
      date_eliminated
    )

  # Get n trials
  cli::cli_alert("Beginning daily table")
  n_trials_tbl <- tables[["daily_results"]]

  trials_col <- which(str_detect(names(n_trials_tbl), "[tT]rial"))

  n_trials <- n_trials_tbl |>
    select(contestant = 1, trials = all_of(trials_col)) |>
    semi_join(contestants_overview, by = c("contestant" = "id_name")) |>
    mutate(trials = as.numeric(trials))

  # Tidy up trials - use raw table as stars col is weird
  cli::cli_alert("Beginning trials table")
  trials_raw <- tables_raw[["trials"]]

  # Get rows, only keep actual rows (not headers)
  rows <- trials_raw |>
    html_elements("tr") |>
    discard(\(r) {
      all(html_name(html_children(r)) != "td")
    })

  stars_clean <- rows |>
    purrr::map(
      \(row) {
        stars <- row |>
          html_element("td > span") |>
          html_attr("title") |>
          discard(is.na)
        if (!length(stars)) stars <- NA_character_
        stars
      }
    )

  known_year <- lubridate::year(seasons$start_date[seasons$season == n])

  trials_tbl <- trials_raw |>
    html_table()

  if (sum(names(trials_tbl) == "Name of trial") == 2) {
    cols <- which(names(trials_tbl) == "Name of trial")
    trial_names <- trials_tbl[,3:4] |>
      pmap_chr(
        \(...) {
          nm1 <- list(...)[[1]]
          nm2 <- list(...)[[2]]
          if (nm1 == nm2) return(nm1)
          str_c(nm1, ": ", nm2)
        }
      )
    trials_tbl[, 3] <- trial_names
    trials_tbl <- trials_tbl[, -4]
  }

  trials_tbl <- trials_tbl |>
    rename(Date = 2) |>
    mutate(stars = stars_clean,
           stars_available = str_extract(stars, "(?<=/)\\d+"),
           stars_won= str_extract(stars, "\\d+(?=/)"),

           Date = case_when(
             str_detect(Date, "^\\d+ \\w+$") ~ str_c(Date, known_year),
             .default = Date
           ),

           date = lubridate::dmy(Date),
           across(
             where(is.character),
             \(x) str_remove(x, pattern = "\\[.*?\\]")
           )) |>
    select(
      number = 1,
      date,
      name = 3,
      contestant = 4,
      stars_available,
      stars_won
    ) |>
    mutate(
      contestant = str_replace_all(contestant,
                                   pattern = "([[:lower:]])([[:upper:]])",
                                   replacement = "\\1; \\2"),
      contestant = str_replace_all(contestant,
                                   pattern = "\\s{2,}",
                                   replacement = "; ")
    )

  # Overall trial performance
  cli::cli_alert("Beginning trial perforamnce table")
  trial_perf_raw <- tables_raw[["trial_performance"]]

  # Get rows, only keep actual rows (not headers)
  rows <- trial_perf_raw |>
    html_elements("tr") |>
    discard(\(r) {
      first(html_name(html_children(r)))!="td"
    })

  stars_clean <- rows |>
    purrr::map(
      \(row) {
        stars <- row |>
          html_element("td > span") |>
          html_attr("title") |>
          discard(is.na)
        if (!length(stars)) stars <- NA_character_
        stars
      }
    )


  trial_perf_tbl <- trial_perf_raw |>
    html_table() |>
    mutate(stars = stars_clean,
           stars_available = as.numeric(str_extract(stars, "(?<=/)\\d+")),
           stars_won= as.numeric(str_extract(stars, "\\d+(?=/)")),
           across(
             where(is.character),
             \(x) str_remove(x, pattern = "\\[.*?\\]")
           ),
           trial_performance = stars_won/stars_available) |>
    select(contestant = 1,
           stars_available,
           stars_won,
           trial_performance)


  # Clean up ratings
  cli::cli_alert("Beginning ratings table")
  season_ratings <- tables[["ratings"]] |>
    rename(
      episode = 1,
      date = 2,
      rating_millions = 3,
      weekly_uk_tv_rank = 4
    ) |>
    filter(str_detect(episode, "\\d")) |>
    mutate(
      full_date = case_when(
        str_detect(date, "\\d+ \\w+$") ~ str_c(date, known_year, sep = " "),
        .default = date
      ),
      full_date = lubridate::dmy(full_date)
    )  |>
    mutate(
      across(
        c(episode, rating_millions, weekly_uk_tv_rank),
        as.numeric
      ),
      season = n
    ) |>
    select(
      season,
      episode,
      date = full_date,
      rating_millions,
      weekly_uk_tv_rank
    )

  # Tidy up dingo dollar challenge tables
  if ("dingo_dollar_challenges" %in% names(tables)) {
    # TODO: add handling for dingo dollar challenges
    # TODO: append season DD challenge table to overall table
  }

  # Get finalised datasets and append
  cli::cli_alert("Appending season tables")
  season_contestants <- contestants_overview |>
    left_join(trial_perf_tbl, by = "contestant") |>
    left_join(n_trials, by = c("id_name" = "contestant")
    ) |>
    select(
      season,
      first_name,
      last_name,
      famous_for,
      position,
      position_desc,
      date_eliminated,
      trials_attempted = trials,
      stars_available,
      stars_won,
      trial_performance
    )
  contestants <- bind_rows(contestants,
                           season_contestants)

  ratings <- bind_rows(ratings,
                       season_ratings)

  cli::cli_alert_success("Completed for season {n}")
}

usethis::use_data(contestants, overwrite = TRUE)
