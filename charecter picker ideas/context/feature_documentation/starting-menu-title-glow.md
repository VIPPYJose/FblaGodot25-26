# Starting Menu Title Glow

The main menu title "Maplewood Mysteries" glows when the cursor hovers over it. The hovered character and a small number of neighbors get a golden outline and brighter text; the glow clears as soon as the cursor leaves the title.

---

## What it does

- Renders the title as one continuous line of text.
- On hover, the character under the cursor plus one character on each side (three characters total) get a glow: thicker golden outline and slightly brighter font color.
- When the cursor leaves the title, the glow is removed so no glow remains when the mouse is off the words.

---

## Where it lives

- **Scene:** `scenes/menu/starting_menu.tscn` — `TitleContainer` (MarginContainer) and its child `TitleHBox` (HBoxContainer). The title is built at runtime; the scene only provides the container.
- **Script:** `scripts/starting_menu.gd` — `_build_title_with_glow()`, `_on_title_char_hovered()`, `_on_title_char_exited()`, `_check_clear_glow()`, `_apply_glow()`, `_clear_title_glow()`.
- **Theme:** `resources/themes/title.tres` — used for each character label (font, size, default colors).

---

## How to use / key behavior

- **No setup:** The effect runs automatically when the starting menu loads.
- **Per-character hover:** Each character is a `Label` inside a `MarginContainer` wrapper. The wrapper has `mouse_filter = STOP` so it reliably receives hover; the label has `mouse_filter = IGNORE` so only the wrapper drives the effect.
- **Glow spread:** Controlled by `GLOW_SPREAD` (default `1`). The hovered index ± `GLOW_SPREAD` characters get the glow.
- **Leaving the title:** Each wrapper’s `mouse_exited` calls `_check_clear_glow()` (deferred). That checks whether the cursor is still over any wrapper; if not, it clears all glows so the title never stays glowing when the cursor is off the text.

---

## Customization

- **Spread:** Change `GLOW_SPREAD` in `starting_menu.gd` (e.g. `0` = only the hovered character, `2` = five characters).
- **Look:** Adjust `GLOW_OUTLINE_SIZE`, `GLOW_OUTLINE_COLOR`, and `GLOW_FONT_COLOR` in the same script.
- **Title text:** Change `TITLE_TEXT`; the same logic applies to the new string.

---

## Notes

- Hover is implemented with wrapper controls because `mouse_entered` / `mouse_exited` on `Label` alone can be unreliable in some Godot versions.
- Clearing uses a deferred check so the mouse position is correct after the exit event.
