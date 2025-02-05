## code to prepare the 5 main datasets goes here

library(pak)
library(rvest)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)

season_numbers <- seasons$season

contestants <- tibble::tibble()
results <- tibble::tibble()
ratings <- tibble::tibble()
trials <- tibble::tibble()
challenges <- tibble::tibble()

for (n in season_numbers) {
  cli::cli_alert_info("Starting for season {n}")

  ### SETUP #####
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

  # Manual adjustments for consistency
  if (n %in% c(7, 8, 9)) {
    tables_raw <- tables_raw[-5]
  }
  if (n == 15) {
    tables_raw <- tables_raw[-c(4,7)]
  }
  if (n == 24) {
    tables_raw <- tables_raw[-6]
  }

  # Seasons < 11 (apart from those above) have 5 key tables, seasons >= 11 have 10
  if (!length(tables_raw) %in% c(5, 6, 8, 10)) {
    cli::cli_abort("Season {n} wiki page has {length(tables_raw)} tables on it")
  }

  table_names <- c("contestants", "daily_results", "trials", "trial_performance", "ratings")
  if (length(tables_raw) == 6) {
    table_names <- c("contestants", "daily_results", "trials", "trial_performance",
                     "dingo_dollar_challenges", "ratings")
  }
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


  ### CONTESTANTS #####
  cli::cli_alert("Beginning contestants table")

  # Tidy up contestants table
  contestants_overview <- tables[["contestants"]] |>
    rename_with(\(nm) str_remove(nm, pattern = "\\[.*?\\]")) |>
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

  ### Vote results/number of trials #####
  # Get n trials
  cli::cli_alert("Beginning daily table")
  n_trials_tbl <- tables[["daily_results"]]

  trials_col <- which(str_detect(names(n_trials_tbl), "[tT]rial"))

  match_id_name_n_trials <- function(col) {
    case_match(
      col,
      "Fash" ~ "John",
      "Biggins" ~ "Christopher",
      "Lady C" ~ "Lady",
      "Becky" ~ "Rebekah",
      "Kez" ~ "Kezia",
      "Naughty Boy" ~ "Naughty",
      "Jamie Lynn" ~ "Jamie",
      "GK Barry" ~ "GK",
      "Rev. Richard" ~ "Rev",
      .default = col
    )
  }

  n_trials <- n_trials_tbl |>
    select(contestant = 1, trials = all_of(trials_col)) |>
    mutate(contestant = match_id_name_n_trials(contestant)) |>
    semi_join(contestants_overview, by = c("contestant" = "id_name")) |>
    mutate(trials = as.numeric(trials))

  # Get results from daily results table
  duplicate_cols <- names(n_trials_tbl) |>
    table()
  new_names <- names(n_trials_tbl) |>
    purrr::imap(
      \(nm, i) {
        if (nm == "") return(str_c("col_", i))
        if (duplicate_cols[[nm]] == 1) return(nm)
        pos <- sum(names(n_trials_tbl)[1:i] == nm, na.rm = TRUE)
        str_c(nm, "_", pos)
      }
    ) |>
    str_remove(pattern = "\\[.*?\\]") |>
    str_replace("\\s+", "_") |>
    str_to_lower()

  vote_results <- n_trials_tbl |>
    set_names(new_names) |>
    select(
      contestant = 1,
      starts_with("day")
    ) |>
    filter(!contestant %in% c("", "Celebrity"),
           !str_detect(contestant, "Eliminated|Notes|Bottom two")) |>
    pivot_longer(
      cols = -contestant,
      names_to = "vote",
      values_to = "result"
    ) |>
    mutate(
      season = n,
      vote_mday = str_remove(vote, "day_"),
      vote_day = as.numeric(str_extract(vote_mday, "^\\d+")),
      vote_day_part = as.numeric(str_extract(vote_mday, "\\d+$")),
      vote_day_part = if_else(vote_day == vote_day_part, 1, vote_day_part),
      vote_share = str_extract(result, "[\\d\\.]+%"),
      vote_share = as.numeric(str_extract(vote_share, "[\\d\\.]+"))/10,
      result_outcome = case_when(
        str_starts(result, "1st|2nd") ~ "safe",
        str_starts(result, "Safe") ~ "safe",
        str_starts(result, "Winner") ~ "safe",
        str_starts(result, "Bottom two") ~ "safe",
        str_starts(result, "\\d") ~ "eliminated",
        str_starts(result, "Eliminated|Withdrew") ~ NA,
        str_starts(result, "Runner-up") ~ "eliminated",
        str_starts(result, "Immune") ~ "immune",
        .default = "unknown"
      ),
      position = case_when(
        str_starts(result, "\\d") ~ str_extract(result, "\\d+"),
        str_starts(result, "Winner") ~ "1",
        str_starts(result, "Runner-up") ~ "2",
        str_starts(result, "Eliminated|Withdrew|Safe|Bottom two") ~ NA,
        .default = "unknown"
      ),
      across(
        c(vote_day, vote_day_part, position, vote_share),
        as.numeric
      )
    ) |>
    arrange(vote_day, vote_day_part) |>
    mutate(x = 1,
           n = cumsum(x),
           .by = contestant) |>
    select(
      season,
      day = vote_day,
      vote = n,
      contestant,
      result = result_outcome,
      position,
      vote_share
    )

  # Manual adjustment for season 1
  if (n == 1) {
    vote_results <- vote_results |>
      mutate(result = if_else(position == max(position, na.rm = TRUE),
                              "eliminated",
                              "safe"),
             .by = vote)
  }

  results <- bind_rows(results,
                       vote_results)

  ### TRIALS #####
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

  trial_decision <- rows |>
    map_chr(
      \(x) {
        z <- x |>
          html_children() |>
          html_attr("style") |>
          str_extract("(?<=(background(-color)?|bgcolor):)(#)?[[:alnum:]]+") |>
          unique()
        z <- first(z[!is.na(z)])
        if (length(z) == 0) z <- "unknown"
        z
      }
    ) |>
    coalesce(
      html_attr(rows, "style") |>
        str_extract("(?<=(background(-color)?|bgcolor):)(#)?[[:alnum:]]+"),
      html_attr(rows, "bgcolor")
    ) |>
    case_match(
      "#FFFF99" ~ "public",
      "#ff9" ~ "public",
      "#9cf" ~ "contestants",
      "#99CCFF" ~ "contestants",
      "#99ccff" ~ "contestants",
      "lightgreen" ~ "showrunners",
      "#90EE90" ~ "showrunners",
      .default = "unknown"
    )

  if (any(trial_decision == "unknown") | any(is.na(trial_decision))) browser()

  known_year <- lubridate::year(seasons$start_date[seasons$season == n])

  trials_tbl_raw <- trials_raw |>
    html_table()

  if (sum(names(trials_tbl_raw) == "Name of trial") == 2) {
    cols <- which(names(trials_tbl_raw) == "Name of trial")
    trial_names <- trials_tbl_raw[,3:4] |>
      pmap_chr(
        \(...) {
          nm1 <- list(...)[[1]]
          nm2 <- list(...)[[2]]
          if (nm1 == nm2) return(nm1)
          str_c(nm1, ": ", nm2)
        }
      )
    trials_tbl_raw[, 3] <- trial_names
    trials_tbl_raw <- trials_tbl_raw[, -4]
  }

  trials_tbl <- trials_tbl_raw |>
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
           ),
           season = n,
           chosen_by = trial_decision) |>
    rename(
      number = 1,
      name = 3,
      contestant = 4
    ) |>
    mutate(
      contestant = str_replace_all(contestant,
                                   pattern = "([[:lower:]])([[:upper:]])",
                                   replacement = "\\1; \\2"),
      contestant = str_replace_all(contestant,
                                   pattern = "\\s{2,}",
                                   replacement = "; "),

      live = str_detect(number, "[Ll]ive"),
      number = str_extract(number, "\\d+"),

      # Type validation
      across(
        c(season, number, stars_available, stars_won),
        as.numeric
      ),
      across(
        c(name, contestant),
        as.character
      )
    ) |>
    select(
      season,
      number,
      date,
      name,
      live,
      contestant,
      chosen_by,
      stars_available,
      stars_won
    ) |>
    # Combine double rows (two contestants)
    group_by(season, number, date, name, live, chosen_by) |>
    summarise(contestant = str_c(contestant, collapse = "; "),
              stars_available = sum(stars_available, na.rm = TRUE),
              stars_won = sum(stars_won, na.rm = TRUE),
              .groups = "drop")

  ### Overall trial performance #####
  # Overall trial performance
  cli::cli_alert("Beginning trial performance table")
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
    rename(contestant = 1) |>
    # Manual adjustments
    mutate(
      contestant = case_match(
        contestant,
        "Georgia Toffolo" ~ 'Georgia "Toff" Toffolo',
        .default = contestant
      )
    ) |>
    mutate(stars = stars_clean,
           # Manual star adjustments for bugs/typos in wiki page
           stars = case_when(
             contestant == "Malique Thompson-Dwyer" ~ list("11/11 stars"),
             contestant == "Louise Minchin" ~ list("10/10 stars"),
             contestant == "Richard Madeley" ~ list("4/10 stars"),
             .default = stars
           ),
           stars_available = as.numeric(str_extract(stars, "(?<=/)\\d+")),
           stars_won= as.numeric(str_extract(stars, "\\d+(?=/)")),
           across(
             where(is.character),
             \(x) str_remove(x, pattern = "\\[.*?\\]")
           ),
           trial_performance = stars_won/stars_available) |>
    replace_na(list(stars_available = 0, stars_won = 0)) |>
    select(contestant,
           stars_available,
           stars_won,
           trial_performance)


  ### RATINGS #####
  # Clean up ratings
  cli::cli_alert("Beginning ratings table")
  if (n <= 9) {
    season_ratings <- tables[["ratings"]] |>
      rename(
        episode = 1,
        date = 2,
        viewership_millions = 3,
        weekly_uk_tv_rank = 4
      )
  } else if (n == 10) {
    season_ratings <- tables[["ratings"]] |>
      rename(
        episode = 1,
        date = 2,
        viewership_millions = 6,
        weekly_itv_rank = 4
      )
  } else if (n > 15) {
    season_ratings <- tables[["ratings"]] |>
      rename(
        episode = 1,
        date = 2,
        viewership_millions = 3,
        weekly_itv_rank = 4
      )
  } else {
    season_ratings <- tables[["ratings"]] |>
      rename(
        episode = 1,
        date = 2,
        viewership_millions = 7,
        weekly_itv_rank = 4
      )
  }

  season_ratings <- season_ratings |>
    filter(str_detect(episode, "[[:alpha:]]", negate = TRUE)) |>
    mutate(
      full_date = case_when(
        str_detect(date, "\\d+ \\w+$") ~ str_c(date, known_year, sep = " "),
        .default = date
      ),
      full_date = lubridate::dmy(full_date)
    )  |>
    mutate(
      across(
        any_of(c("episode",
                 "viewership_millions",
                 "weekly_uk_tv_rank",
                 "weekly_itv_rank")),
        as.numeric
      ),
      season = n
    ) |>
    select(
      season,
      episode,
      date = full_date,
      viewership_millions,
      any_of(
        c("weekly_uk_tv_rank",
          "weekly_itv_rank")
      )
    )

  ### CHALLENGES #####
  # Tidy up dingo dollar challenge tables
  if ("dingo_dollar_challenges" %in% names(tables)) {

    dd <- tables_raw[["dingo_dollar_challenges"]]

    q_success <- dd |>
      html_elements("tr") |>
      discard(\(r) {
        first(html_name(html_children(r)))!="td"
      }) |>
      html_attr("style") |>
      str_extract("(?<=background:).*(?=;)|(?<=background:).*$") |>
      case_match(
        "#afa" ~ "correct",
        "#90ff90" ~ "correct",
        "#aaffaa" ~ "correct",
        "#ddffdd" ~ "correct",
        "#aaffff" ~ "not_asked",
        "#" ~ "not_asked",
        "lightgrey" ~ "not_asked",
        NA ~ "not_asked",
        "#ffdddd" ~ "incorrect",
        "#faa" ~ "incorrect",
        "#ff9090" ~ "incorrect",
        "#ffaaaa" ~ "incorrect",
        .default = "missing"
      )

    dd_tbl <- tables[["dingo_dollar_challenges"]] |>
      rename(
        episode = Episode,
        any_of(
          c(
            prizes_available = "Prizes available",
            prize = "Prize chosen",
            prize = "Prize",
            date = "Air date"
          )
        ),
        episode = 1,
        date = 2,
        contestant = Celebrities
      ) |>
      mutate(
        season = n,
        episode = as.numeric(episode),
        question = q_success,
        across(
          any_of(c("date")),
          \(d) {
            str_c(d, known_year) |>
              lubridate::dmy()
          }
        ),
        across(
          any_of(c("contestant", "prizes_available", "prize")),
          \(x) {
            x |>
              str_replace_all(pattern = "([[:lower:]])([[:upper:]])",
                              replacement = "\\1; \\2") |>
              str_replace_all(pattern = "\\s{2,}",
                              replacement = "; ")
          }
        )
      ) |>
      select(
        season,
        episode,
        any_of(c("date")),
        contestant,
        question,
        any_of(
          c("prizes_available",
            "prize")
        )
      )
    # Append season DD challenge table to overall table
    challenges <- bind_rows(challenges,
                            dd_tbl)  |>
      select(
        season,
        episode,
        any_of(c("date")),
        contestant,
        any_of(
          c("prizes_available",
            "prize")
        ),
        question
      )
    if ("prizes_available" %in% names(challenges)) {
      challenges <- challenges |>
        mutate(
          prizes_available = if_else(is.na(prizes_available),
                                     prize,
                                     prizes_available)
        )
    }
  }

  ### FINALISE AND APPEND #####
  # Get finalised datasets and append
  cli::cli_alert("Appending season tables")
  season_contestants <- contestants_overview |>
    left_join(trial_perf_tbl, by = "contestant") |>
    left_join(n_trials, by = c("id_name" = "contestant")
    ) |>
    select(
      season,
      first_name,
      nickname,
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

  trials <- bind_rows(trials,
                      trials_tbl)
  ratings <- bind_rows(ratings,
                       season_ratings)

  cli::cli_alert_success("Completed for season {n}")
}

usethis::use_data(contestants, overwrite = TRUE)
usethis::use_data(results, overwrite = TRUE)
usethis::use_data(trials, overwrite = TRUE)
usethis::use_data(challenges, overwrite = TRUE)
usethis::use_data(ratings, overwrite = TRUE)

