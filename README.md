# Password-change form in Elm

This elm-lang demo application shows how a legacy one-page form application can be converted to an Elm application.

The application reads data from the legacy form and hides it, passing that data to the Elm application that recreates the form. That application adds dynamic features to the form such as interactive evaluation of password strength using an external javascript module. When constraints are satisfied the user may submit the form which does a simple post back to the server. The server side code is unchanged.

## Features ##

Scrape data from legacy form elements and pass to Elm application. (See `formInfo` in reset.js and Reset.elm).

Send data from Elm application to external javascript module and receive results from that. (See `pwChanges` and `pwStrength`).

Send focus requests from Elm application via Effects. (See `focus` port and `focusEffect` function passed to update function of sub-model).
