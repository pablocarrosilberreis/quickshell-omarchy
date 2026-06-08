// custom/weather: poll weather.sh (json {"text"}), hide when empty.
BarButton {
  id: root
  pad: 7
  leftCmd: "notify-send -u low \"$(omarchy-weather-status)\""

  Poll {
    interval: 60000
    command: ["omarchy-weather-bar"]
    onUpdated: (out) => {
      try { root.text = JSON.parse(out).text || "" }
      catch (e) { root.text = "" }
    }
  }
}
