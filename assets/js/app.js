// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
// import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"

import { Elm } from "../src/Main.elm";

(function () {
    var startup = function () {
        // Start the Elm App.

        var initialLikedItems = [];

        if (typeof localStorage.likedItems == 'string') {
            initialLikedItems = JSON.parse(localStorage.likedItems);
        }

        var app = Elm.Main.init({
            node: document.getElementById('elm-main'),
            flags: initialLikedItems
        });

        // Receive messages from Elm run-time through `channelEventRequest` port in Elm
        app.ports.channelEventRequest.subscribe((request) => {
            channel.push(request.event, request.payload);
        });

        // Receive messages from Elm run-time through `localStorageRequest` port in Elm
        app.ports.localStorageRequest.subscribe((request) => {
            if (request.value === null) {
                localStorage[request.method](request.key);
            } else {
                localStorage[request.method](request.key, JSON.stringify(request.value));
            }
            console.log("localStorageRequest", request, localStorage);
        });

        let channel = socket.channel("portfolio:lobby", {});

        channel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp); });

        channel.on("get_items", payload => {
            console.log("get_items response...");
            // Send the new list of portfolio items any time we receive `get_items` event from Phoenix. 
            // This will happen on both fetches (initiated through Elm) and updates to the data from outside sources (someone "liked" an item)
            app.ports.channelEventResponse.send(payload);
        });

        channel.on("like_item", payload => {
            console.log("like_item response", payload);
        });

        channel.on("phx_error", payload => {
            // Resets liked items when browser is disconnected from the socket (does not happen on a browser refresh or page navigation)
            // There are better ways to invalidate this cache but this was a simple way to cover a common case of the app 
            // being restarted/shut down while the user has the browser open
            localStorage.removeItem('likedItems');
            console.log("phx_error response", payload);
        });
    }

    window.addEventListener('load', startup, false);
}());