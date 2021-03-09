// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";

import * as Turbo from "@hotwired/turbo";

import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

const application = Application.start();
const context = require.context("./controllers", true, /\.js$/);
application.load(definitionsFromContext(context));

window.onload = function () {
  let scrollTop = 0;

  addEventListener("turbo:click", ({ target }) => {
    if (target.hasAttribute("data-turbo-preserve-scroll")) {
      scrollTop = document.scrollingElement.scrollTop;
    }
  });

  addEventListener("turbo:load", () => {
    if (scrollTop) {
      document.scrollingElement.scrollTo(0, scrollTop);
    }

    scrollTop = 0;
  });

  tippy(".class");
};
