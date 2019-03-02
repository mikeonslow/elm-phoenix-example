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
        var app = Elm.Main.init({
            node: document.getElementById('elm-main')
        });

        app.ports.channelEventRequest.subscribe((request) => {
            channel.push(request.event, request.payload);
        });

        let channel = socket.channel("portfolio:lobby", {});

        channel.join()
            .receive("ok", resp => { console.log("Joined successfully", resp) })
            .receive("error", resp => { console.log("Unable to join", resp) });

        channel.on("get_items", payload => {
            console.log("get_items response");
            app.ports.channelEventResponse.send(payload);
        })
    }

    window.addEventListener('load', startup, false);
}());