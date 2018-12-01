import pandas as pd
import pickle
data = pd.read_csv("/home/shiny/file.txt", delimiter =";", names = ["Selected_airport"], index_col=0)
optimal_cost = data["Selected_airport"].iloc[0]
with open('/home/shiny/optimal_cost', 'w') as f:
    f.write(',\n{}'.format(optimal_cost))
data = data.drop([-1], axis=0)
data = data[data["Selected_airport"] == 1]
filename = '/home/shiny/stages'
stages = pickle.load(open(filename, 'rb'))
cords = pd.read_csv("IANA_codes_coordinates.csv", index_col=0)
with open("/home/shiny/coordinates.txt", 'w') as f:
    f.write("From,lat_from,lon_from,To,lat_to,lon_to\n")
    for i, stage in enumerate(stages):
        city_from = stage.loc[data.index[i]][0]
        city_to = stage.loc[data.index[i]][1]
        lat_from = cords[cords['code'] == city_from].values.tolist()[0][1]
        lon_from = cords[cords['code'] == city_from].values.tolist()[0][2]
        lat_to = cords[cords['code'] == city_to].values.tolist()[0][1]
        lon_to = cords[cords['code'] == city_to].values.tolist()[0][2]
        f.write("{},{},{},{},{},{}\n".format(city_from,lat_from,lon_from,city_to,lat_to,lon_to))

