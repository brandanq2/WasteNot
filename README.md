# WasteNot

A World of Warcraft: Forever addon that tells you, right in an item's tooltip, which of your **known Cooking recipes** use it, so you stop vendoring meat you could have cooked.

Hovering an ingredient:

```
WasteNot
───
Used in
[icon] Crocolisk Gumbo                 530 HP · +5 Agi
      Tender Crocolisk Meat 20/1
      Hot Spices 0/1
```

Hovering a food you know how to cook:

```
WasteNot
───
Cooked from
      Tender Crocolisk Meat 20/1            Can make 3
      Hot Spices 3/1
```

- Recipe names are coloured by difficulty (orange / yellow / green / grey), matching the profession window.
- Each ingredient shows how many you carry vs. how many the recipe needs: green if you have enough, red if not.
- The food's effect (health restored and Well Fed buff) is summarised next to the recipe name. English clients only.

## Usage

1. Open your Cooking window once per character. WasteNot reads your known recipes and caches them, because the game only exposes recipe data while the window is open.
2. Hover any item. If one of your recipes uses it, you'll see it.

The cache refreshes whenever you open Cooking or learn a new recipe.

| Command | |
|---|---|
| `/wn` | Show how many recipes are cached and when |
| `/wn toggle` | Turn the tooltip lines on or off |
| `/wn effects` | Show or hide the food effect summary |
| `/wn reagents` | Show or hide the ingredient lines |
| `/wn lines <n>` | Maximum recipes listed per tooltip (default 6) |
| `/wn reset` | Clear the cache for this character |

## Releasing

Pushing a `v*` tag runs `.github/workflows/release.yml`, which:

1. stamps the version into `WasteNot.toc` (replacing `@project-version@`);
2. zips `WasteNot/` and publishes a GitHub release with a changelog built from commits since the previous tag;
3. uploads the zip to CurseForge, tagged for the game version that matches `## Interface:` (16001 → `1.60.1`, WoW: Forever).

Tags containing `alpha` or `beta` (e.g. `v0.2.0-beta.1`) are uploaded with that release type.

Required repo secrets: `CF_API_KEY` (from <https://legacy.curseforge.com/account/api-tokens>) and `CF_PROJECT_ID` (shown on the CurseForge project page). If the workflow can't find the Forever version type by name, set the repo variable `CF_GAME_VERSION_TYPE_ID` to pin it.

```sh
git tag v0.1.0
git push origin v0.1.0
```

## Development

Symlink or copy `WasteNot/` into `World of Warcraft/_forever_/Interface/AddOns/`, then `/reload` in-game.
