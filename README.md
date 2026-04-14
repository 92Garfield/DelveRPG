# DelveRPG

An ARPG-style HUD for World of Warcraft that makes delving feel more like an actual adventure.

Delves reward you with Companion XP, stacking Boons and gold — but none of that is shown in a satisfying way by the default UI. DelveRPG adds a small, draggable overlay that tracks all three with animated bars, floating gain labels and live count-up numbers.

## Features

- **Companion XP Bar** — Tracks Brann's friendship progression with a smooth animated fill. Shows the current level, XP fraction, and total XP earned this delve. A floating `+XP` label pops off the bar on each gain.
- **Boon Display** — Reads the stacking Boons buff and shows every active stat bonus (Max HP, Main Stat, Haste, Crit, etc.) in a compact 2-column grid. Only non-zero stats are shown; the panel grows and shrinks dynamically. Values count up in real time on change.
- **Gold Gained** — Tracks total gold earned since entering the delve. Resets automatically on each new run. Counts up with a floating gain label on each tick.

## Configuration

Open the options panel via **ESC → Interface → AddOns → DelveRPG**, or type `/drpg config`.

- **Enable HUD** — Master on/off toggle
- **Show Only in Delves** — Suppresses the HUD and all event handling when outside a delve
- **HUD Scale** — Scale the entire overlay (0.5 – 2.0)
- **Position X / Y** — Offset from screen centre
- **Companion Faction ID** — Defaults to 2744 (Brann Bronzebeard)
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
