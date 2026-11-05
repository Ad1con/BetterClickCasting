local _, ns = ...

if GetLocale() ~= "deDE" then
	return
end

local L = ns.L

L["ADDON_TITLE"] = "Better Click Casting"
L["RANK_FALLBACK_FORMAT"] = "Rang %d"
L["TAG_MAX"] = "[MAX]"
L["TAG_MAX_SHORT"] = "Max"
L["MAX_RANK_HINT_FORMAT"] = " / Max %d"

-- Rang-Wechsler-Button und Kontextmenü
L["SELECT_RANK_TITLE_FORMAT"] = "%s: Rang wählen"
L["RANK_SWITCHER_TOOLTIP_TITLE"] = "Zauberrang wechseln"
L["RANK_SWITCHER_CURRENT_FORMAT"] = "Aktuell: %s (Max gelernt: %s)"
L["RANK_SWITCHER_HINT_LEFT"] = "• Linksklick: Alle gelernten Ränge auswählen"
L["RANK_SWITCHER_HINT_RIGHT"] = "• Rechtsklick: Sofort auf höchsten Rang (MAX) setzen"

-- Gruppierung und Sortierung im ClickBindingFrame
L["GROUP_BUTTON_FORMAT"] = "Gruppe: %s"
L["GROUP_MENU_TITLE"] = "Gruppierung & Sortierung"
L["GROUP_MODE_MODIFIER"] = "Nach Modifier (Direktklick / Shift / Strg / Alt)"
L["GROUP_MODE_MODIFIER_SHORT"] = "Modifier"
L["GROUP_MODE_BUTTON"] = "Nach Maustaste (LMB / RMB / MMB / MB4+)"
L["GROUP_MODE_BUTTON_SHORT"] = "Maustaste"
L["GROUP_MODE_TYPE"] = "Nach Aktionstyp (Zauber / Makros)"
L["GROUP_MODE_TYPE_SHORT"] = "Typ"
L["GROUP_MODE_NONE"] = "Flache Liste (Logische Sortierung LMB / RMB / MMB / MB4+)"
L["GROUP_MODE_NONE_SHORT"] = "Aus"
L["GROUP_TOOLTIP_TITLE"] = "Gruppierung & Sortierung"
L["GROUP_TOOLTIP_DESC"] = "Gliedert deine eigenen Klickbelegungen in übersichtliche Untergruppen und sortiert Maustasten in logischer Reihenfolge (Links, Rechts, Mitte, Maus 4+)."

L["GROUP_HDR_NO_MOD"] = "Direktklick (Ohne Modifier)"
L["GROUP_HDR_MOD_FORMAT"] = "%s + Klick"
L["GROUP_HDR_SPELLS"] = "Zauber"
L["GROUP_HDR_PET"] = "Begleiter-Aktionen"
L["GROUP_HDR_MACROS"] = "Makros"
L["GROUP_HDR_UNBOUND"] = "Nicht zugewiesen"

-- Zeilen-Tooltips im ClickBindingFrame
L["TOOLTIP_CLICK_BINDING_LABEL"] = "Klickbelegung:"
L["TOOLTIP_RANK_STATUS_LABEL"] = "Rang-Status:"
L["TOOLTIP_STATUS_MAX_RANK_FORMAT"] = "Höchster gelernter Rang (%s)"
L["TOOLTIP_STATUS_DOWNRANK_FORMAT"] = "Downrank (%s / Max: %s)"
L["TOOLTIP_SWITCH_RANK_HINT"] = "Tipp: Rang-Button rechts anklicken zum Wechseln des Ranges."

-- Zauberbuch-Tooltips und Checkbox
L["SPELLBOOK_ALREADY_BOUND_LABEL"] = "Klickbelegung:"
L["SPELLBOOK_QUICK_BIND_CHECKBOX"] = "1-Klick Direkt-Binden"
L["SPELLBOOK_QUICK_BIND_HINT"] = "Direkt-Binden aktiv: Klicke mit der gewünschten Maustaste (oder Shift/Strg/Alt + Klick) direkt auf diesen Zauber!"

-- Minimap-Button
L["MINIMAP_TOOLTIP_SUBTITLE"] = "Erweiterungen für die native Klickbelegung"
L["MINIMAP_HINT_LEFT"] = "• Linksklick: Klickbelegung öffnen / schließen"
L["MINIMAP_HINT_RIGHT"] = "• Rechtsklick: Better Click Casting Einstellungen"
L["MINIMAP_HINT_DRAG"] = "• Ziehen: Minimap-Icon verschieben"

-- Settings-Button und Menü
L["SETTINGS_BUTTON_TOOLTIP_TITLE"] = "Better Click Casting: Einstellungen"
L["SETTINGS_BUTTON_TOOLTIP_DESC"] = "Zauberrang-Anzeige, Gruppierung, Rang-Wechsler, Zauberbuch-Helfer und Minimap-Icon konfigurieren."
L["SETTINGS_MENU_TITLE"] = "Better Click Casting"
L["SETTINGS_HEADER_CLICKCAST"] = "Klickbelegungs-Fenster"
L["SETTINGS_HEADER_SPELLBOOK"] = "Zauberbuch-Integration"
L["SETTINGS_HEADER_GENERAL"] = "Allgemein & Aktionen"

L["SETTING_SHOW_RANK_IN_NAME"] = "Zauberrang im Namen anzeigen"
L["SETTING_SHOW_RANK_IN_NAME_DESC"] = "Zeigt den gebundenen Rang (z. B. Rang 4) direkt hinter dem Zaubernamen an."
L["SETTING_HIGHLIGHT_DOWNRANKS"] = "[MAX] & Downranks farblich hervorheben"
L["SETTING_HIGHLIGHT_DOWNRANKS_DESC"] = "Markiert den höchsten Rang grün mit [MAX] und niedrigere Ränge orange mit Hinweis auf den höchsten gelernten Rang."
L["SETTING_SHOW_RANK_SWITCHER"] = "Direkten Rang-Wechsler-Button anzeigen"
L["SETTING_SHOW_RANK_SWITCHER_DESC"] = "Zeigt rechts in der Zeile den Button zum schnellen Umschalten des Zauberranges."
L["SETTING_SHOW_LINE_TOOLTIPS"] = "Zauber- & Makro-Tooltips in der Liste"
L["SETTING_SHOW_LINE_TOOLTIPS_DESC"] = "Zeigt beim Hovern über eine Zeile den vollständigen Zauber-Tooltip des Ranges bzw. den Makro-Text."

L["SETTING_QUICK_BIND_SPELLBOOK"] = "1-Klick Direkt-Binden im Zauberbuch"
L["SETTING_QUICK_BIND_SPELLBOOK_DESC"] = "Wenn aktiv, bindet bei geöffneter Klickbelegung jeder Klick auf einen Zauber im Zauberbuch (inkl. Linksklick, Rechtsklick, Mittelklick, Maus 4+ sowie Shift/Strg/Alt) sofort diese Maustaste."
L["SETTING_SHOW_SPELLBOOK_BADGES"] = "Gebundene Tasten-Badges im Zauberbuch"
L["SETTING_SHOW_SPELLBOOK_BADGES_DESC"] = "Zeigt zugewiesene Maustasten (LMB, RMB, MMB, S-LMB, MB4) direkt auf den gebundenen Zauberrängen im Zauberbuch an."
L["SETTING_AUTO_SHOW_ALL_RANKS"] = "Automatisch 'Alle Zauberränge anzeigen'"
L["SETTING_AUTO_SHOW_ALL_RANKS_DESC"] = "Falls 'Alle Zauberränge anzeigen' im Zauberbuch deaktiviert ist, wird es beim Öffnen der Klickbelegung temporär aktiviert und beim Schließen wieder zurückgesetzt."

L["SETTING_SHOW_MINIMAP_BUTTON"] = "Minimap-Icon anzeigen"
L["SETTING_SHOW_MINIMAP_BUTTON_DESC"] = "Zeigt den Better Click Casting Button an der Minimap (jederzeit per /bcc umschaltbar)."

L["ACTION_UPGRADE_ALL_MAX_FORMAT"] = "Alle gebundenen Zauber auf MAX setzen (%d)"
L["ACTION_UPGRADE_ALL_MAX_NONE"] = "Alle gebundenen Zauber sind auf MAX-Rang"
L["ACTION_UPGRADE_ALL_MAX_DESC"] = "Stellt alle aktuell in der Liste gebundenen Zauber mit niedrigerem Rang auf ihren höchsten gelernten Rang hoch."
L["CHAT_UPGRADED_COUNT_FORMAT"] = "|cff40ff40Better Click Casting:|r %d Zauber auf den höchsten gelernten Rang aktualisiert (klicke auf Speichern zum Übernehmen)."
L["CHAT_HELP_HINT"] = "|cff99ccffBetter Click Casting:|r Nutze |cffffffff/bcc|r zum Öffnen der Klickbelegung oder |cffffffff/bcc minimap|r für das Minimap-Icon."
