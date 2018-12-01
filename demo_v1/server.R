library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(jsonlite)

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
      latitude >= latRng[1] & latitude <= latRng[2] &
        longitude >= lngRng[1] & longitude <= lngRng[2])
  })

  # This observer is responsible for maintaining the circles and legend,
  # according to the variables the user has chosen to map to color and size.
  observe({
    colorBy <- "price"
    sizeBy <- "price"
    colorData <- ifelse(zipdata$price >= input$price_threshold, 
                        paste(input$price_threshold,'-',max(zipdata$price)), 
                        paste('<=', input$price_threshold))
    pal <- colorFactor(c("#0000FF","#FF0000"), colorData)
    radius <- zipdata[[sizeBy]] / max(zipdata[[sizeBy]]) * 300000
  # Update map
    leafletProxy("map", data = zipdata) %>%
      clearShapes() %>%
      addMarkers(lng = cityFrom$longitude, lat = cityFrom$latitude) %>%
      addCircles(~longitude, ~latitude, radius=radius, layerId=row.names(data),
                 stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
        layerId="colorLegend")
  })
  
  observeEvent(input$compute, {
    # Create a Progress object
    progress <- shiny::Progress$new()
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    # Pop up a progress bar on the right bottom corner
    progress$set(message = "Communicating with Kiwi servers...", value = 0)
    progress$inc(1/5, detail = paste("In progress...", 1))
    # Make REST call to kiwi servers with new parameters
    flights <- fromJSON(paste("https://api.skypicker.com/flights?flyFrom=",
                              input$airport,
                              "&dateFrom=",input$day,"/",input$month,"/",input$year,
                              "&dateTo=",input$day_to,"/",input$month_to,"/",input$year_to,
                              "&partner=picky", sep=''))
    progress$inc(1/5, detail = paste("In progress...", 2))
    # Compute new data
    data <- flights$data
    route <- data$route
    zipdata <- data.frame(city = character(), latitude = numeric(), longitude = numeric(), price = numeric())
    for (i in seq(1,length(route),1)){
      zipdata <- rbind(zipdata, data.frame(city = data$flyTo[[i]],
                                           latitude = tail(route[[i]]$latTo, 1),
                                           longitude = tail(route[[i]]$lngTo, 1),
                                           price = data$price[[i]]))
      progress$inc(1/length(route), detail = paste("In progress...", i))
    }
    progress$close()
    cityFrom <- data.frame(city = data$flyFrom[[1]], latitude = route[[1]]$latFrom, longitude = route[[1]]$lngFrom)
    
    colorBy <- "price"
    sizeBy <- "price"
    colorData <- ifelse(zipdata$price >= input$price_threshold, 
                        paste(input$price_threshold,'-',max(zipdata$price)), 
                        paste('<=', input$price_threshold))
    pal <- colorFactor(c("#0000FF","#FF0000"), colorData)
    radius <- zipdata[[sizeBy]] / max(zipdata[[sizeBy]]) * 300000
    
    progress <- shiny::Progress$new()
    on.exit(progress$close())
    progress$set(message = "Generating graph...", value = 0)
    progress$inc(1/10, detail = paste("In progress...", 1))
    cmd <- paste("python generate_graf.py", input$price_threshold, input$maximum_cities, input$time_in_city, input$airport,
                 input$year, input$month, input$day)
    #system('chmod a+x generate_graf.py')
    system(cmd, intern = TRUE)
    progress$inc(1/10, detail = paste("In progress...", 3))
    cmd <- paste("./solv_shiny model.mod /home/shiny/data.dat")
    system(cmd, intern = TRUE)
    progress$inc(1/10, detail = paste("In progress...", 8))
    system("python generate_path.py", intern = TRUE)
    progress$inc(1/10, detail = paste("In progress...", 9))
    cords <- read.csv("/home/shiny/coordinates.txt", sep=",")
    lng <- cords$lon_from
    lat <- cords$lat_from
    progress$inc(1/10, detail = paste("In progress...", 10))
    progress$close()
    # Update map
    leafletProxy("map", data = zipdata) %>%
      clearShapes() %>%
      clearMarkers() %>%
      addMarkers(lng = cityFrom$longitude, lat = cityFrom$latitude) %>%
      addCircles(~longitude, ~latitude, radius=radius, layerId=row.names(data),
                 stroke=FALSE, fillOpacity=0.4, fillColor=pal(colorData)) %>%
      addPolylines(lng = lng, lat = lat) %>%
      addLegend("bottomleft", pal=pal, values=colorData, title=colorBy,
                layerId="colorLegend")
  })

  # Show a popup at the given location
  showZipcodePopup <- function(row, lat, lng) {
    selectedZip <- zipdata[zipdata$latitude == lat & zipdata$longitude == lng,]
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
