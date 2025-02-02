import "../css/app.css";

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

document.addEventListener("DOMContentLoaded", () => {
  const inspectors = document.querySelectorAll(".hover-inspector");

  inspectors.forEach((inspector) => {
    inspector.addEventListener("mousemove", (event) => {
      // Where do we want the tooltip?
      // For a small offset, say +15 on the X, +15 on the Y:
      const x = event.clientX + 15;
      const y = event.clientY - 15;

      // Update the element’s style for the `::after` position
      inspector.style.setProperty("--tooltip-left", `${x}px`);
      inspector.style.setProperty("--tooltip-top", `${y}px`);
    });
  });
});
