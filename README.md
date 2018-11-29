# Flight_search

***Project done in Shiny.***
1. User can specify departure airport by putting IATA code of airport.
2. User can specify start search date and end search date (the time between dates is user trip time planned).
3. Maximum overall price for entire trip. (user can change this value any time, without need of fetching additional data)
4. Compute best route (partially implemented - only API updates from kiwi.com). Future release should implement GMPL
Linear Programming for compute best -> the lease cost EUR consuming trip.


***Map description***
1. Circles - airports
2. Size of a circle - (bigger - bigger cost, lower - lower cost) from current home airport
3. Colour of a cirlce - (Red - cost above user maximum cost, Blue - cost below user maximum cost specified)
4. When you clicked on a circle - user can see actual flight cost (from home airport to clicked one), it also displays airport town name
