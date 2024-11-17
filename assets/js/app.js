// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import "flowbite/dist/flowbite.phoenix.js";
import ApexCharts from 'apexcharts';
import Datepicker from 'flowbite-datepicker/Datepicker';
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

window.addEventListener("phx:page-loading-start", () => {
    document.body.classList.add("loading");
});

window.addEventListener("phx:page-loading-stop", () => {
    document.body.classList.remove("loading");
    document.body.classList.add("loaded");
});
Hooks = {}

Hooks.Datepicker = {
    mounted() {
        const datepickerEl = this.el;
        new Datepicker(datepickerEl, {
            // options
        });
    },
    updated() {
        this.mounted();
    }
}

Hooks.DashboardChart = {
    mounted() {

        this.handleEvent("chart-data", (data) => this.renderChart(data));

    },
    renderChart(data) {
        console.log(data);
        const options = {
            series: data.series_data,
            chart: {
                stacked: true,
                stackType: "100%",
                sparkline: {
                    enabled: false,
                },
                type: "bar",
                width: "100%",
                height: 400,
                toolbar: {
                    show: false,
                }
            },
            fill: {
                opacity: 1,
            },
            plotOptions: {
                bar: {
                    horizontal: true,
                    columnWidth: "100%",
                    borderRadiusApplication: "end",
                    borderRadius: 6,
                    dataLabels: {
                        position: "top",
                    },
                },
            },
            legend: {
                show: true,
                position: "bottom",
            },
            dataLabels: {
                enabled: false,
            },
            tooltip: {
                shared: true,
                intersect: false,
            },
            xaxis: {
                labels: {
                    show: false,
                    style: {
                        fontFamily: "Inter, sans-serif",
                        cssClass: 'text-xs font-normal fill-gray-500 dark:fill-gray-400'
                    }
                },
                categories: data.categories,
                axisTicks: {
                    show: false,
                },
                axisBorder: {
                    show: false,
                },
            },
            yaxis: {
                labels: {
                    show: true,
                    style: {
                        fontFamily: "Inter, sans-serif",
                        cssClass: 'text-s font-normal fill-gray-500 dark:fill-gray-400'
                    }
                }
            },
            grid: {
                show: true,
                strokeDashArray: 4,
                padding: {
                    left: 2,
                    right: 2,
                    top: -20
                },
            }
          
        }

        if (document.getElementById("bar-chart") && typeof ApexCharts !== 'undefined') {
            const chart = new ApexCharts(document.getElementById("bar-chart"), options);
            chart.render();
        }
    }
}

let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })
// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

