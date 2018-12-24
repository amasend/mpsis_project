import pandas as pd
import sys

with open('/home/shiny/graf_err', 'w') as f:
	f.write('clear')


#data = pd.read_csv("data/dane.csv", delimiter=";", names=["From", "To", "year", "month", "day", "Time", "Cost", "From_latitude", #									"From_longitude","To_latitude", 
#								"To_longitude", "name", "To_city", "To_airport_name"])
data = pd.read_csv("data/dane_v2.csv", delimiter=";", names=["From", "To", "year", "month", "day", "Time", "Cost", "From_latitude", 									"From_longitude","To_latitude", "To_longitude", "From_city", "From_airport_name", "To_city", "To_airport_name"])

data = data.drop(['Time', "From_city", "From_airport_name", "To_city", "To_airport_name"], axis=1)

# data cleaning
data["To"] = data["To"].str.strip()

#data['year'] = [int(i[0].split("-")[0]) for i in data['Date'].str.split()]
#data['month'] = [int(i[0].split("-")[1]) for i in data['Date'].str.split()]
#data['day'] = [int(i[0].split("-")[2]) for i in data['Date'].str.split()]
#data['hour'] = [int(i[1].split(":")[0]) for i in data['Date'].str.split()]
#data['minute'] = [int(i[1].split(":")[1]) for i in data['Date'].str.split()]
#data['second'] = [int(i[1].split(":")[2]) for i in data['Date'].str.split()]
#data = data.drop(["Date"], axis=1)

# LabelEncoder -> changes categorical data into numerical
from sklearn import preprocessing
le = preprocessing.LabelEncoder()
labels = data['To'].tolist()
labels = labels + data['From'].tolist()
labels = list(set(labels))
le.fit(labels)
data['From_edge'] = le.transform(data['From'])
data['To_edge'] = le.transform(data['To'])

max_cost = int(sys.argv[1])
max_cities = int(sys.argv[2])
time_in_citie_in_days = int(sys.argv[3])
start_citie = sys.argv[4]
year = int(sys.argv[5])
month = int(sys.argv[6])
day = int(sys.argv[7])

data['route_id'] = data.index

def remove_duplicate_route(data):
    for i in data:
        x = i[3:]+i[:3]
        if x in data:
            data.remove(x)
lista = list(set((data['From'] + data['To']).tolist()))
remove_duplicate_route(lista)

# check if there is any route from start city on particular day
if data.loc[(data['From'] == start_citie) & (data['year'] == year) & (data['month'] == month) & (data['day'] == day) & (data['Cost'] <= max_cost)].shape[0] == 0:
    exit(-1)

# add route_id
for i, z in enumerate(lista):
    data.loc[(data['From'] == z[:3]) & (data['To'] == z[3:]), ['route_id']] = i
    data.loc[(data['From'] == z[3:]) & (data['To'] == z[:3]), ['route_id']] = i
# create dataframe only with start city and all the connections from it
stage_1 = data.loc[(data['From'] == start_citie) & (data['year'] == year) & (data['month'] == month) & (data['day'] == day) & (data['Cost'] <= max_cost)]

# create rest dataframes (with transit cities)
stages = [stage_1]
for stage in range(max_cities-1):
    day = day+time_in_citie_in_days
    stages.append(data.loc[(data['From'].isin(stages[-1]['To'].values)) & ~(data['route_id'].isin(stages[-1]['route_id'].values)) & (data['To'] != start_citie) & (data['year'] == year) & (data['month'] == month) & (data['day'] == day) & (data['Cost'] <= max_cost)])
    
    for i in range(len(stages)-1):
        stages[-1] = stages[-1].loc[(~stages[-1]['route_id'].isin(stages[i]['route_id'].values))]
stages.append(data.loc[(data['From'].isin(stages[-1]['To'].values)) & (data['To'] == start_citie) & (data['year'] == year) & (data['month'] == month) & (data['day'] == day+time_in_citie_in_days) & (data['Cost'] <= max_cost)])

# make correction to cities numbers (ogolnie powinno byc bardziej From_vertex, To_vertex)
import numpy as np
tmp = 0
err = 0
for i, stage in enumerate(stages):
    if i != 0:
        err = tmp - np.max(stages[i-1]['From_edge'])
        stage['From_edge'] = le.transform(stage['From'].tolist())
        stage['From_edge'] += (np.max(stages[i-1]['From_edge']) + 1 + err)
        stage['To_edge'] = le.transform(stage['To'].tolist())
        stage['To_edge'] += (np.max(stages[i-1]['To_edge']) + 1)
        tmp = np.max(stages[i-1]['To_edge'])
        stages[i] = stage
    else:
        stage['From_edge'] = 0
        stage['To_edge'] = le.transform(stage['To'].tolist())
        stage['To_edge'] += 1
        stages[i] = stage

# set index numbers as link numbers
length = 0
for i, stage in enumerate(stages):
    if i == 0:
        stage.index = stage.reset_index().drop(['index'], axis=1).index + 1
        length = len(stage)
    else:
        stage.index = stage.reset_index().drop(['index'], axis=1).index + 1 + length
        length = length + len(stage)

import pickle
filename = '/home/shiny/stages'
pickle.dump(stages, open(filename, 'wb'))

s = list()
for stage in stages:
	s.append(stage.drop(["From_latitude", "From_longitude", "To_latitude", "To_longitude"], axis=1))
stages = s

try:
	stages[-1]['To_edge'].iloc[0]
except IndexError as e:
	print("Cannot compute the graph, there are no flights at this time from particular airport!")
	with open('/home/shiny/graf_err', 'w') as f:
		f.write('Cannot compute the graph, there are no flights at this time from particular airport!')
	exit(-1)

with open("/home/shiny/data.dat", "w") as f:
    f.write("""
data;

param V_count := {V_count};
param E_count := {E_count};
param D_count := {D_count};

param : h  s t :=
 1      1 {s} {t}
;
	""".format(V_count=stages[-1]['To_edge'].iloc[0], 
	           E_count=stages[-1].tail(1).index.values[0], 
	           D_count=1, 
	           s=0, 
	           t=stages[-1]['To_edge'].iloc[0]))

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
param : A :=
""")

with open("/home/shiny/data.dat", "a") as f:
    for stage in stages:
	for val, index in zip(stage.values, stage.index.values):
	    f.write("""
 {link_number},{to_edge_number}    1
""".format(link_number=index, 
	   to_edge_number=val[-3]))

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
;
""")

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
param : B :=
""")

with open("/home/shiny/data.dat", "a") as f:
    for stage in stages:
	for val, index in zip(stage.values, stage.index.values):
	    f.write("""
 {link_number},{to_edge_number}    1
""".format(link_number=index, 
	   to_edge_number=val[-2]))

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
;
""")

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
param : KSI :=
""")

with open("/home/shiny/data.dat", "a") as f:
    for stage in stages:
	for val, index in zip(stage.values, stage.index.values):
	    f.write("""
 {link_number}    {cost}
""".format(link_number=index, 
	   cost=val[5]))

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
;
""")

with open("/home/shiny/data.dat", "a") as f:
     f.write("""
end;
""")

