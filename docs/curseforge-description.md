# WasteNot

**WasteNot** shows which of your known Cooking recipes use an item, right in its tooltip, so you stop vendoring meat and spices you could have cooked.

Open your Cooking window once and WasteNot remembers every recipe your character knows. From then on, hovering any item tells you what you can make with it, what else you need, and whether you're carrying enough.

## Features

- **Ingredient tooltips** — Hover a raw ingredient to see every known recipe that uses it, coloured by difficulty (orange / yellow / green / grey) just like the profession window
- **Food effects at a glance** — Each recipe shows a short summary of what the food does, e.g. `530 HP · +5 Agi`
- **Have / need counts** — Every ingredient is listed with how many you carry vs. how many the recipe needs, in green when you have enough and red when you don't
- **Cooked food tooltips** — Hover a food you know how to cook to see its ingredients and how many you can make right now
- **Per character** — Each character remembers its own recipes and updates automatically whenever you open Cooking or learn something new

## Getting Started

1. Install WasteNot
2. Open your Cooking window once on each character
3. Hover any item

## Slash Commands

| Command | Description |
|---------|-------------|
| `/wn` | How many recipes are cached and when they were last scanned |
| `/wn toggle` | Turn the tooltip lines on or off |
| `/wn effects` | Show or hide the food effect summary |
| `/wn reagents` | Show or hide the ingredient lines |
| `/wn lines <n>` | Maximum recipes listed per tooltip (default 6) |
| `/wn reset` | Clear this character's recipe cache |

## Notes

- Built for **World of Warcraft: Forever**
- Food effect summaries are read from English item text and won't appear on other client languages; everything else works in any language
