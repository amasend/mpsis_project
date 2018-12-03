library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(jsonlite)
library(shinyalert)

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
    
    # price <- zipdata[(zipdata$From == "KRK") & (zipdata$Year == as.numeric("2019")) & (zipdata$Month == as.numeric("01")) & (zipdata$Day == as.numeric("10")),]$Price
    # lati <- zipdata[(zipdata$From == "KRK") & (zipdata$Year == as.numeric("2019")) & (zipdata$Month == as.numeric("01")) & (zipdata$Day == as.numeric("10")),]$To_latitude
    # longi <- zipdata[(zipdata$From == "KRK") & (zipdata$Year == as.numeric("2019")) & (zipdata$Month == as.numeric("01")) & (zipdata$Day == as.numeric("10")),]$To_longitude
    # colorData <- ifelse(price >= 100,
    #                     paste(100,'-',max(price)),
    #                     paste('<=', 100))
    # pal <- colorFactor(c("#0000FF","#FF0000"), colorData)
    # radius <- price / max(price) * 300000
    
    # input$day,"/",input$month,"/",input$year
    # cityFrom.city <- factor("KBP", levels=levels(zipdata$From))
    # length(zipdata[zipdata$From == input$city_airport,]$Price)
    # length(zipdata[zipdata$From == "KBP",]$To_latitude)
    
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
    cityFrom <- data.frame(city = unique(as.character(zipdata[zipdata[, 'name'] == input$city_airport,]$From[1])),
                           latitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_latitude[1])),
                           longitude = unique(as.numeric(zipdata[zipdata[, 'name'] == input$city_airport,]$From_longitude[1])))
    shinyalert("Searching...", "Now, our minions are searching the best trip for you! Please be patient and wait for their result, if you want to check the progress see the right down corner :)", type = "info")
    # # Create a Progress object
    # progress <- shiny::Progress$new()
    # # Make sure it closes when we exit this reactive, even if there's an error
    # on.exit(progress$close())
    # # Pop up a progress bar on the right bottom corner
    # progress$set(message = "Communicating with Kiwi servers...", value = 0)
    # progress$inc(1/5, detail = paste("In progress...", 1))
    # # Make REST call to kiwi servers with new parameters
    # flights <- fromJSON(paste("https://api.skypicker.com/flights?flyFrom=",
    #                           as.character(IANA_codes[IANA_codes[, 'name'] == input$city_airport,]$code),
    #                           "&dateFrom=",input$day,"/",input$month,"/",input$year,
    #                           "&dateTo=",input$day_to,"/",input$month_to,"/",input$year_to,
    #                           "&partner=picky", sep=''))
    # progress$inc(1/5, detail = paste("In progress...", 2))
    # # Compute new data
    # data <- flights$data
    # route <- data$route
    # zipdata <- data.frame(city = character(), latitude = numeric(), longitude = numeric(), price = numeric())
    # for (i in seq(1,length(route),1)){
    #   zipdata <- rbind(zipdata, data.frame(city = data$flyTo[[i]],
    #                                        latitude = tail(route[[i]]$latTo, 1),
    #                                        longitude = tail(route[[i]]$lngTo, 1),
    #                                        price = data$price[[i]]))
    #   progress$inc(1/length(route), detail = paste("In progress...", i))
    # }
    # progress$close()
    # #cityFrom <- data.frame(city = data$flyFrom[[1]], latitude = route[[1]]$latFrom, longitude = route[[1]]$lngFrom)
    
    # colorBy <- "price"
    # sizeBy <- "price"
    # colorData <- ifelse(zipdata$price >= input$price_threshold, 
    #                     paste(input$price_threshold,'-',max(zipdata$price)), 
    #                     paste('<=', input$price_threshold))
    # pal <- colorFactor(c("#0000FF","#FF0000"), colorData)
    # radius <- zipdata[[sizeBy]] / max(zipdata[[sizeBy]]) * 300000
    
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Generating graph...", value = 0)
    progress$inc(1/10, detail = paste("In progress...", 1))
    cmd <- paste("python generate_graf.py", input$price_threshold, input$maximum_cities, input$time_in_city,
                 cityFrom$city, input$year, input$month, input$day)
    #system('chmod a+x generate_graf.py')
    system(cmd, intern = TRUE)
    progress$inc(1/10, detail = paste("In progress...", 3))
    cmd <- paste("./solv_shiny model.mod /home/shiny/data.dat")
    system(cmd, intern = TRUE)
    progress$inc(1/10, detail = paste("In progress...", 8))
    system("python generate_path.py", intern = TRUE)
    optimal_cost <- read.csv("/home/shiny/optimal_cost", col.names = c('total_cost', 'nan'))
    progress$inc(1/10, detail = paste("In progress...", 9))
    cords <- read.csv("/home/shiny/coordinates.txt", sep=",")
    lng <- cords$lon_from
    lat <- cords$lat_from
    progress$inc(1/10, detail = paste("In progress...", 10))
    shinyalert(paste("Total price:", optimal_cost$total_cost, "EUR"), "Now you can go and book your trip!", type = "info")
    # Update map
    leafletProxy("map", data = zipdata) %>%
      # clearShapes() %>%
      # clearMarkers() %>%
      # addMarkers(lng = cityFrom$longitude, lat = cityFrom$latitude) %>%
      # addCircles(~longitude, ~latitude, radius=radius, layerId=row.names(data),
      #            stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      addPolylines(lng = lng, lat = lat)
      # addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
      #           layerId="colorLegend")
  })

  # Show a popup at the given location
  showZipcodePopup <- function(row, lat, lng) {
    selectedZip <- zipdata[zipdata$To_latitude == lat & zipdata$To_longitude == lng & zipdata$Year == as.numeric(input$year) & zipdata$Month == as.numeric(input$month) & zipdata$Day == as.numeric(input$day),]
    content <- as.character(tagList(
      tags$h4("Airport:", selectedZip$city),
      sprintf("Ticket price: %s EUR", selectedZip$price), tags$br()
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
