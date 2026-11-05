# Changelog

## [0.3.0] (2026-11-05)
### Added
- **List Grouping & Logical Sorting:**
  - Switchable grouping inside `ClickBindingFrame` via the header selector pill (`Group: Modifier`) or the Settings menu: group by **Modifier** (`Direct Click`, `Shift + Click`, `Ctrl + Click`, `Alt + Click`), **Mouse Button** (`LMB`, `RMB`, `MMB`, `MB4+`), **Action Type** (`Spells`, `Pet Actions`, `Macros`), or **Off** (flat list with logical mouse-button and modifier sorting).
- **1-Click Direct Bind in Spellbook:**
  - Added a `"1-Click Direct Bind"` pill checkbox at the bottom-left of `SpellBookFrame` while `ClickBindingFrame` is open, allowing any mouse button (including `LMB`, `RMB`, `MMB`, `MB4+`, and `Shift/Ctrl/Alt` modifiers) to bind spells in a single click.
- **Persistent Spellbook Key Badges:**
  - Bound key badges (`LMB`, `RMB`, `MMB`, `S-LMB`, `MB4`, `MB5`) and tooltip lines now remain visible in the Spellbook at all times (even when `ClickBindingFrame` is closed) using `C_ClickBindings.GetProfileInfo()`.
- **Modernized Integrated Buttons:**
  - Upgraded the inline rank switcher (`92x22`), the permanently visible row delete button, the `"Group: ..."` header selector, the Spellbook `"1-Click Direct Bind"` bar, and Spellbook key badges with Blizzard's dark/gold rounded pill atlases (`common-dropdown-c-button`, `common-dropdown-a-button`).
  - Added a native gear badge (`questlog-icon-setting`) to the circular settings portrait button inside `ClickBindingFrame`.
- **Minimap Button & Addon Compartment:**
  - Uses Blizzard's native `clickcast-icon-mouse` atlas for crisp, mipmapped in-game rendering.
  - Left-Click to directly open/close Blizzard's native Click Cast Bindings window (`ClickBindingFrame`).
  - Right-Click to open the Better Click Casting Settings menu.
  - Freely draggable around the Minimap (`BetterClickCastingDB.minimapAngle`) plus `/bcc` and `/bcc minimap` slash commands.
- **Native Settings Button inside `ClickBindingFrame`:**
  - Added a circular settings portrait button right next to the Macro and Spellbook buttons at the top right of `ClickBindingFrame`.
  - Live toggles for: Rank in Name, `[MAX]` & Downrank Highlighting, Inline Rank Switcher, Full Tooltips, 1-Click Spellbook Quick-Binding, Spellbook Key Badges, Auto-Enable *"Show All Spell Ranks"* while Click Binding is open, and Minimap Button visibility.
  - **1-Click Action:** *"Upgrade All Bound Spells to MAX Rank"* directly from the settings menu.

## [0.2.0] (2026-11-05)
### Added
- **Inline Rank Switcher:** Switch between all learned ranks of a bound spell directly inside the Click Cast Bindings list via Left-Click dropdown (with mana costs and tooltips), Right-Click (instant upgrade to MAX rank), or Mouse Wheel scrolling without re-binding the mouse button.
- **Max-Rank & Downrank Detection:** Clearly distinguishes between your highest learned rank (`[MAX]`) and lower ranks (`Rank X / Max Y`).
- **Full Row Tooltips:** Hovering any spell, pet action, or macro in `ClickBindingFrame` displays the full rank-accurate spell tooltip or macro body.
- **Spellbook Quick-Binding:** Clicking a spell in the Spellbook while in Click Binding mode always adds/fills a slot automatically without having to click *"Add Binding"* first.
- **Spellbook Key Badges:** Displays the bound mouse button shorthand (`M1`, `S-M2`, etc.) directly on bound spell ranks in the Spellbook.
- **Localization & Modular Architecture:** Full `enUS` (default fallback) and `deDE` localization with modular `Core/`, `Locales/`, and `Modules/` structure.

## [0.1.0] (2026-11-05)
### Added
- Initial release displaying spell ranks (`C_Spell.GetSpellSubtext`) in `ClickBindingFrame` rows, icon rank badges (`R1`, `R2`, ...), and unbound warning messages.
