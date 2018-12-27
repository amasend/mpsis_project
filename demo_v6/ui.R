library(leaflet)
library(shinyalert)

# Choices for drop-downs
vars <- cities_names
algorithms <- c('Option_1', 'Option_2')

navbarPage("Trip search optimalizator", id="nav",

  tabPanel("Interactive map",
    div(class="outer",

      tags$head(
        # Include our custom CSS
        includeCSS("styles.css"),
        includeScript("gomap.js")
      ),

      # If not using custom CSS, set height of leafletOutput to a number instead of percent
      leafletOutput("map", width="100%", height="100%"),

      # Shiny versions prior to 0.11 should use class = "modal" instead.
      absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
        draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
        width = 330, height = "auto",
        useShinyalert(),

        h2("Trip search"),

        #selectInput("color", "Color", vars),
        #selectInput("city_airport", "City airport", vars, selected = "Prague Ruzyne Airport"),
        selectizeInput(
          'city', label = "Departure city", choices = vars,
          options = list(maxItems = 1)
        ),
        selectizeInput(
          'algorithm', label = "Select Algorithm", choices = algorithms,
          options = list(maxItems = 1)
        ),
        #textInput("airport", "IATA code of departure airport ", "PRG"),
        h3("Departure date range"),
        h5("From date:"),
        div(style="display:inline-block",textInput("day", "Day", "1", width=70, value=1)),
        div(style="display:inline-block",textInput("month", "Month", "1", width=70, value=2)),
        div(style="display:inline-block",textInput("year", "Year", "1", width=70, value=2019)),
        numericInput("price_threshold", "Maximum overall price in EUR", 500),
        numericInput("time_in_city", "Time in days to stay in city", 2),
        numericInput("maximum_cities", "How many cities you want to visit", 5),
        actionButton("compute", "Compute best route", icon("refresh")),
        #actionButton("preview", "Preview"),
        textOutput("test")
      ),

      tags$div(id="cite",
        'Data taken from ', tags$em('https://www.kiwi.com/us/'), 'App created by Bartosz Frankowski, Amadeusz Masny, Milosz Sliwinski, Anna Wojcik.'
      )
    )
  ),
  conditionalPanel("false", icon("crosshair"))
)
