# Better Click Casting

### 💬 The Backstory (or: Why This AddOn Exists)

Back in the Beta, I dutifully reported an issue for Blizzard's built-in **Click Cast Bindings** menu. Why? Because while the native Click Casting system itself is rock-solid, its UI was clearly copy-pasted straight from Retail, a magical place where **Spell Ranks** haven't existed for fifteen years.

Want to know if that `Flash Heal` in your list is Rank 1, Rank 4, or Rank 7? *Good luck guessing!*
Learned a new spell rank at your class trainer and want to upgrade your binding? *Have fun deleting the row, hunting down the spell in your Spellbook, and binding it all over again!*
Want to see a tooltip in the list to check mana costs? *Too bad!*

Sadly, the menu never got any love from Blizzard.
**Are you in the same boat as me? Then have fun with this AddOn!**

---

### ✨ What Better Click Casting Does (English)

**Better Click Casting** gives Blizzard's native Click Cast UI (`ClickBindingFrame`) and Spellbook (`PlayerSpellsFrame`) the Classic & *WoW Forever* upgrade it always deserved, while keeping 100% of Blizzard's secure, lightweight native system under the hood:

* **🪶 No Heavy Unitframes or Replacement AddOns Required:**
  * You no longer need to install heavyweight unitframe suites (like VuhDo, Cell, or HealBot) or separate click-casting replacements just to use Click Casting with proper Spell Ranks in Classic. Keep your lightweight native UI and raid frames while enjoying full downranking support!

* **🔍 Finally See Your Spell Ranks:**
  * Displays the exact bound rank right next to every spell name (e.g., `Flash Heal (Rank 4)`).
  * **Max-Rank & Downrank Detection:** Highlights spells at your highest learned rank with a green **`[MAX]`** tag, and marks lower ranks (whether intentional downranks or spells you forgot to upgrade after visiting the trainer) in orange with a max-rank hint like `(Rank 2 / Max 4)`.

* **⚡ Inline Rank Switcher (No More Re-Binding!):**
  * Adds a sleek rank button (`R2` / `R4 (Max)`) directly to every multi-rank spell row.
  * **Left-Click:** Opens a dropdown menu of all learned ranks, complete with mana/resource costs and full spell tooltips.
  * **Right-Click:** Instantly upgrades that binding to your highest learned rank (`MAX`).
  * *Best of all: Your assigned mouse button and modifiers stay completely untouched!*

* **🗂️ Clean Grouping & Logical Sorting:**
  * Tired of Blizzard's chaotic alphabetical button sorting?
  * Group your custom bindings by **Modifier** (`Direct Click`, `Shift + Click`, `Ctrl + Click`, `Alt + Click`), by **Mouse Button** (`LMB`, `RMB`, `MMB`, `MB4`, `MB5`), by **Action Type** (`Spells`, `Pet Actions`, `Macros`), or keep a flat list sorted in actual human mouse-button order.

* **📖 1-Click Direct Bind & Key Badges in the Spellbook:**
  * **1-Click Direct Bind:** Enable the *"1-Click Direct Bind"* checkbox at the bottom-left of your Spellbook while the Click Cast window is open. Click any spell in your Spellbook with **any** mouse button (`LMB`, `RMB`, `MMB`, `MB4+`, or `Shift/Ctrl/Alt + Click`) to bind it immediately in a single click.
  * **Persistent Key Badges:** Shows your bound mouse button shorthands (`LMB`, `RMB`, `MMB`, `S-LMB`, `MB4`) directly on the spell icons in your Spellbook at all times, plus full binding info in the Spellbook tooltip.
  * **Auto-Show All Spell Ranks:** Temporarily enables *"Show All Spell Ranks"* when you open the Click Cast window (and restores your setting when you close it).

* **📜 Full Row Tooltips & 1-Click Max Upgrade:**
  * Hover any row in the Click Cast list to see the full, rank-accurate spell tooltip or macro text.
  * Just visited the class trainer? Use the **"Upgrade All Bound Spells to MAX"** action in the settings menu to update your entire profile in one click.

* **🧭 Minimap Button & Slash Commands:**
  * **Left-Click** the Minimap icon (or type `/bcc`) to open Click Cast Bindings directly without digging through the ESC menu.
  * **Right-Click** the Minimap icon (or click the gear portrait button inside the Click Cast window) to customize every feature to your liking.

---

### 🇩🇪 Funktionen (Deutsch)

**Better Click Casting** erweitert Blizzards native **Klickbelegung** (`ClickBindingFrame`) und das **Zauberbuch** (`PlayerSpellsFrame`) um vollständige **Zauberrang-Unterstützung**, ohne Blizzards eigenes System durch ein schwergewichtiges Zweitsystem zu ersetzen:

* **Keine komplexen Unitframes oder Zusatz-AddOns nötig:**
  * Du brauchst keine schweren Heiler-Unitframes (wie VuhDo, Cell oder HealBot) mehr zu installieren, nur um Blizzards eingebautes Click-Casting sinnvoll mit Zauberrängen (Downranking) nutzen zu können.
* **Zauberränge direkt in der Liste:** Zeigt den gebundenen Rang direkt hinter dem Zaubernamen (z. B. `Blitzheilung (Rang 4)`).
* **Max-Rang- & Downrank-Erkennung:**
  * Markiert den höchsten gelernten Rang mit einem grünen **`[MAX]`**-Label.
  * Hebt niedrigere Ränge (Downranks oder nach dem Lehrer-Besuch veraltete Ränge) farblich in Orange hervor, inkl. Hinweis auf den höchsten gelernten Rang (`(Rang 2 / Max 4)`).
* **Direkter Rang-Wechsler in der Zeile (ohne Taste neu zu binden):**
  * **Linksklick auf den Rang-Button (`R2` / `R4 (Max)`):** Öffnet ein Dropdown-Menü mit allen gelernten Rängen inkl. Manakosten und Zauber-Tooltips.
  * **Rechtsklick auf den Rang-Button:** Stellt den Zauber sofort auf den höchsten gelernten Rang (`MAX`) hoch.
* **Gruppierung & Logische Sortierung:**
  * Gliedert eigene Klickbelegungen im Fenster wahlweise nach **Modifier** (`Direktklick`, `Shift + Klick`, `Strg + Klick`, `Alt + Klick`), **Maustaste** (`LMB`, `RMB`, `MMB`, `MB4+`), **Aktionstyp** (`Zauber`, `Begleiter-Aktionen`, `Makros`) oder als logisch sortierte Liste.
* **1-Klick Direkt-Binden & Tasten-Badges im Zauberbuch:**
  * Über die Checkbox *„1-Klick Direkt-Binden“* unten links im Zauberbuch (während die Klickbelegung offen ist) bindet jeder Klick auf einen Zauber im Zauberbuch (inkl. Linksklick `LMB`, Rechtsklick `RMB`, Mittelklick `MMB`, `MB4`, `MB5` sowie `Shift/Strg/Alt + Klick`) den Zauber sofort in 1 Schritt an diese Maustaste.
  * Bereits gebundene Ränge zeigen im Zauberbuch dauerhaft das Kürzel der zugewiesenen Maustaste (`LMB`, `RMB`, `MMB`, `S-LMB`, `MB4`).
* **Vollständige Zauber- & Makro-Tooltips:**
  * Beim Hovern über eine Zeile in der Klickbelegung wird der echte Zauber-Tooltip des jeweiligen Ranges bzw. der Makro-Inhalt angezeigt.
* **Minimap-Icon & Einstellungsmenü:**
  * Linksklick auf das Minimap-Icon (oder `/bcc`) öffnet direkt die Klickbelegung, Rechtsklick öffnet die AddOn-Einstellungen samt 1-Klick-Upgrade aller gebundenen Zauber auf `MAX`.

---

## 📄 License

Released under the [MIT License](./LICENSE).
