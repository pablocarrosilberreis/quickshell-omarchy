# QuickShell bar for Omarchy

A custom top bar built with [QuickShell](https://quickshell.outfoxxed.me/) (QML) that replaces Waybar on [Omarchy](https://omarchy.org/). Colors hot-load from the active Omarchy theme — no restart needed when you run `omarchy theme set`.

## Modules

| Widget | Interación |
|---|---|
| Omarchy menu | clic — abre el menú de Omarchy |
| Workspaces | muestra los workspaces activos de Hyprland |
| Active window | título de la ventana activa |
| Media player | hover → popup con controles, progreso y carátula |
| Volume | clic → selector de dispositivos de audio |
| Network | clic → selector de redes WiFi |
| Bluetooth | clic → selector de dispositivos BT |
| CPU / RAM | clic → popup de recursos del sistema |
| Battery | con indicador de estado de carga |
| Keyboard layout | clic → picker de layout |
| Clock | hover → calendario mensual |
| Notification center | toasts y centro de notificaciones |

## Requisitos

- [Omarchy](https://omarchy.org/) instalado y funcionando
- `quickshell` (AUR: `quickshell-git`) — el script de instalación lo instala automáticamente si falta
- `JetBrainsMono Nerd Font` — ya incluida en Omarchy

Dependencias de runtime de los widgets (presentes en una instalación estándar de Omarchy):

- `python3` — scripts de sysinfo / audio / wifi
- `playerctl` — controles del reproductor multimedia
- `nmcli` (NetworkManager) — red / WiFi
- `bluetoothctl` (bluez) — Bluetooth
- `pactl` / `pamixer` (PipeWire/Pulse) — volumen y dispositivos de audio
- `jq` — parseo de layout de teclado y otros
- `hyprctl` — workspaces y ventana activa

> Las temperaturas se leen directamente de sysfs (`/sys/class/hwmon`), sin depender de `lm_sensors`.

## Instalación

```bash
git clone https://github.com/pablocarrosilberreis/quickshell-omarchy.git ~/.config/quickshell
cd ~/.config/quickshell
bash install.sh
```

Luego cierra sesión y vuelve a entrar (o reinicia Hyprland con `omarchy reload`).

Para iniciar sin reiniciar:

```bash
uwsm-app -- qs &
```

## Qué hace el script

1. Instala `quickshell-git` desde AUR si no está presente (requiere `yay` o `paru`)
2. Instala los scripts empaquetados de `bin/` (sysinfo, audio, wifi, bluetooth, weather, teclado) en `~/.local/bin/`
3. Crea los helpers `omarchy-toggle-quickshell` y `omarchy-restart-quickshell` en `~/.local/bin/`
4. Crea el toggle `~/.local/state/omarchy/toggles/waybar-off` para suprimir Waybar
5. Añade `o.launch_on_start("qs")` a `~/.config/hypr/autostart.lua`
6. Reapunta `Super+Shift+Space` a `omarchy-toggle-quickshell` en `bindings.lua`

> Waybar **no se borra** — puedes revertir en cualquier momento (ver abajo).

## Atajos

| Atajo | Acción |
|---|---|
| `Super+Shift+Space` | Toggle visibilidad de la barra |

Scripts disponibles:

```bash
omarchy-toggle-quickshell   # toggle rápido (equivalente al atajo)
omarchy-restart-quickshell  # matar y relanzar qs
```

## Temas

Los colores se leen automáticamente desde:

```
~/.config/omarchy/current/theme/quickshell.json
```

Formato esperado (lo generan los temas de Omarchy):

```json
{
  "primary": "#78824b",
  "background": "#222222",
  "backgroundText": "#c2c2b0"
}
```

Al hacer `omarchy theme set <tema>` los colores se actualizan en vivo.

## Desinstalar

Detiene QuickShell, elimina los archivos y deja el sistema como estaba:

```bash
# 1. Detener QuickShell
pkill -x qs 2>/dev/null; pkill -x quickshell 2>/dev/null

# 2. Eliminar la config y los scripts helper
rm -rf ~/.config/quickshell
rm -f ~/.local/bin/omarchy-toggle-quickshell
rm -f ~/.local/bin/omarchy-restart-quickshell

# 3. Eliminar la línea de autostart
sed -i '/launch_on_start.*"qs"/d' ~/.config/hypr/autostart.lua
sed -i '/QuickShell bar.*replaces waybar/d' ~/.config/hypr/autostart.lua

# 4. Eliminar el bloque de keybindings de QuickShell
sed -i '/-- QuickShell bar overrides/,/SUPER + SHIFT + CTRL + RIGHT/d' ~/.config/hypr/bindings.lua
```

Luego reactiva Waybar (ver siguiente sección) y recarga Hyprland.

## Revertir a Waybar

Si solo quieres volver a Waybar sin desinstalar QuickShell:

```bash
# Reactiva Waybar (elimina el toggle waybar-off)
omarchy toggle waybar-off

# Detiene QuickShell
pkill -x qs

# Recarga Hyprland para que waybar arranque
omarchy reload
```

## Estructura

Consolidado en 14 archivos QML (Quickshell auto-descubre cada `.qml` como tipo
del módulo `qs`; no hay `qmldir` manual). Widgets, popups y primitivas viven como
**inline components** (`component X: ...`) dentro de pocos archivos. Los singletons
son piso fijo: `pragma Singleton` es por archivo, no se pueden fusionar.

```
~/.config/quickshell/
├── shell.qml              # raíz: paneles por monitor + ventanas de popups + toasts
│                          #   + PopupPanel/PopupFrame como inline components
├── Bar.qml                # barra + los 16 widgets + BarButton/Tooltip/Bubble (inline)
├── Popups.qml             # los 6 popups + sus filas/secciones (inline planos);
│                          #   referenciados desde shell.qml como Popups.<Nombre>
├── Poll.qml               # util compartida (one-shot command → stdout); la usan singletons y barra
├── *State.qml             # singletons de estado: Wifi/Bluetooth/Audio/KbLayout/SysInfo/Calendar/MediaPlayer/Notif
├── Theme.qml              # singleton: colores y fuente del tema activo
├── Glyphs.qml             # singleton: iconos Nerd Font
├── assets/
│   └── omarchy-mark.png   # logo para el menú (el glyph no renderiza en Qt)
├── bin/                   # scripts helper empaquetados (se instalan en ~/.local/bin)
├── install.sh             # script de instalación
└── kb_favorites.json      # layouts de teclado favoritos
```

## Gotchas de QuickShell 0.3.0

- `Variants` delegate requiere estar envuelto en `Component {}`
- No nombrar propiedades `state` (es una propiedad interna de `Item`)
- Correr scripts con `trap 'kill 0' EXIT` bajo `setsid` para que no maten el proceso de qs
- Tintear imágenes con `Image { layer.effect: MultiEffect }`, no `ColorOverlay`
- Los inline components (`component X: ...`) se declaran en el objeto raíz del
  archivo y **no se pueden anidar** uno dentro de otro: por eso en `Popups.qml`
  los popups y sus sub-filas están todos planos al mismo nivel
