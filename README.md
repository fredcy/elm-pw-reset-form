# Password-change form in Elm

This elm-lang demo application shows how a legacy one-page form application can be converted to an Elm application.

The application reads data from the legacy form and hides it, passing that data to the Elm application that recreates the form. That application adds dynamic features to the form such as interactive evaluation of password strength using an external javascript module. When constraints are satisfied the user may submit the form which does a simple post back to the server. The server code is unchanged, except to add `script` elements to load the javascript for the app.

## Features ##

Scrape data from legacy form elements and pass to Elm application. (See `formInfo` in reset.js and Reset.elm).

Send data from Elm application to external javascript module and receive results from that. (See `pwChanges` and `pwStrength`).

Send focus requests from Elm application via Effects. (See `focus` port and `focusEffect` function passed to update function of sub-model).

## Files ##

### reset.html ###
The legacy page from the server, extended only to bring in the new javascript. This is the user's entry point.

### reset.js ###
This code sets up the connection between the legacy HTML page and the Elm `Reset` application.

### Reset.elm ###
This defines the main application, `Reset`. The Makefile compiles this into reset-elm.js.

### PasswordField.elm ###
This sub-model is used by Reset.elm to build the two password entry fields (main and confirmation).

### zxcvbn.js ###
This third-party code must be installed before running the app. See the Makefile.
