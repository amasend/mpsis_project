library(dplyr)

#zipdata <- read.csv("data/flights.csv")
zipdata <- read.csv("data/dane.csv", sep=";", col.names = c("From", "To", "Year", "Month", "Day", "Time", "Price", "From_latitude", "From_longitude",
                                                            "To_latitude", "To_longitude", "name", "To_city", "To_airport_name"))
cityFrom <- read.csv("data/cityFrom.csv")
IANA_codes <- read.csv("IANA_codes_coordinates.csv")
#zzz <- read.csv("data/dane.csv", sep=";", col.names = c("From", "To", "Date", "Price"))
airport_names <- unique(zipdata$name)
