### SEASON 1

n <- 1

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
if (length(tables_raw) != 5) {
  cli::cli_abort("Season {n} wiki page has {length(tables_raw)} tables on it")
}
tables <- tables_raw |>
  html_table() |>
  rlang::set_names(c("contestants", "daily_results", "trials", "trial_performance", "ratings"))


cli::cli_alert("Tables extracted")
cli::cli_alert("Beginning contestants table")

# Tidy up contestants table
contestants_overview <- tables[["contestants"]] |>
  rename(
    contestant = Celebrity,
    famous_for = `Famous for`,
    status = Status
  ) |>
  mutate(
    season = n,
    position_desc = str_extract(status,
                                "^.*?(?=on \\d)"),
    position = n() + 1 - as.numeric(str_extract(status, "(?<=Eliminated )\\d+")),
    position = case_when(
      position_desc == "Winner" ~ 1,
      position_desc == "Runner-up" ~ 2,
      .default = position
    ),
    date_eliminated = str_extract(
      status,
      "(?<=on )[[:alnum:] ]+"
    ) |>
      lubridate::dmy(),
    first_name = str_extract(contestant, "^[\\w-]+"),
    last_name = str_extract(contestant, "[\\w-]+$")
  ) |>
  select(
    season,
    contestant,
    first_name,
    last_name,
    famous_for,
    position,
    position_desc,
    date_eliminated
  )

# Tidy up daily results
cli::cli_alert("Beginning daily table")
daily <- tables[["daily_results"]] |>
  set_names(names(tables[["daily_results"]]))

if (daily[[1,1]] == names(daily)[1]) {
  daily <- slice(daily, -1)
}
daily <- daily |>
  rename(contestant = 1,
         trials = Trials) |>
  semi_join(contestants, by = c("contestant" = "first_name")) |>
  pivot_longer(cols = -c(contestant, trials),
               names_to = "day",
               values_to = "position") |>
  mutate(
    across(
      c(day, position),
      \(x) str_extract(x, "\\d+") |> as.numeric()
    )
  )

# Tidy up trials - use raw table as stars col is weird
cli::cli_alert("Beginning trials table")
trials <- tables_raw[[3]]

stars <- trials |>
  html_elements("span") |>
  html_attr("title") |>
  discard(is.na)
stars_clean <- stars |>
  keep_at(at = seq(from = 1, to = length(stars), by = 2))

trials_tbl <- trials |>
  html_table() |>
  mutate(stars = stars_clean,
         stars_available = str_extract(stars, "(?<=/)\\d+"),
         stars_won= str_extract(stars, "\\d+(?=/)"),
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
    contestant = str_replace(contestant,
                             pattern = "([[:lower:]])([[:upper:]])",
                             replacement = "\\1; \\2")
  )

# Overall trial performance
cli::cli_alert("Beginning trial perforamnce table")
trial_perf <- tables_raw[[4]]

stars <- trial_perf |>
  html_elements("span") |>
  html_attr("title") |>
  discard(is.na)
stars_clean <- stars |>
  keep_at(at = seq(from = 1, to = length(stars), by = 2))

trial_perf_tbl <- trial_perf |>
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
  )|>
  mutate(
    full_date = str_c(date, last(date), sep = " ") |>
      lubridate::dmy()
  ) |>
  filter(str_detect(episode, "\\d"))  |>
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

# Get finalised datasets and append
cli::cli_alert("Appending season tables")
season_contestants <- contestants_overview |>
  left_join(trial_perf_tbl, by = "contestant") |>
  left_join(
    unique(select(daily, contestant, trials)),
    by = c("first_name" = "contestant")
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

season_results <- daily |>
  select(first_name = contestant, day, position) |>
  left_join(select(contestants, first_name, last_name), by = "first_name") |>
  mutate(season = n) |>
  select(season,
         contestant_first_name = first_name,
         contestant_last_name = last_name,
         day,
         position)
results <- bind_rows(results,
                     season_results)

ratings <- bind_rows(ratings,
                     season_ratings)

cli::cli_alert_success("Completed for season {n}")
