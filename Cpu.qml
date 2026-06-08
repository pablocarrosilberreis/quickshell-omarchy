// cpu: static glyph button (waybar shows icon only). Opens btop / terminal.
BarButton {
  text: Glyphs.cpu
  pad: 7
  leftCmd: "omarchy-launch-or-focus-tui btop"
  rightCmd: "alacritty"
}
