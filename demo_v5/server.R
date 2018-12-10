library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(jsonlite)
library(shinyalert)
library(geosphere)

set.seed(100)

function(input, output, session) {
  ## Interactive Map ###########################################

  # Create the map
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = 19.94497990000002, lat = 50.06465009999999, zoom = 5)
  })

  # A reactive expression that returns the set of zips that are
  # in bounds right now
  zipsInBounds <- reactive({
    if (is.null(input$map_bounds))
      return(zipdata[FALSE,])
    bounds <- input$map_bounds
    latRng <- range(bounds$north, bounds$south)
    lngRng <- range(bounds$east, bounds$west)

    subset(zipdata,
           From_latitude >= latRng[1] & From_latitude <= latRng[2] &
             From_longitude >= lngRng[1] & From_longitude <= lngRng[2])
  })

  # This observer is responsible for maintaining the circles and legend,
  # according to the variables the user has chosen to map to color and size.
  observe({
    colorBy <- "Price"
    sizeBy <- "Price"
    cityFrom <- data.frame(city = unique(as.character(zipdata[zipdata[, 'name'] == input$city_airport,]$From[1])),
                           latitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_latitude[1])),
                           longitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_longitude[1])))
    
    cityFrom.city <- factor(cityFrom$city, levels=levels(zipdata$From))
    cityFrom.year <- factor(input$year, levels=levels(zipdata$Year))
    cityFrom.month <- factor(input$month, levels=levels(zipdata$Month))
    cityFrom.day <- factor(input$day, levels=levels(zipdata$Day))
    
    
    price <- zipdata[(zipdata$From == cityFrom.city) & (zipdata$Year == as.numeric(input$year)) & (zipdata$Month == as.numeric(input$month)) & (zipdata$Day == as.numeric(input$day)),]$Price
    
    lati <- zipdata[(zipdata$From == cityFrom.city) & (zipdata$Year == as.numeric(input$year)) & (zipdata$Month == as.numeric(input$month)) & (zipdata$Day == as.numeric(input$day)),]$To_latitude
    longi <- zipdata[(zipdata$From == cityFrom.city) & (zipdata$Year == as.numeric(input$year)) & (zipdata$Month == as.numeric(input$month)) & (zipdata$Day == as.numeric(input$day)),]$To_longitude
    colorData <- ifelse(price >= input$price_threshold,
                        paste(input$price_threshold,'-',max(price)),
                        paste('<=', input$price_threshold))
    pal <- colorFactor(c("#0000FF","#FF0000"), colorData)
    radius <- price / max(price) * 50000
  # Update map
    leafletProxy("map", data = zipdata) %>%
      clearShapes() %>%
      clearMarkers() %>%
      addMarkers(lng = cityFrom$longitude, lat = cityFrom$latitude) %>%
      
      addCircles(longi,
                 lati,
                 radius=radius, layerId=row.names(data),
                 stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      setView(lng = cityFrom$longitude,
              lat = cityFrom$latitude,
              zoom = 5) %>%
      addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
        layerId="colorLegend")
    
  })
  
  observeEvent(input$compute, {
    
    if (input$price_threshold <= 0) {
        shinyalert(paste("Incorrect price treshold."), type = "info")
    } else if (input$maximum_cities <= 0){
        shinyalert(paste("Incorrect cities count."), type = "info")
    } else if (input$time_in_city <= 0){
        shinyalert(paste("Incorrect value of time."), type = "info")
    } else if (!(input$year %in% zipdata$Year)){
        shinyalert(paste("Incorrect year value."), type = "info")
    } else if (!(input$month %in% zipdata$Month)){
        shinyalert(paste("Incorrect month value."), type = "info")
    } else if (!(input$day %in% zipdata$Day)){
        shinyalert(paste("Incorrect day value."), type = "info")
    } else {
    
      cityFrom <- data.frame(city = unique(as.character(zipdata[zipdata[, 'name'] == input$city_airport,]$From[1])),
                             latitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_latitude[1])),
                             longitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_longitude[1])))
      shinyalert("Searching...", "Now, our minions are searching the best trip for you! Please be patient and wait for their result, if you want to check the progress see the right down corner :)", type = "info")
  
      progress <- shiny::Progress$new()
      on.exit(progress$close())
      progress$set(message = "Generating graph...", value = 0)
      progress$inc(1/10, detail = paste("In progress...", 1))
      cmd <- paste("python generate_graf.py", input$price_threshold, input$maximum_cities, input$time_in_city,
                   cityFrom$city, input$year, input$month, input$day)
  
      system(cmd, intern = TRUE)
      progress$inc(1/10, detail = paste("In progress...", 3))
      fn <- "/home/shiny/data.dat"
      if (file.exists(fn)) {
        cmd <- paste("./solv_shiny model.mod /home/shiny/data.dat")
        system(cmd, intern = TRUE)
        progress$inc(1/10, detail = paste("In progress...", 8))
        con <- read.csv("/home/shiny/file.txt",sep=";")
        con <- as.numeric(unlist(strsplit(colnames(con)[2], "X"))[2])
      }else
      {
        con <- "stop"
      }
      if (con > input$price_threshold | con == "stop") { # if there is only one symbol it means that PRIMAL is INFEASIBLE
          shinyalert(paste("We cannot find a trip that meets your requirements. Try again with different parameters."), type = "info")
          progress$inc(1/10, detail = paste("In progress...", 10))
      } 
      else {# PRIMAL FEASIBLE part 
        fn <- "/home/shiny/data.dat"
        if (file.exists(fn)) file.remove(fn)
        system("python generate_path.py", intern = TRUE)
        fn <- "/home/shiny/file.txt"
        if (file.exists(fn)) file.remove(fn)
        optimal_cost <- read.csv("/home/shiny/optimal_cost", col.names = c('total_cost', 'nan'))
        progress$inc(1/10, detail = paste("In progress...", 9))
        cords <- read.csv("/home/shiny/coordinates.txt", sep=",")
        lng <- cords$lon_from
        lat <- cords$lat_from
        progress$inc(1/10, detail = paste("In progress...", 10))
        shinyalert(paste("Total price:", optimal_cost$total_cost, "EUR"), "Now you can go and book your trip!", type = "info")
        # Update map
        
        geo_lines <- gcIntermediate(matrix(c(cords$lon_from, cords$lat_from), ncol=2),
                                 matrix(c(cords$lon_to, cords$lat_to), ncol=2),
                                 n=50, 
                                 addStartEnd=TRUE,
                                 sp=TRUE)
        pop <- c()
        for (row in 1:nrow(cords)) {
          pop <- c(pop, as.character(tagList(tags$h4(row, "Airport:", as.character(IANA_codes[IANA_codes[, 'code'] == factor(cords[row, ]$To, levels=levels(IANA_codes$code)), ]$name)),
                                             tags$h5("Cost: ", cords[row, ]$cost, " EUR"),
                                     sprintf("City: %s", as.character(IANA_codes[IANA_codes[, 'code'] == factor(cords[row, ]$To, levels=levels(IANA_codes$code)), ]$city))),
                                     tags$br()))
        }
        
        leafletProxy("map", data = zipdata) %>%
          clearShapes() %>%
          addPolylines(data=geo_lines, fillOpacity=0.4) %>%
          addPopups(cords$lon_to[1:nrow(cords)], cords$lat_to[1:nrow(cords)], pop)
      }
    }
  })

  # Show a popup at the given location
  showZipcodePopup <- function(row, lat, lng) {
    cityFrom <- data.frame(city = unique(as.character(zipdata[zipdata[, 'name'] == input$city_airport,]$From[1])),
                           latitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_latitude[1])),
                           longitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_longitude[1])))
    cityFrom.city <- factor(cityFrom$city, levels=levels(zipdata$From))
    selectedZip <- zipdata[zipdata$To_latitude == lat & zipdata$To_longitude == lng & zipdata$Year == as.numeric(input$year) & zipdata$Month == as.numeric(input$month) & zipdata$Day == as.numeric(input$day) & zipdata$From == cityFrom.city,]
    content <- as.character(tagList(
      tags$h4("Airport:", selectedZip$To_airport_name),
      sprintf("Ticket price: %s EUR", selectedZip$Price), tags$br()
    ))
    leafletProxy("map") %>% addPopups(lng, lat, content, layerId = row)
  }

  # When map is clicked, show a popup with city info
  observe({
    leafletProxy("map") %>% clearPopups()
    event <- input$map_shape_click
    if (is.null(event))
      return()

    isolate({
      showZipcodePopup(event$id, event$lat, event$lng)
    })
  })
}
