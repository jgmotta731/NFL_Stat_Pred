library(shiny)
library(bslib)
library(reactable)
library(dplyr)
library(readr)
library(shinyWidgets)
library(arrow)
library(htmltools)
library(nflreadr)

# Load headshots
headshots <- load_player_stats(2018:most_recent_season()) %>%
  filter(position %in% c("WR", "TE", "QB", "RB")) %>%
  select(player_display_name, headshot_url) %>%
  mutate(player_display_name = player_display_name) %>%
  distinct(player_display_name, .keep_all = TRUE)

# Load prediction data
qb_preds <- read_parquet("QB_Preds.parquet") %>% left_join(headshots, by = "player_display_name")
rb_preds <- read_parquet("RB_Preds.parquet") %>% left_join(headshots, by = "player_display_name")
rec_preds <- read_parquet("WR_TE_Preds.parquet") %>% left_join(headshots, by = "player_display_name")

# Load metrics data
qb_metrics <- read_parquet("QB_Metrics.parquet")
rb_metrics <- read_parquet("RB_Metrics.parquet")
rec_metrics <- read_parquet("WR_TE_Metrics.parquet")

# Theme
my_theme <- bs_theme(
  version = 5,
  bg = "#121212",
  fg = "#FFFFFF",
  primary = "#FF0000",
  base_font = font_google("Inter"),
  heading_font = font_google("Roboto"),
  "navbar-bg" = "#121212",
  "navbar-dark-color" = "#FFFFFF",
  "navbar-dark-hover-color" = "#FF0000"
)

# UI
ui <- tagList(
  tags$head(
    tags$style(HTML("
      .navbar-brand {
        display: flex;
        align-items: center;
      }
      .navbar-brand img {
        margin-right: 10px;
        height: 40px;
      }
    "))
  ),
  navbarPage(
    title = div(
      tags$img(src = "QB_Tool.png", alt = "Logo", height = "40px"),
      "NFL Player Predictor"
    ),
    theme = my_theme,
    
    # --- HOME TAB ---
    tabPanel(
      "Home",
      div(
        class = "container-fluid",
        style = "padding: 2rem;",
        div(
          class = "card",
          style = "background-color: #1e1e1e; border: 1px solid #FF0000; padding: 2rem; color: white;",
          div(
            class = "card-body text-center",
            h1("Welcome to NFL Player Stat Predictor", class = "display-4 mb-4"),
            p(class = "lead",
              "Harness the power of machine learning to predict NFL player performance."
            )
          )
        ),
        div(
          class = "row",
          lapply(1:3, function(i) {
            bg <- if (i %% 2 == 0) "#1e1e1e" else "#FFFFFF"
            fg <- if (i %% 2 == 0) "white" else "black"
            content <- c(
              "Advanced Analytics" = "Leveraging machine learning models trained on historical NFL data.",
              "Weekly Updates" = "Fresh predictions before every game, incorporating the latest player and team data.",
              "Key Statistics" = "Accurate predictions for passing yards, touchdowns, interceptions, and more."
            )
            div(
              class = "col-md-4",
              div(
                class = "card h-100",
                style = paste0("background-color: ", bg, "; border: 1px solid #FF0000; color: ", fg, ";"),
                div(
                  class = "card-body",
                  h3(names(content)[i], class = "card-title text-danger"),
                  p(content[[i]])
                )
              )
            )
          })
        )
      )
    ),
    
    # --- PREDICTIONS TAB ---
    tabPanel(
      "Predictions",
      div(class = "container-fluid", style = "padding: 2rem;",
          fluidRow(
            column(
              width = 2,
              div(
                style = "background-color: #121212; border: 1px solid #FF0000; padding: 1rem; color: #FFFFFF;",
                h4("Select Position Group"),
                selectInput("position_group", "Position:",
                            choices = c("QB", "RB", "WR/TE"), selected = "QB"),
                hr(),
                h4("Implied Probability Calculator"),
                p(HTML("Enter American odds (positive or negative) to calculate the implied probability of the event.")),
                textInput("american_odds", "American Odds:", ""),
                actionButton("calculate", "Calculate", style = "background-color: #FF0000; color: #FFFFFF;"),
                verbatimTextOutput("implied_prob")
              )
            ),
            column(
              width = 10,
              div(
                class = "card",
                style = "background-color: #1e1e1e; border: 1px solid #FF0000;",
                div(
                  class = "card-body",
                  h2("Weekly Player Performance Predictions", class = "mb-3", style = "color: white;"),
                  p("Sort and filter predictions by clicking column headers or using the search box.", style = "color: white;")
                )
              ),
              div(style = "width: 100%;", reactableOutput("predictions_table"))
            )
          )
      )
    ),
    
    # --- METRICS TAB ---
    tabPanel(
      "Metrics",
      div(
        class = "container-fluid",
        style = "padding: 2rem;",
        fluidRow(
          column(
            width = 3,
            div(
              style = "background-color: #121212; border: 1px solid #FF0000; padding: 1rem; color: #FFFFFF;",
              h4("Understanding the Metrics"),
              p(HTML("<strong>RMSE (Root Mean Squared Error):</strong><br>
              RMSE measures the average prediction error in the same units as the stat being predicted. 
              A lower RMSE generally indicates better model performance. In sports analytics, an RMSE that’s around 
              10–20% of the typical range of the stat is often considered quite good—especially for game-to-game predictions 
              where high variability is expected.")),
              br(),
              p(HTML("<strong>R-squared (R²):</strong><br>
              R² reflects how much of the variation in the stat your model explains. While a value closer to 1 is ideal, 
              that’s rarely realistic in complex real-world data. In player stat prediction, R² values around 0.3–0.5 
              (or even lower) can still represent strong performance and useful predictive power.")),
              br(),
              p(HTML("<strong>Why These Matter:</strong><br>
              These metrics help gauge whether the model meaningfully improves upon simple baselines, even in the presence 
              of randomness—like injuries, coaching decisions, or unexpected game flow."))
            )
          ),
          column(
            width = 9,
            div(style = "margin-bottom: 1rem;",
                h4("QB Model Metrics", style = "color: white;"),
                reactableOutput("qb_metrics_table")),
            div(style = "margin-bottom: 1rem;",
                h4("RB Model Metrics", style = "color: white;"),
                reactableOutput("rb_metrics_table")),
            div(style = "margin-bottom: 1rem;",
                h4("WR/TE Model Metrics", style = "color: white;"),
                reactableOutput("rec_metrics_table"))
          )
        )
      )
    )
  )
)

# Server
# Server
server <- function(input, output) {
  
  # Reactive dataset based on position
  selected_data <- reactive({
    switch(input$position_group,
           "QB" = qb_preds,
           "RB" = rb_preds,
           "WR/TE" = rec_preds)
  })
  
  # Dynamic reactable output
  output$predictions_table <- renderReactable({
    data <- selected_data()
    # Add a dummy 'Player' column to trigger the custom cell rendering
    data$Player <- data$player_display_name
    
    # Dynamically define columns based on position group
    col_defs <- switch(input$position_group,
                       "QB" = list(
                         Player = colDef(
                           name = "Player",
                           html = TRUE,
                           minWidth = 150,
                           filterable = TRUE,
                           cell = function(value, index) {
                             img_url <- selected_data()[index, "headshot_url", drop = TRUE]
                             htmltools::div(
                               style = "text-align: center;",
                               htmltools::tags$img(src = img_url, height = "80px", 
                                                   style = "border-radius: 50%; margin-bottom: 4px;"),
                               htmltools::div(style = "font-size: 14px; color: #FFFFFF;", value)
                             )
                           },
                           align = "left"
                         ),
                         recent_team = colDef(name = "Tm", filterable = TRUE, minWidth = 70, align = "left"),
                         opponent_team = colDef(name = "Opp", filterable = TRUE, minWidth = 70, align = "left"),
                         game_date = colDef(name = "Game Date", filterable = TRUE, minWidth = 130, align = "center"),
                         week = colDef(name = "Wk", filterable = TRUE, minWidth = 70, align = "center"),
                         pred_attempts = colDef(name = "Pass Att", filterable = TRUE, minWidth = 95, align = "right"),
                         pred_completions = colDef(name = "Cmp", filterable = TRUE, minWidth = 80, align = "right"),
                         pred_passing_yards = colDef(name = "Pass Yds", filterable = TRUE, minWidth = 100, align = "right"),
                         pred_passing_tds = colDef(name = "Pass TD", filterable = TRUE, minWidth = 95, align = "right"),
                         pred_interceptions = colDef(name = "Int", filterable = TRUE, minWidth = 60, align = "right"),
                         pred_carries = colDef(name = "Rush Att", filterable = TRUE, minWidth = 110, align = "right"),
                         pred_rushing_yards = colDef(name = "Rush Yds", filterable = TRUE, minWidth = 105, align = "right"),
                         pred_rushing_tds = colDef(name = "Rush TD", filterable = TRUE, minWidth = 100, align = "right"),
                         pred_fantasy_points = colDef(name = "FF Pts", filterable = TRUE, minWidth = 90, align = "right")
                       ),
                       "RB" = list(
                         Player = colDef(
                           name = "Player",
                           html = TRUE,
                           minWidth = 50, maxWidth = 150,
                           filterable = TRUE,
                           cell = function(value, index) {
                             img_url <- selected_data()[index, "headshot_url", drop = TRUE]
                             htmltools::div(
                               style = "text-align: center;",
                               htmltools::tags$img(src = img_url, height = "80px", 
                                                   style = "border-radius: 50%; margin-bottom: 4px;"),
                               htmltools::div(style = "font-size: 14px; color: #FFFFFF;", value)
                             )
                           }, align = "left"
                         ),
                         recent_team = colDef(name = "Tm", filterable = TRUE, minWidth = 30, maxWidth = 90, align = "left"),
                         opponent_team = colDef(name = "Opp", filterable = TRUE, minWidth = 30, maxWidth = 90, align = "left"),
                         game_date = colDef(name = "Game Date", filterable = TRUE, minWidth = 30, maxWidth=170, align = "center"),
                         week = colDef(name = "Wk", filterable = TRUE, minWidth = 30, maxWidth = 80, align = "center"),
                         pred_carries = colDef(name = "Rush Att", filterable = TRUE, minWidth = 80, maxWidth = 110, align = "right"),
                         pred_rushing_yards = colDef(name = "Rush Yds", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_rushing_tds = colDef(name = "Rush TDs", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_receptions = colDef(name = "Rec", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_receiving_yards = colDef(name = "Rec Yds", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_fantasy_points = colDef(name = "FF Pts", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_fantasy_points_ppr = colDef(name = "PPR Pts", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right")
                       ),
                       "WR/TE" = list(
                         Player = colDef(
                           name = "Player",
                           html = TRUE,
                           minWidth = 50, maxWidth = 150,
                           filterable = TRUE,
                           cell = function(value, index) {
                             img_url <- selected_data()[index, "headshot_url", drop = TRUE]
                             htmltools::div(
                               style = "text-align: center;",
                               htmltools::tags$img(src = img_url, height = "80px", 
                                                   style = "border-radius: 50%; margin-bottom: 4px;"),
                               htmltools::div(style = "font-size: 14px; color: #FFFFFF;", value)
                             )
                           }, align = "left"
                         ),
                         position = colDef(name = "Pos", filterable = TRUE, minWidth = 30, maxWidth = 80, align = "center"),
                         recent_team = colDef(name = "Tm", filterable = TRUE, minWidth = 30, maxWidth = 90, align = "left"),
                         opponent_team = colDef(name = "Opp", filterable = TRUE, minWidth = 30, maxWidth = 90, align = "left"),
                         game_date = colDef(name = "Game Date", filterable = TRUE, minWidth = 30, maxWidth=170, align = "center"),
                         week = colDef(name = "Wk", filterable = TRUE, minWidth = 30, maxWidth = 80, align = "right"),
                         pred_receptions = colDef(name = "Rec", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_receiving_yards = colDef(name = "Rec Yds", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_receiving_tds = colDef(name = "Rec TDs", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_fantasy_points = colDef(name = "FF Pts", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right"),
                         pred_fantasy_points_ppr = colDef(name = "PPR Pts", filterable = TRUE, minWidth = 30, maxWidth = 110, align = "right")
                       )
    )
    data <- data[, names(col_defs)]
    reactable(
      data,
      columns = col_defs,
      theme = reactableTheme(
        backgroundColor = "#121212",
        borderColor = "#FF0000",
        stripedColor = "#1A1A1A",
        highlightColor = "#FF000022",
        cellPadding = "1rem",
        style = list(
          fontFamily = "Inter, sans-serif",
          color = "#FFFFFF"
        ),
        headerStyle = list(
          backgroundColor = "#000000",
          color = "#FFFFFF",
          "&:hover" = list(backgroundColor = "#FF0000")
        ),
        inputStyle = list(
          backgroundColor = "#FFFFFF",
          color = "#000000",
          borderColor = "#FF0000"
        )
      ),
      striped = TRUE,
      highlight = TRUE,
      borderless = TRUE,
      defaultPageSize = 3,
      pagination = TRUE
    )
  })
  
  # Implied Probability Calculator
  output$implied_prob <- renderText({
    req(input$calculate)
    odds <- as.numeric(input$american_odds)
    if (is.na(odds)) {
      return("Please enter a valid numeric American Odds.")
    }
    prob <- if (odds < 0) {
      abs(odds) / (abs(odds) + 100) * 100
    } else {
      100 / (odds + 100) * 100
    }
    paste("Implied Probability:", round(prob, 2), "%")
  })
  
  # Metrics tables
  make_metrics_table <- function(df) {
    reactable(
      df,
      columns = list(
        response = colDef(name = "Target Variable"),
        rmse = colDef(name = "RMSE", format = colFormat(digits = 2)),
        rsq = colDef(name = "R-squared", format = colFormat(digits = 3))
      ),
      defaultPageSize = 5,
      bordered = TRUE,
      striped = TRUE,
      highlight = TRUE,
      theme = reactableTheme(
        backgroundColor = "#121212",
        borderColor = "#FF0000",
        stripedColor = "#1A1A1A",
        style = list(color = "#FFFFFF"),
        headerStyle = list(backgroundColor = "#000000", color = "#FFFFFF")
      )
    )
  }
  
  output$qb_metrics_table <- renderReactable({ make_metrics_table(qb_metrics) })
  output$rb_metrics_table <- renderReactable({ make_metrics_table(rb_metrics) })
  output$rec_metrics_table <- renderReactable({ make_metrics_table(rec_metrics) })
}

shinyApp(ui, server)
