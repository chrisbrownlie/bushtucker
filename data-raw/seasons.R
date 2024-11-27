## code to prepare `seasons` dataset goes here

library(rvest)
library(dplyr)
library(stringr)

main_wiki_page <- "https://en.wikipedia.org/wiki/I%27m_a_Celebrity...Get_Me_Out_of_Here!_(British_TV_series)#Series_overview"

seasons <- main_wiki_page |>
  read_html() |>
  html_element(css = "table.wikitable:nth-child(1)") |>
  html_table(header = FALSE) |>
  select(
    season = 1,
    contestants = 2,
    location = 3,
    presenters = 4,
    episodes = 5,
    start_date = 7,
    end_date = 8,
    winner = 9,
    runner_up = 10,
    third_place = 11,
    avg_viewers_millions = 12
  ) |>
  slice(-1, -2) |>
  filter(!is.na(season)) |>
  mutate(
    avg_viewers_millions = na_if(avg_viewers_millions, "TBA"),
    across(
      c(season, contestants, episodes, avg_viewers_millions),
      as.numeric
    ),
    across(
      c(start_date, end_date),
      \(x) {
        x |>
          str_extract("(?<=\\().*?(?=\\))") |>
          lubridate::ymd()
      }
    )
  )

usethis::use_data(seasons, overwrite = TRUE)

