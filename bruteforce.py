from datetime import datetime
from datetime import timedelta
import time
start = time.time()

# INPUT DATA
fly_from = "KRK" # city of departure
when = datetime.strptime('2019-02-04 10:25:00', '%Y-%m-%d %H:%M:%S') # date and time of departure
how_many_cities = 7
# how many cities in the path


results_list = []

class Airport:
    def __init__(self, iata, flights):
        self.iata = iata
        self.flights = flights


class Flight:
    def __init__(self, from_airport, to_airport, time, price):
        self.from_airport = from_airport
        self.to_airport = to_airport
        self.time = time
        self.price = price


class Graph:
    def __init__(self, airport_dictionary):
        self.airport_dictionary = airport_dictionary

    def get_airport(self, iata):
        airport = self.airport_dictionary[iata]
        return airport


def run(departure_airport, previous_airport, steps, path, previous_flight_date):
    if steps == 0:
        iata_from = path[0].from_airport.iata
        iata_to = path[how_many_cities - 1].to_airport.iata
        if iata_from == iata_to:
            results_list.append(path)
            # print("Kornik")
        return path
    for current_flight in departure_airport.flights:
        next_not_previous = previous_airport is None or previous_airport.iata != current_flight.to_airport.iata
        one_day_difference_at_least = previous_flight_date + timedelta(days=1) < current_flight.time

        prev = previous_flight_date
        prev_plus_2 = previous_flight_date + timedelta(days=2)
        current_flight_time = current_flight.time

        two_days_difference_the_most = prev_plus_2 > current_flight.time
        if next_not_previous and one_day_difference_at_least and two_days_difference_the_most:
            new_path = path.copy()
            new_path.append(current_flight)
            run(current_flight.to_airport, departure_airport, steps - 1, new_path, current_flight.time)


with open('out.txt') as f:
    content = f.readlines()
content = [x.strip() for x in content]

graph = Graph(airport_dictionary={})

for line in content:
    line = line.split(";")
    airport = Airport(iata=line[0], flights=[])
    graph.airport_dictionary[airport.iata] = airport

# print(len(graph.airport_dictionary))
i = 0
for line in content:
    line = line.split(";")
    airport_from = graph.airport_dictionary[line[0]]
    departure_time = datetime.strptime(line[2], ' %Y-%m-%d %H:%M:%S')
    if line[1][1:] in graph.airport_dictionary and departure_time > when:
        airport_to = graph.airport_dictionary[line[1][1:]]
        price = line[3]
        i = i + 1
        flight = Flight(from_airport=airport_from, to_airport=airport_to, time=departure_time, price=price)
        airport_from.flights.append(flight)
# print(i)
starting_airport = graph.get_airport(fly_from)
run(departure_airport=starting_airport, previous_airport=None, steps=how_many_cities, path=[],
    previous_flight_date=when)

price_dict = {}
min_price=10000

for result in (results_list):
    p = 0
    for flight in result:
        p = p + int(flight.price)
        # Trips one by one:
        # print(
        #     str(flight.from_airport.iata) + ">" + str(flight.to_airport.iata) + " " + str(flight.price) + " Eur " + str(
        #         flight.time))
    # print("Full price = " + str(p))
    # print("-" * 10)
    if p < min_price:
        min_price = p
        optimum = result
print("The cheapest trip costs: " + str(min_price))
for flight in optimum:
    print(str(flight.from_airport.iata) + ">" + str(flight.to_airport.iata) + " " + str(flight.price) + " Eur " + str(
        flight.time))


end = time.time()
print(end - start)