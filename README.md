# 🔇 Shush

> A chat silencer for World of Warcraft: Wrath of the Lich King (3.3.5a)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Filters](#filters)

Shush keeps the noise out of your chat. Silence messages by keyword, hide opposing-faction
chatter outside PvP zones, and check what got muted in a recently-silenced window.

## Features

- 🗯 **Keyword filter** – hide any message that contains a word or phrase from your list
- ⚔️ **Faction filter** – hide opposing-faction chatter in non-PvP zones
- 📜 **Recently silenced window** – see the last silenced messages with sender, reason and timestamp
- 🧩 **ElvUI aware** – the log window is skinned automatically when ElvUI is present
- ⚙️ Zero configuration to start – works out of the box, settings persist between sessions

## Installation

1. Copy the `Shush` folder to your `Interface\AddOns` directory:

   ```
   WoW/Interface/AddOns/Shush/
   ```

2. Restart the game client (or use `/reload`, if you have it).
3. Look for the load message in chat: **Shush loaded. Type /shush for help.**

> [!NOTE]
> ElvUI is an optional dependency. The addon works fine without it; ElvUI only improves the look of the log window.

> [!NOTE]
> Requires the WotLK 3.3.5a client (interface version 30300).

## Usage

All commands go through `|cff66ccff/shush|r`:

| Command | Description |
|---|---|
| `/shush` | Show help and current status |
| `/shush on \| off \| toggle` | Enable or disable all filtering |
| `/shush add <word or phrase>` | Silence messages containing this word or phrase |
| `/shush remove <word or phrase>` | Remove a word from the list (alias: `del`) |
| `/shush list` | Show all silenced words |
| `/shush log` | Open the recently silenced window |
| `/shush faction on \| off` | Toggle the opposing-faction filter |

### Examples

```
/shush add anal
/shush add gold prices
/shush list
/shush faction off
```

> [!TIP]
> Keywords are matched case-insensitively as plain substrings, so `anal` also silences `analysis`.
> Phrases are matched the same way — no regex, no escapes, and no need for quotes.

## Filters

### Keyword filter

Applies to say, yell, emote, channel and whisper messages from other players. Your own messages
are never filtered. Every matching message is hidden from chat and recorded in the
recently silenced window. The list is capped at the last 50 entries.

### Faction filter

Hidden players of the opposing faction say, yell, emote or use chat channels while you are in
a non-PvP area. Whispers are never filtered by faction, and inside PvP zones (battlegrounds,
arenas, hostile, contested or combat zones) the filter stays off so you can read enemy banter.

Both filters can be toggled independently — see [Usage](#usage).