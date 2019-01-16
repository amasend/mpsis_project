'''
python debug.py > output.txt

    logika:
Pobieramy loty dla każdego lotniska(IATA) dla każdego dnia w przedziale <start date, end date>. Limit 90 euro za bilet.

    Przykładowy GET:
https://api.skypicker.com/flights?flyFrom=KRK&dateFrom=10/01/2019&dateTo=10/01/2019&partner=picky&currency=EUR&price_to=90
Jak się wklei tego URLa w przeglądarkę, to można sobie stukturę responsa podejrzeć -> mogę inaczej dane sformatować. Narazie jest tak:
IATA lotniska z; IATA lotniska do; data i godzina wylotu; cena w €
'''

import requests
from datetime import timedelta, date
import time
import datetime
import json


# with open('airports.json') as json_data:
#     airports = json.load(json_data)
#     print(airports[0]['iata'])
# def function(json_object, iata):
#     return [obj['name'] for obj in json_object if obj['iata'] == iata]

# print(function(airports, "YNJ"))
# print("------------")

def daterange(start_date, end_date):
    for n in range(int((end_date - start_date).days)):
        yield start_date + timedelta(n)


def prepare_list_of_iatas():
    with open('iata.txt') as f:
        content = f.readlines()
    content = [x.strip() for x in content]
    return content


def get_name_by_iata(iata_code):
    url = "https://api.skypicker.com/locations?term=" + iata_code + "&locale=en-US&location_types=airport&limit=10&active_only=true&sort=name"
    data = requests.get(url)
    json_data = json.loads(data.text)
    locations = json_data['locations']
    # city_name = locations[0]["city"]["name"]
    airport_name = locations[0]["name"]
    return airport_name


def iata_names_dict_prep(i_list):
    iata_dict = {}
    # print("Preparing dictionary of airports... hold on")
    for i_code in i_list:
        try:
            iata_dict[i_code] = get_name_by_iata(i_code)
        except:
            print("EXCEPTION!")
    # print("done")
    return iata_dict


iata_list = prepare_list_of_iatas()
start_date = date(2019, 2, 1)
end_date = date(2019, 2, 20)

iata_names_dictionary = iata_names_dict_prep(iata_list)
for iata_code in iata_list:
    url_fly_from = "?flyFrom=" + iata_code
    fly_from = iata_names_dictionary[iata_code]
    # fly_from = get_name_by_iata(iata_code)
    for single_date in daterange(start_date, end_date):
        try:
            date = single_date.strftime("%d/%m/%Y")
            url_date_from = "&dateFrom=" + date
            url_date_to = "&dateTo=" + date
            url = "https://api.skypicker.com/flights" + url_fly_from + url_date_from + url_date_to + "&price_to=90" + "&partner=picky&currency=EUR&directFlights=1"
            # print(url)
            data = requests.get(url)
            json_data = json.loads(data.text)
            flights = json_data['data']
            for each in flights:
                departure_time = (datetime.datetime.fromtimestamp(each['dTime']))
                if each['flyTo'] in iata_list:
                    print(each['flyFrom'] + "; " + each['flyTo'] + "; " + str(departure_time) + "; " + str(
                        each['price']) + "; " + str(each["route"][0]['latFrom']) + "; " + str(
                        each["route"][0]['lngFrom']) + "; " + str(each["route"][0]['latTo']) + "; " + str(
                        each["route"][0]['lngTo']) + "; " + each['cityFrom'] + "; " + fly_from + "; " + each[
                              'cityTo'] + "; " + iata_names_dictionary[each['flyTo']])
        except:
            print("EXCEPTION!")
        time.sleep(1)
