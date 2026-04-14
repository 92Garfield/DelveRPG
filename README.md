# DelveRPG

**An ARPG-style HUD that makes delving feel more like an actual adventure.**

In delves you gather a couple of things that are not portrayed nicely in the default UI as you make progress: XP, Boons and gold at least. DelveRPG adds a small HUD that tracks these things in a way that makes them feel more rewarding and satisfying to earn. The HUD is designed to be simple and unobtrusive, but also visually appealing and informative.

## Features

- **Companion XP** — Shows Valeera's level as a progress bar. Each time she earns XP the bar smoothly fills and a floating `+XP` label pops off it. The current level label, the raw fraction and a running total of XP earned this delve are shown so you always know how close the next level is.
- **Boons** — Tracks the stacking Boons buff received from the blue bags (which also contain a big amount of XP for Valeera). Whenever a stat ticks up, the value counts up in real time and a floating gain label pops off the panel.
- **Gold Gained** — Keeps a simple running total of gold earned since you entered the delve. Resets automatically on each new run.

## Configuration

Open the options panel via **ESC → Interface → AddOns → DelveRPG**.

- **Enable HUD** — Master on/off toggle
- **Show Only in Delves** — Suppresses the HUD and all event handling when outside a delve
- **HUD Scale** — Scale the entire overlay (0.5 – 2.0)
- **Position X / Y** — Offset from screen centre
- **Companion Faction ID** — Friendship faction ID for the companion XP bar
- **Reset Gold Counter** — Resets the gold baseline to now

## Slash Commands

| Command | Description |
|---|---|
| `/drpg` | Toggle the HUD |
| `/drpg show` / `/drpg hide` | Force show or hide |
| `/drpg config` | Open the options panel |
| `/drpg reset` | Reset the gold counter |
| `/drpg refresh` | Force-refresh all displays |
| `/drpg help` | List all commands |

Alias: `/delve` works the same as `/drpg`.

## Libraries Used

- LibStub
- CallbackHandler-1.0
- AceAddon-3.0
- AceDB-3.0
- AceConsole-3.0
- AceEvent-3.0
- AceGUI-3.0
- AceConfig-3.0

## Author

**Demonperson** (a.k.a. 92Garfield)

https://raider.io/characters/eu/blackmoore/Demonperson

## License

MIT — see [LICENSE](LICENSE)
