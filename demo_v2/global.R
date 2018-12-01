library(dplyr)

zipdata <- read.csv("data/flights.csv")
cityFrom <- read.csv("data/cityFrom.csv")
IANA_codes <- read.csv("IANA_codes_coordinates.csv")
zzz <- read.csv("data/dane.csv", sep=";", col.names = c("From", "To", "Date", "Price"))
