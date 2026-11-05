local _, ns = ...

local L = setmetatable({}, {
	__index = function(t, k)
		return k
	end,
})

ns.L = L

-- Englischer Standard-Fallback (enUS / enGB)
L["ADDON_TITLE"] = "Better Click Casting"
L["RANK_FALLBACK_FORMAT"] = "Rank %d"
L["TAG_MAX"] = "[MAX]"
L["TAG_MAX_SHORT"] = "Max"
L["MAX_RANK_HINT_FORMAT"] = " / Max %d"

-- Rang-Wechsler-Button und Kontextmenü
L["SELECT_RANK_TITLE_FORMAT"] = "%s: Select Rank"
L["RANK_SWITCHER_TOOLTIP_TITLE"] = "Change Spell Rank"
L["RANK_SWITCHER_CURRENT_FORMAT"] = "Current: %s (Max learned: %s)"
L["RANK_SWITCHER_HINT_LEFT"] = "• Left-Click: Choose from learned ranks"
L["RANK_SWITCHER_HINT_RIGHT"] = "• Right-Click: Upgrade to highest rank (MAX)"

-- Gruppierung und Sortierung im ClickBindingFrame
L["GROUP_BUTTON_FORMAT"] = "Group: %s"
L["GROUP_MENU_TITLE"] = "Group & Sort Bindings"
L["GROUP_MODE_MODIFIER"] = "By Modifier (Direct / Shift / Ctrl / Alt)"
L["GROUP_MODE_MODIFIER_SHORT"] = "Modifier"
L["GROUP_MODE_BUTTON"] = "By Mouse Button (LMB / RMB / MMB / MB4+)"
L["GROUP_MODE_BUTTON_SHORT"] = "Button"
L["GROUP_MODE_TYPE"] = "By Action Type (Spells / Macros)"
L["GROUP_MODE_TYPE_SHORT"] = "Type"
L["GROUP_MODE_NONE"] = "Flat List (Logical Sort LMB / RMB / MMB / MB4+)"
L["GROUP_MODE_NONE_SHORT"] = "Off"
L["GROUP_TOOLTIP_TITLE"] = "List Grouping & Sorting"
L["GROUP_TOOLTIP_DESC"] = "Organizes your custom click bindings into clean sections and sorts mouse buttons in logical order (Left, Right, Middle, Mouse 4+)."

L["GROUP_HDR_NO_MOD"] = "Direct Click (No Modifier)"
L["GROUP_HDR_MOD_FORMAT"] = "%s + Click"
L["GROUP_HDR_SPELLS"] = "Spells"
L["GROUP_HDR_PET"] = "Pet Actions"
L["GROUP_HDR_MACROS"] = "Macros"
L["GROUP_HDR_UNBOUND"] = "Unassigned"

-- Zeilen-Tooltips im ClickBindingFrame
L["TOOLTIP_CLICK_BINDING_LABEL"] = "Click Binding:"
L["TOOLTIP_RANK_STATUS_LABEL"] = "Rank Status:"
L["TOOLTIP_STATUS_MAX_RANK_FORMAT"] = "Highest learned rank (%s)"
L["TOOLTIP_STATUS_DOWNRANK_FORMAT"] = "Downrank (%s / Max: %s)"
L["TOOLTIP_SWITCH_RANK_HINT"] = "Tip: Click the rank button on the right to switch ranks."

-- Zauberbuch-Tooltips und Checkbox
L["SPELLBOOK_ALREADY_BOUND_LABEL"] = "Click-bound to:"
L["SPELLBOOK_QUICK_BIND_CHECKBOX"] = "1-Click Direct Bind"
L["SPELLBOOK_QUICK_BIND_HINT"] = "Direct Bind active: Click this spell with any mouse button (or Shift/Ctrl/Alt + Click) to bind it immediately!"

-- Minimap-Button
L["MINIMAP_TOOLTIP_SUBTITLE"] = "Native Click Cast Enhancements"
L["MINIMAP_HINT_LEFT"] = "• Left-Click: Open / Close Click Cast Bindings"
L["MINIMAP_HINT_RIGHT"] = "• Right-Click: Better Click Casting Settings"
L["MINIMAP_HINT_DRAG"] = "• Drag: Move Minimap Button"

-- Settings-Button und Menü
L["SETTINGS_BUTTON_TOOLTIP_TITLE"] = "Better Click Casting: Settings"
L["SETTINGS_BUTTON_TOOLTIP_DESC"] = "Configure spell rank display, grouping, inline rank switcher, spellbook helpers, and minimap icon."
L["SETTINGS_MENU_TITLE"] = "Better Click Casting"
L["SETTINGS_HEADER_CLICKCAST"] = "Click Cast Window"
L["SETTINGS_HEADER_SPELLBOOK"] = "Spellbook Integration"
L["SETTINGS_HEADER_GENERAL"] = "General & Actions"

L["SETTING_SHOW_RANK_IN_NAME"] = "Show Spell Rank in Name"
L["SETTING_SHOW_RANK_IN_NAME_DESC"] = "Appends the spell rank (e.g. Rank 4) to each spell row."
L["SETTING_HIGHLIGHT_DOWNRANKS"] = "Highlight [MAX] & Downranks"
L["SETTING_HIGHLIGHT_DOWNRANKS_DESC"] = "Marks highest ranks with [MAX] in green and lower ranks in orange with max-rank hints."
L["SETTING_SHOW_RANK_SWITCHER"] = "Show Inline Rank Switcher Button"
L["SETTING_SHOW_RANK_SWITCHER_DESC"] = "Shows the clickable rank dropdown button on the right side of multi-rank spell rows."
L["SETTING_SHOW_LINE_TOOLTIPS"] = "Show Full Spell & Macro Tooltips"
L["SETTING_SHOW_LINE_TOOLTIPS_DESC"] = "Displays rank-accurate spell tooltips and macro text when hovering rows."

L["SETTING_QUICK_BIND_SPELLBOOK"] = "1-Click Direct Bind in Spellbook"
L["SETTING_QUICK_BIND_SPELLBOOK_DESC"] = "When enabled while Click Cast Bindings is open, clicking any spell in the Spellbook with ANY mouse button (including Left-Click, Right-Click, Middle-Click, Mouse4+, and Shift/Ctrl/Alt modifiers) immediately binds it to that button."
L["SETTING_SHOW_SPELLBOOK_BADGES"] = "Show Bound Key Badges in Spellbook"
L["SETTING_SHOW_SPELLBOOK_BADGES_DESC"] = "Displays assigned mouse buttons (LMB, RMB, MMB, S-LMB, MB4) directly on bound spell ranks in the Spellbook."
L["SETTING_AUTO_SHOW_ALL_RANKS"] = "Auto-Enable 'Show All Spell Ranks'"
L["SETTING_AUTO_SHOW_ALL_RANKS_DESC"] = "If 'Show All Spell Ranks' is turned off in your Spellbook, temporarily enables it while the Click Cast window is open and restores it when closed."

L["SETTING_SHOW_MINIMAP_BUTTON"] = "Show Minimap Button"
L["SETTING_SHOW_MINIMAP_BUTTON_DESC"] = "Displays the Better Click Casting button on the Minimap (use /bcc to toggle anytime)."

L["ACTION_UPGRADE_ALL_MAX_FORMAT"] = "Upgrade All Bound Spells to MAX (%d)"
L["ACTION_UPGRADE_ALL_MAX_NONE"] = "All Bound Spells Are at MAX Rank"
L["ACTION_UPGRADE_ALL_MAX_DESC"] = "Upgrades all currently bound downranked spells in the list to their highest learned rank."
L["CHAT_UPGRADED_COUNT_FORMAT"] = "|cff40ff40Better Click Casting:|r Upgraded %d spell binding(s) to highest learned rank (click Save to apply)."
L["CHAT_HELP_HINT"] = "|cff99ccffBetter Click Casting:|r Use |cffffffff/bcc|r to open Click Cast Bindings or |cffffffff/bcc minimap|r to toggle the minimap icon."
