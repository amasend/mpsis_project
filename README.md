# Flight_search
***Description***  
Application allowes user to find the best flight trip. (the best in the meaning of cost).
Some features need to be implemented. Application is under development.

# Usage
App is inside of docker contener.
Download contener and run it by typing:  
docker run -p 3838:3838 amasend/shinyapp:version5  
Then go to:  
http://localhost:3838/mpsis_project/demo_v5/  
App should load to your browser.

***Project done in Shiny.***
1. User can specify departure airport.
2. User can specify start search date.
3. Maximum overall price for entire trip. (user can change this value any time, without need of fetching additional data)
4. Compute best route based on GMPL linear programming (SYMPLEX algorithm)


***Map description***
1. Circles - airports
2. Size of a circle - (bigger - bigger cost, lower - lower cost) from current home airport
3. Colour of a cirlce - (Red - cost above user maximum cost, Blue - cost below user maximum cost specified)
4. When you clicked on a circle - user can see actual flight cost (from home airport to clicked one), it also displays airport town name
