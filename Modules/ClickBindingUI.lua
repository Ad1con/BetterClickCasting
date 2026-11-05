local _, ns = ...

local L = ns.L
local Constants = ns.Constants
local Colors = Constants.Colors
local ElementDataTypes = Constants.ElementDataTypes
local Database = ns.Database
local SpellRanks = ns.SpellRanks
local SpellBookUI = ns.SpellBookUI
local SettingsUI = ns.SettingsUI

local ClickBindingUI = {}
ns.ClickBindingUI = ClickBindingUI

local isHooked = false
local restoredAllRanksOnClose = false
local isRebuildingGroups = false

--------------------------------------------------------------------------------
-- Logische Gruppierung und Sortierung im ClickBindingFrame
--------------------------------------------------------------------------------

local function GetElementGroupMetadata(elementData, groupingMode)
	if not elementData or elementData.elementType ~= ElementDataTypes.CustomsBinding then
		return 0, "", 999, 999
	end

	local info = elementData.bindingInfo
	if not info or elementData.unbound or not info.button then
		return 900, L["GROUP_HDR_UNBOUND"], 999, 999
	end

	local btnOrder = Constants.GetButtonSortOrder(info.button)
	local modOrder, modReadable = Constants.GetModifierSortInfo(info.modifiers)

	if groupingMode == "modifier" then
		if modOrder == 1 or modReadable == "" then
			return 100, L["GROUP_HDR_NO_MOD"], btnOrder, modOrder
		else
			-- Eindeutige Gruppen-Ordnung pro Modifier-Kombination (z. B. Shift = 200, Strg = 300, Alt = 400)
			return (modOrder * 100), string.format(L["GROUP_HDR_MOD_FORMAT"], modReadable), btnOrder, modOrder
		end
	elseif groupingMode == "button" then
		local btnTitle = Constants.GetButtonDisplayName(info.button)
		local shortBtn = Constants.GetShortBindingString({ button = info.button, modifiers = 0 })
		if shortBtn and shortBtn ~= "" then
			btnTitle = string.format("%s (%s)", btnTitle, shortBtn)
		end
		return (btnOrder * 100), btnTitle, btnOrder, modOrder
	elseif groupingMode == "type" then
		if Enum and Enum.ClickBindingType then
			if info.type == Enum.ClickBindingType.Spell then
				return 100, L["GROUP_HDR_SPELLS"], btnOrder, modOrder
			elseif info.type == Enum.ClickBindingType.PetAction then
				return 200, L["GROUP_HDR_PET"], btnOrder, modOrder
			elseif info.type == Enum.ClickBindingType.Macro then
				return 300, L["GROUP_HDR_MACROS"], btnOrder, modOrder
			end
		end
		return 400, L["GROUP_HDR_SPELLS"], btnOrder, modOrder
	end

	-- Modus "none" (flache Liste, aber logisch sortiert)
	return 100, "", btnOrder, modOrder
end

local function GetPrimarySectionRank(e)
	if not e then
		return 99
	end
	if e.elementType == ElementDataTypes.DefaultsHeader then
		return 10
	elseif e.elementType == ElementDataTypes.InteractionBinding then
		return 20
	elseif e.elementType == ElementDataTypes.CustomsHeader and not e.isBCCGroupHeader then
		return 30
	elseif e.elementType == ElementDataTypes.NewSlot then
		return 50
	end
	-- Sowohl eigene Untergruppen-Header (isBCCGroupHeader) als auch CustomsBinding liegen in Sektion 40
	return 40
end

local function GetSortTupleForSection40(e, mode)
	if e.isBCCGroupHeader then
		return e._bccGroupOrder or 100, e.bccGroupTitle or "", true, 0, 0
	end
	local groupOrder, groupTitle, btnOrder, modOrder = GetElementGroupMetadata(e, mode)
	return groupOrder, groupTitle, false, btnOrder, modOrder
end

local function BCCElementSortComparator(e1, e2)
	if e1 == e2 then
		return false
	end

	local r1 = GetPrimarySectionRank(e1)
	local r2 = GetPrimarySectionRank(e2)
	if r1 ~= r2 then
		return r1 < r2
	end

	if r1 == 20 then
		local id1 = (e1.bindingInfo and e1.bindingInfo.actionID) or 0
		local id2 = (e2.bindingInfo and e2.bindingInfo.actionID) or 0
		if id1 ~= id2 then
			return id1 < id2
		end
		return false
	end

	if r1 ~= 40 then
		return false
	end

	local mode = Database.Get("groupingMode") or "modifier"
	local g1, title1, isHdr1, b1, m1 = GetSortTupleForSection40(e1, mode)
	local g2, title2, isHdr2, b2, m2 = GetSortTupleForSection40(e2, mode)

	-- 1. Gruppen-Reihenfolge (inkl. Titel-Feinunterscheidung bei gleichem numerischen Rang)
	if g1 ~= g2 then
		return g1 < g2
	end
	if mode ~= "none" and title1 ~= title2 then
		return title1 < title2
	end

	-- 2. Innerhalb derselben Gruppe steht der Untergruppen-Header immer vor seinen Einträgen
	if isHdr1 ~= isHdr2 then
		return isHdr1
	end
	if isHdr1 and isHdr2 then
		return false
	end

	-- 3. Gebundene Einträge vor ungebundenen Einträgen
	local u1 = e1.unbound and true or false
	local u2 = e2.unbound and true or false
	if u1 ~= u2 then
		return not u1
	end

	-- 4. Logische Sortierung nach Maustaste (LMB -> RMB -> MMB -> MB4 -> MB5) und Modifier
	if mode == "button" then
		if m1 ~= m2 then
			return m1 < m2
		end
		if b1 ~= b2 then
			return b1 < b2
		end
	else
		if b1 ~= b2 then
			return b1 < b2
		end
		if m1 ~= m2 then
			return m1 < m2
		end
	end

	local modRaw1 = (e1.bindingInfo and e1.bindingInfo.modifiers) or 0
	local modRaw2 = (e2.bindingInfo and e2.bindingInfo.modifiers) or 0
	if modRaw1 ~= modRaw2 then
		return modRaw1 < modRaw2
	end

	local btnRaw1 = (e1.bindingInfo and e1.bindingInfo.button) or ""
	local btnRaw2 = (e2.bindingInfo and e2.bindingInfo.button) or ""
	if btnRaw1 ~= btnRaw2 then
		return btnRaw1 < btnRaw2
	end

	local type1 = (e1.bindingInfo and e1.bindingInfo.type) or 0
	local type2 = (e2.bindingInfo and e2.bindingInfo.type) or 0
	if type1 ~= type2 then
		return type1 < type2
	end

	local act1 = (e1.bindingInfo and e1.bindingInfo.actionID) or 0
	local act2 = (e2.bindingInfo and e2.bindingInfo.actionID) or 0
	if act1 ~= act2 then
		return act1 < act2
	end

	return false
end

function ClickBindingUI.RebuildGroups()
	if isRebuildingGroups or not ClickBindingFrame or not ClickBindingFrame.dataProvider then
		return
	end
	isRebuildingGroups = true

	local provider = ClickBindingFrame.dataProvider
	local mode = Database.Get("groupingMode") or "modifier"

	-- Falls eine Zeile über DeleteButton oder SPELLS_CHANGED direkt aus dem DataProvider entfernt wird,
	-- Gruppen und Zähler automatisch nachziehen.
	if not provider._bccRemoveHooked and type(provider.Remove) == "function" then
		hooksecurefunc(provider, "Remove", function()
			if not isRebuildingGroups then
				ClickBindingUI.RebuildGroups()
			end
		end)
		provider._bccRemoveHooked = true
	end

	-- Wichtig: Vor dem Entfernen/Einfügen von Headern den SortComparator leeren,
	-- damit Blizzards Standard-ElementSortComparator nicht während provider:Insert() auf Header ohne bindingInfo läuft.
	if provider.ClearSortComparator then
		provider:ClearSortComparator()
	end

	-- 1. Alte eigene Untergruppen-Header entfernen
	local oldHeaders = {}
	for _, element in provider:Enumerate() do
		if element and element.isBCCGroupHeader then
			table.insert(oldHeaders, element)
		end
	end
	if #oldHeaders > 0 then
		provider:Remove(unpack(oldHeaders))
	end

	-- 2. Gruppen-Metadaten und Gesamtzähler auf allen Custom-Bindings berechnen
	local groups = {}
	local totalCustomCount = 0
	for _, element in provider:Enumerate() do
		if element and element.elementType == ElementDataTypes.CustomsBinding then
			totalCustomCount = totalCustomCount + 1
			local groupOrder, groupTitle = GetElementGroupMetadata(element, mode)
			if mode ~= "none" and groupTitle ~= "" then
				local groupKey = tostring(groupOrder) .. ":" .. tostring(groupTitle)
				local grp = groups[groupKey]
				if not grp then
					grp = {
						order = groupOrder,
						title = groupTitle,
						count = 0,
					}
					groups[groupKey] = grp
				end
				grp.count = grp.count + 1
			end
		end
	end

	-- Gesamtzähler auch auf dem Haupt-CustomsHeader aktualisieren
	for _, element in provider:Enumerate() do
		if element and element.elementType == ElementDataTypes.CustomsHeader and not element.isBCCGroupHeader then
			element._bccTotalCustomCount = totalCustomCount
		end
	end

	-- 3. Neue Untergruppen-Header gesammelt einfügen (wenn Gruppierung aktiv)
	if mode ~= "none" then
		local newHeaders = {}
		for _, grp in pairs(groups) do
			table.insert(newHeaders, {
				elementType = ElementDataTypes.CustomsHeader,
				isBCCGroupHeader = true,
				_bccGroupOrder = grp.order,
				bccGroupTitle = grp.title,
				bccGroupCount = grp.count,
				bccHeaderText = string.format("%s%s%s  %s(%d)%s", Colors.HEADER_SUB, grp.title, Colors.RESET, Colors.MUTED, grp.count, Colors.RESET),
			})
		end
		if #newHeaders > 0 then
			if provider.InsertTable then
				provider:InsertTable(newHeaders)
			else
				provider:Insert(unpack(newHeaders))
			end
		end
	end

	-- 4. Eigenen Comparator setzen und einmalig sortieren
	provider:SetSortComparator(BCCElementSortComparator, false)

	-- 5. Sichtbare Header- und Zeilen-Frames sofort aktualisieren
	ClickBindingUI.RefreshVisibleLines()

	isRebuildingGroups = false
end

--------------------------------------------------------------------------------
-- Rang einer bestehenden Zeile ändern (ohne Taste neu zu binden)
--------------------------------------------------------------------------------

local function SetLineSpellRank(lineFrame, elementData, newActionID)
	if not lineFrame or not elementData or not elementData.bindingInfo or not newActionID then
		return
	end
	if elementData.bindingInfo.actionID == newActionID then
		return
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	elementData.bindingInfo.actionID = newActionID

	if lineFrame.Init then
		lineFrame:Init(elementData)
	else
		ClickBindingUI.UpdateLineWithRank(lineFrame, elementData)
	end

	if ClickBindingFrame then
		if ClickBindingFrame.CleanDataProvider then
			ClickBindingFrame:CleanDataProvider()
		end
		ClickBindingUI.RebuildGroups()
		ClickBindingFrame.pendingChanges = true
	end

	if EventRegistry and EventRegistry.TriggerEvent then
		EventRegistry:TriggerEvent("ClickBindingFrame.UpdateFrames")
	end
	if SpellBookUI and SpellBookUI.RefreshBadges then
		SpellBookUI.RefreshBadges()
	end
end

--------------------------------------------------------------------------------
-- 1-Klick Direkt-Binden aus dem Zauberbuch (inkl. LMB, RMB, MMB, MB4+)
--------------------------------------------------------------------------------

function ClickBindingUI.QuickBindSpell(actionType, actionID, buttonName, modifiers)
	if not ClickBindingFrame or not ClickBindingFrame.dataProvider or not actionType or not actionID or not buttonName then
		return false
	end

	modifiers = modifiers or (MakeModifiers and MakeModifiers()) or 0

	-- Prüfen, ob genau dieser Zauber bereits auf exakt dieser Taste + Modifier liegt
	for _, element in ClickBindingFrame.dataProvider:Enumerate() do
		local info = element and element.bindingInfo
		if info and not element.unbound and info.type == actionType and info.actionID == actionID and info.button == buttonName and (info.modifiers or 0) == modifiers then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			return true
		end
	end

	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	if ClickBindingFrame.ClearUnboundText then
		ClickBindingFrame:ClearUnboundText()
	end

	-- 1. Falls eine andere Zeile bereits diese Taste + Modifier belegt hat, diese freigeben
	for _, otherData in ClickBindingFrame.dataProvider:Enumerate() do
		local otherInfo = otherData and otherData.bindingInfo
		if otherInfo and not otherData.unbound and otherInfo.button == buttonName and (otherInfo.modifiers or 0) == modifiers then
			otherInfo.button = nil
			otherInfo.modifiers = nil
			otherData.unbound = true
			if ClickBindingFrame.ScrollBox and ClickBindingFrame.ScrollBox.FindFrame then
				local otherButton = ClickBindingFrame.ScrollBox:FindFrame(otherData)
				if otherButton and otherButton.Init then
					otherButton:Init(otherData)
				end
			end
			if ClickBindingFrame.SetUnboundText then
				ClickBindingFrame:SetUnboundText(otherData)
			end
		end
	end

	-- 2. Vorhandenen ungebundenen Eintrag für denselben Zauber oder leeren NewSlot wiederverwenden
	local targetElement = nil
	for _, element in ClickBindingFrame.dataProvider:Enumerate() do
		local info = element and element.bindingInfo
		if element and element.unbound and info and info.type == actionType and info.actionID == actionID then
			targetElement = element
			break
		end
	end

	if not targetElement and ClickBindingFrame.HasEmptySlot and ClickBindingFrame:HasEmptySlot() then
		targetElement = ClickBindingFrame:GetLastElement()
	end

	if targetElement then
		targetElement.bindingInfo = {
			type = actionType,
			actionID = actionID,
			button = buttonName,
			modifiers = modifiers,
		}
		targetElement.unbound = false
		if targetElement.elementType == ElementDataTypes.NewSlot then
			targetElement.elementType = ElementDataTypes.CustomsBinding
			if ClickBindingFrame.SetHasNewSlot then
				ClickBindingFrame:SetHasNewSlot(false)
			end
		end
	else
		ClickBindingFrame.dataProvider:Insert({
			elementType = ElementDataTypes.CustomsBinding,
			bindingInfo = {
				type = actionType,
				actionID = actionID,
				button = buttonName,
				modifiers = modifiers,
			},
			unbound = false,
		})
	end

	if ClickBindingFrame.CleanDataProvider then
		ClickBindingFrame:CleanDataProvider()
	end
	ClickBindingUI.RebuildGroups()
	ClickBindingFrame.pendingChanges = true

	ClickBindingUI.RefreshVisibleLines()
	if EventRegistry and EventRegistry.TriggerEvent then
		EventRegistry:TriggerEvent("ClickBindingFrame.UpdateFrames")
	end
	if SpellBookUI and SpellBookUI.RefreshBadges then
		SpellBookUI.RefreshBadges()
	end
	return true
end

function ClickBindingUI.CountUpgradeableBindings()
	if not ClickBindingFrame or not ClickBindingFrame.dataProvider then
		return 0
	end
	local count = 0
	for _, element in ClickBindingFrame.dataProvider:Enumerate() do
		local info = element and element.bindingInfo
		if info and Constants.IsSpellOrPetBinding(info) and info.actionID then
			local rankEntry = SpellRanks.GetRankEntryForAction(info.actionID)
			local maxEntry = rankEntry and rankEntry.group and rankEntry.group.maxEntry
			if maxEntry and maxEntry.actionID ~= info.actionID then
				count = count + 1
			end
		end
	end
	return count
end

function ClickBindingUI.UpgradeAllBindingsToMaxRank()
	if not ClickBindingFrame or not ClickBindingFrame.dataProvider then
		return 0
	end
	local upgraded = 0
	for _, element in ClickBindingFrame.dataProvider:Enumerate() do
		local info = element and element.bindingInfo
		if info and Constants.IsSpellOrPetBinding(info) and info.actionID then
			local rankEntry = SpellRanks.GetRankEntryForAction(info.actionID)
			local maxEntry = rankEntry and rankEntry.group and rankEntry.group.maxEntry
			if maxEntry and maxEntry.actionID ~= info.actionID then
				info.actionID = maxEntry.actionID
				upgraded = upgraded + 1
			end
		end
	end

	if upgraded > 0 then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if ClickBindingFrame.CleanDataProvider then
			ClickBindingFrame:CleanDataProvider()
		end
		ClickBindingUI.RebuildGroups()
		ClickBindingFrame.pendingChanges = true
		ClickBindingUI.RefreshVisibleLines()
		if EventRegistry and EventRegistry.TriggerEvent then
			EventRegistry:TriggerEvent("ClickBindingFrame.UpdateFrames")
		end
		if SpellBookUI and SpellBookUI.RefreshBadges then
			SpellBookUI.RefreshBadges()
		end
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(string.format(L["CHAT_UPGRADED_COUNT_FORMAT"], upgraded))
		end
	end
	return upgraded
end

local function OpenRankContextMenu(rankButton, lineFrame, elementData, rankEntry)
	if not MenuUtil or not MenuUtil.CreateContextMenu or not rankEntry or not rankEntry.group then
		return
	end

	local group = rankEntry.group
	if #group.entries <= 1 then
		return
	end

	MenuUtil.CreateContextMenu(rankButton, function(_, rootDescription)
		rootDescription:CreateTitle(string.format(L["SELECT_RANK_TITLE_FORMAT"], group.name))

		local function IsSelected(entryActionID)
			return elementData and elementData.bindingInfo and elementData.bindingInfo.actionID == entryActionID
		end

		local function SetSelected(entryActionID)
			SetLineSpellRank(lineFrame, elementData, entryActionID)
		end

		for _, entry in ipairs(group.entries) do
			local label = (entry.subName and entry.subName ~= "")
				and entry.subName
				or string.format(L["RANK_FALLBACK_FORMAT"], entry.rankIndex or 1)
			local isMax = (group.maxEntry == entry)
			local costStr = SpellRanks.GetSpellPowerCostString(entry.spellID or entry.actionID)

			local displayParts = { label }
			if costStr then
				table.insert(displayParts, string.format("%s(%s)%s", Colors.MUTED, costStr, Colors.RESET))
			end
			if isMax then
				table.insert(displayParts, Colors.TAG_MAX .. L["TAG_MAX"] .. Colors.RESET)
			end

			local radioText = table.concat(displayParts, " ")
			local radio = rootDescription:CreateRadio(radioText, IsSelected, SetSelected, entry.actionID)
			radio:SetTooltip(function(tooltip)
				if entry.slotIndex and entry.spellBank and tooltip.SetSpellBookItem then
					tooltip:SetSpellBookItem(entry.slotIndex, entry.spellBank)
				elseif tooltip.SetSpellByID then
					tooltip:SetSpellByID(entry.spellID or entry.actionID)
				end
			end)
		end
	end)
end

--------------------------------------------------------------------------------
-- Tooltips für Zeilen im ClickBindingFrame
--------------------------------------------------------------------------------

function ClickBindingUI.ShowLineTooltip(lineFrame)
	if not lineFrame or not Database.Get("showLineTooltips") then
		return
	end
	local elementData = lineFrame.GetElementData and lineFrame:GetElementData()
	if not elementData or not elementData.bindingInfo then
		return
	end

	local bindingInfo = elementData.bindingInfo
	local bType = bindingInfo.type
	local actionID = bindingInfo.actionID
	if not actionID or not Enum or not Enum.ClickBindingType then
		return
	end

	GameTooltip:SetOwner(lineFrame, "ANCHOR_RIGHT")

	if bType == Enum.ClickBindingType.Spell or bType == Enum.ClickBindingType.PetAction then
		local rankEntry = SpellRanks.GetRankEntryForAction(actionID)
		if rankEntry and rankEntry.slotIndex and rankEntry.spellBank then
			GameTooltip:SetSpellBookItem(rankEntry.slotIndex, rankEntry.spellBank)
		else
			GameTooltip:SetSpellByID(actionID)
		end

		GameTooltip:AddLine(" ")
		local bindText = Constants.GetFullBindingString(bindingInfo)
		GameTooltip:AddDoubleLine(L["TOOLTIP_CLICK_BINDING_LABEL"], bindText, 0.8, 0.8, 0.8, 1, 1, 1)

		if rankEntry and rankEntry.group and #rankEntry.group.entries > 1 then
			local group = rankEntry.group
			local maxEntry = group.maxEntry
			if maxEntry and maxEntry.actionID == rankEntry.actionID then
				GameTooltip:AddDoubleLine(
					L["TOOLTIP_RANK_STATUS_LABEL"],
					string.format(L["TOOLTIP_STATUS_MAX_RANK_FORMAT"], rankEntry.subName ~= "" and rankEntry.subName or L["TAG_MAX_SHORT"]),
					0.8, 0.8, 0.8,
					0.25, 1.0, 0.25
				)
			elseif maxEntry then
				GameTooltip:AddDoubleLine(
					L["TOOLTIP_RANK_STATUS_LABEL"],
					string.format(L["TOOLTIP_STATUS_DOWNRANK_FORMAT"], rankEntry.subName or "?", maxEntry.subName or "?"),
					0.8, 0.8, 0.8,
					1.0, 0.72, 0.2
				)
			end
			if Database.Get("showRankSwitcher") then
				GameTooltip:AddLine(L["TOOLTIP_SWITCH_RANK_HINT"], 0.6, 0.85, 1.0, true)
			end
		end

		GameTooltip:Show()
	elseif bType == Enum.ClickBindingType.Macro then
		local macroName, _, macroBody = GetMacroInfo(actionID)
		if macroName then
			GameTooltip_SetTitle(GameTooltip, string.format(CLICK_BINDING_MACRO_TITLE or "Macro: %s", macroName))
			if macroBody and macroBody ~= "" then
				GameTooltip:AddLine(macroBody, 0.9, 0.9, 0.9, true)
			end
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(L["TOOLTIP_CLICK_BINDING_LABEL"], Constants.GetFullBindingString(bindingInfo), 0.8, 0.8, 0.8, 1, 1, 1)
			GameTooltip:Show()
		else
			GameTooltip:Hide()
		end
	else
		GameTooltip:Hide()
	end
end

--------------------------------------------------------------------------------
-- Moderne UI-Widgets auf Header- und Zeilen-Frames
--------------------------------------------------------------------------------

local function EnsureHeaderGroupWidgets(headerFrame)
	if headerFrame.BCCGroupButton then
		return headerFrame.BCCGroupButton, headerFrame.BCCSubDivider
	end

	-- Dezent schimmernde Trennlinie unter eigenen Untergruppen-Headern
	local divider = headerFrame:CreateTexture(nil, "ARTWORK")
	divider:SetAtlas("Options_HorizontalDivider", true)
	divider:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT", 0, -1)
	divider:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT", -6, -1)
	divider:SetAlpha(0.55)
	divider:Hide()
	headerFrame.BCCSubDivider = divider

	-- Moderner Pill-Dropdown-Button rechts im Haupt-"Benutzerdefinierte Belegungen"-Header
	-- Nutzt "common-dropdown-c-button" (ohne eingebrannten Rechtspfeil) + "common-dropdown-a-button" (Pfeil nach unten)
	local btn = CreateFrame("Button", nil, headerFrame)
	btn:SetSize(134, 19)
	btn:SetPoint("RIGHT", headerFrame, "RIGHT", -4, 0)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAtlas("common-dropdown-c-button")
	bg:SetPoint("TOPLEFT", -3, 3)
	bg:SetPoint("BOTTOMRIGHT", 3, -3)
	btn.Bg = bg

	local hl = btn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAtlas("common-dropdown-c-button-hover-1")
	hl:SetBlendMode("ADD")
	hl:SetAlpha(0.45)
	hl:SetPoint("TOPLEFT", -3, 3)
	hl:SetPoint("BOTTOMRIGHT", 3, -3)

	local arrow = btn:CreateTexture(nil, "OVERLAY")
	arrow:SetAtlas("common-dropdown-a-button")
	arrow:SetSize(11, 11)
	arrow:SetPoint("RIGHT", btn, "RIGHT", -5, -1)
	btn.Arrow = arrow

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", btn, "LEFT", 8, 0)
	label:SetPoint("RIGHT", arrow, "LEFT", -3, 0)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(false)
	btn.Text = label

	btn:SetScript("OnMouseDown", function(self)
		self.Text:SetPoint("LEFT", self, "LEFT", 9, -1)
		self.Arrow:SetPoint("RIGHT", self, "RIGHT", -4, -2)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self.Text:SetPoint("LEFT", self, "LEFT", 8, 0)
		self.Arrow:SetPoint("RIGHT", self, "RIGHT", -5, -1)
	end)

	btn:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		if SettingsUI and SettingsUI.OpenGroupingMenu then
			SettingsUI.OpenGroupingMenu(self)
		end
	end)

	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, L["GROUP_TOOLTIP_TITLE"])
		GameTooltip_AddNormalLine(GameTooltip, L["GROUP_TOOLTIP_DESC"], true)
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	btn:Hide()
	headerFrame.BCCGroupButton = btn
	return btn, divider
end

local function UpdateHeaderFrame(headerFrame, elementData)
	if not headerFrame then
		return
	end
	elementData = elementData or (headerFrame.GetElementData and headerFrame:GetElementData())
	local groupBtn, divider = EnsureHeaderGroupWidgets(headerFrame)

	-- Zuerst eigene Elemente zurücksetzen (ScrollBox-Recycling-Hygiene)
	groupBtn:Hide()
	divider:Hide()
	if headerFrame.Name then
		headerFrame.Name:ClearAllPoints()
		headerFrame.Name:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
	end

	if not elementData then
		return
	end

	if elementData.isBCCGroupHeader then
		if headerFrame.Name then
			headerFrame.Name:SetPoint("LEFT", headerFrame, "LEFT", 6, 0)
			headerFrame.Name:SetText(elementData.bccHeaderText or "")
		end
		divider:Show()
	elseif elementData.elementType == ElementDataTypes.CustomsHeader then
		if headerFrame.Name and elementData._bccTotalCustomCount and elementData._bccTotalCustomCount > 0 then
			local baseTitle = CLICK_BINDINGS_CUSTOMS_HEADER or headerFrame.Name:GetText() or ""
			headerFrame.Name:SetText(string.format("%s %s(%d)%s", baseTitle, Colors.MUTED, elementData._bccTotalCustomCount, Colors.RESET))
		end
		if SettingsUI and SettingsUI.GetCurrentGroupShortLabel then
			groupBtn.Text:SetText(string.format(L["GROUP_BUTTON_FORMAT"], SettingsUI.GetCurrentGroupShortLabel()))
			groupBtn:Show()
		end
	end
end

local LEGACY_BUTTON_REGIONS = {
	"TopLeft",
	"TopRight",
	"BottomLeft",
	"BottomRight",
	"TopMiddle",
	"MiddleLeft",
	"MiddleRight",
	"BottomMiddle",
	"MiddleMiddle",
}

local function ShouldShowDeleteButton(lineFrame, elementData)
	elementData = elementData or (lineFrame and lineFrame.GetElementData and lineFrame:GetElementData())
	if not elementData then
		return false
	end
	return elementData.elementType ~= ElementDataTypes.InteractionBinding
end

local function EnsureDeleteButtonStyled(lineFrame)
	local delBtn = lineFrame and lineFrame.DeleteButton
	if not delBtn then
		return nil
	end
	if delBtn._bccStyled then
		return delBtn
	end
	delBtn._bccStyled = true

	-- Alte 9-Slice-Silbertexturen aus UIMenuButtonStretchTemplate unsichtbar schalten
	for _, key in ipairs(LEGACY_BUTTON_REGIONS) do
		if delBtn[key] and delBtn[key].SetAlpha then
			delBtn[key]:SetAlpha(0)
		end
	end

	-- In der 2. Zeile (auf derselben vertikalen Achse y = -8 wie BindingText) rechts außen platzieren,
	-- damit Zeile 1 (Zaubername + Rang) die volle Zeilenbreite ohne Überlappung nutzen kann.
	delBtn:SetSize(22, 18)
	delBtn:ClearAllPoints()
	delBtn:SetPoint("RIGHT", lineFrame, "RIGHT", -6, -8)

	if lineFrame.Name and lineFrame.Icon then
		lineFrame.Name:ClearAllPoints()
		lineFrame.Name:SetPoint("LEFT", lineFrame.Icon, "RIGHT", 5, 9)
		lineFrame.Name:SetPoint("RIGHT", lineFrame, "RIGHT", -8, 9)
		lineFrame.Name:SetWordWrap(false)
	end
	if lineFrame.BindingText and lineFrame.Icon then
		lineFrame.BindingText:ClearAllPoints()
		lineFrame.BindingText:SetPoint("LEFT", lineFrame.Icon, "RIGHT", 5, -8)
		lineFrame.BindingText:SetWordWrap(false)
	end

	local bg = delBtn:CreateTexture(nil, "BACKGROUND")
	bg:SetAtlas("common-dropdown-c-button")
	bg:SetPoint("TOPLEFT", -2, 2)
	bg:SetPoint("BOTTOMRIGHT", 2, -2)
	delBtn.BCCBg = bg

	local hl = delBtn:GetHighlightTexture()
	if hl and hl.SetAtlas then
		hl:SetAtlas("common-dropdown-c-button-hover-1")
		hl:SetBlendMode("ADD")
		hl:SetAlpha(0.45)
		hl:ClearAllPoints()
		hl:SetPoint("TOPLEFT", -2, 2)
		hl:SetPoint("BOTTOMRIGHT", 2, -2)
	end

	if delBtn.Icon then
		delBtn.Icon:ClearAllPoints()
		delBtn.Icon:SetPoint("CENTER", delBtn, "CENTER", 0, 0)
	end

	delBtn:HookScript("OnMouseDown", function(self)
		if self.Icon then
			self.Icon:SetPoint("CENTER", self, "CENTER", 1, -1)
		end
	end)

	delBtn:HookScript("OnMouseUp", function(self)
		if self.Icon then
			self.Icon:SetPoint("CENTER", self, "CENTER", 0, 0)
		end
	end)

	-- Blizzards XML-Skript und ClickBindingLineMixin:OnLeave verstecken DeleteButton bei OnLeave;
	-- für löschbare Zeilen dauerhaft sichtbar halten.
	delBtn:HookScript("OnLeave", function(self)
		if ShouldShowDeleteButton(lineFrame) then
			self:Show()
		end
	end)
	delBtn:HookScript("OnHide", function(self)
		if not self._bccAllowHide and ShouldShowDeleteButton(lineFrame) then
			self:Show()
		end
	end)

	return delBtn
end

local function EnsureLineRankButton(lineFrame)
	if lineFrame.BCCRankButton then
		return lineFrame.BCCRankButton
	end

	EnsureDeleteButtonStyled(lineFrame)

	-- Kompaktes Dark-Pill-Dropdown in der 2. Zeile direkt links neben dem DeleteButton (Höhe 18px)
	local btn = CreateFrame("Button", nil, lineFrame)
	btn:SetSize(88, 18)
	if lineFrame.DeleteButton then
		btn:SetPoint("RIGHT", lineFrame.DeleteButton, "LEFT", -4, 0)
	else
		btn:SetPoint("RIGHT", lineFrame, "RIGHT", -6, -8)
	end
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local bg = btn:CreateTexture(nil, "BACKGROUND")
	bg:SetAtlas("common-dropdown-c-button")
	bg:SetPoint("TOPLEFT", -2, 2)
	bg:SetPoint("BOTTOMRIGHT", 2, -2)
	btn.Bg = bg

	local hl = btn:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAtlas("common-dropdown-c-button-hover-1")
	hl:SetBlendMode("ADD")
	hl:SetAlpha(0.45)
	hl:SetPoint("TOPLEFT", -2, 2)
	hl:SetPoint("BOTTOMRIGHT", 2, -2)

	local arrow = btn:CreateTexture(nil, "OVERLAY")
	arrow:SetAtlas("common-dropdown-a-button")
	arrow:SetSize(10, 10)
	arrow:SetPoint("RIGHT", btn, "RIGHT", -5, -1)
	btn.Arrow = arrow

	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", btn, "LEFT", 6, 0)
	label:SetPoint("RIGHT", arrow, "LEFT", -2, 0)
	label:SetJustifyH("CENTER")
	label:SetWordWrap(false)
	btn.Text = label

	btn:SetScript("OnMouseDown", function(self)
		self.Text:SetPoint("LEFT", self, "LEFT", 7, -1)
		self.Arrow:SetPoint("RIGHT", self, "RIGHT", -4, -2)
	end)

	btn:SetScript("OnMouseUp", function(self)
		self.Text:SetPoint("LEFT", self, "LEFT", 6, 0)
		self.Arrow:SetPoint("RIGHT", self, "RIGHT", -5, -1)
	end)

	btn:SetScript("OnClick", function(self, mouseButton)
		local elementData = lineFrame.GetElementData and lineFrame:GetElementData()
		if not elementData or not elementData.bindingInfo then
			return
		end
		local rankEntry = SpellRanks.GetRankEntryForAction(elementData.bindingInfo.actionID)
		if not rankEntry or not rankEntry.group then
			return
		end

		if mouseButton == "RightButton" then
			local maxEntry = rankEntry.group.maxEntry
			if maxEntry and maxEntry.actionID ~= elementData.bindingInfo.actionID then
				SetLineSpellRank(lineFrame, elementData, maxEntry.actionID)
				ClickBindingUI.ShowLineTooltip(lineFrame)
			else
				OpenRankContextMenu(self, lineFrame, elementData, rankEntry)
			end
		else
			OpenRankContextMenu(self, lineFrame, elementData, rankEntry)
		end
	end)

	btn:SetScript("OnEnter", function(self)
		if lineFrame.DeleteButton and lineFrame.elementType ~= ElementDataTypes.InteractionBinding then
			lineFrame.DeleteButton:Show()
		end
		local elementData = lineFrame.GetElementData and lineFrame:GetElementData()
		local rankEntry = elementData and elementData.bindingInfo and SpellRanks.GetRankEntryForAction(elementData.bindingInfo.actionID)

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip_SetTitle(GameTooltip, L["RANK_SWITCHER_TOOLTIP_TITLE"])
		if rankEntry and rankEntry.group and rankEntry.group.maxEntry then
			local maxEntry = rankEntry.group.maxEntry
			GameTooltip:AddLine(string.format(L["RANK_SWITCHER_CURRENT_FORMAT"], rankEntry.subName or "?", maxEntry.subName or "?"), 1, 1, 1)
		end
		GameTooltip:AddLine(L["RANK_SWITCHER_HINT_LEFT"], 0.6, 0.85, 1.0)
		GameTooltip:AddLine(L["RANK_SWITCHER_HINT_RIGHT"], 0.25, 1.0, 0.25)
		GameTooltip:Show()
	end)

	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
		if lineFrame:IsMouseMotionFocus() then
			ClickBindingUI.ShowLineTooltip(lineFrame)
		end
		if lineFrame.DeleteButton and ShouldShowDeleteButton(lineFrame) then
			lineFrame.DeleteButton:Show()
		end
	end)

	btn:Hide()
	lineFrame.BCCRankButton = btn
	return btn
end

local function ApplyRankToLine(lineFrame, elementData, subtext)
	local rankBtn = EnsureLineRankButton(lineFrame)

	if not elementData or not elementData.bindingInfo or not Constants.IsSpellOrPetBinding(elementData.bindingInfo) then
		if rankBtn then
			rankBtn:Hide()
		end
		return
	end

	local actionID = elementData.bindingInfo.actionID
	local baseName = SpellRanks.GetSpellBaseNameForAction(actionID)
	if not baseName then
		if rankBtn then
			rankBtn:Hide()
		end
		return
	end

	local rankEntry = SpellRanks.GetRankEntryForAction(actionID)
	if (not subtext or subtext == "") and rankEntry and rankEntry.subName and rankEntry.subName ~= "" then
		subtext = rankEntry.subName
	end

	if not subtext or subtext == "" then
		if rankBtn then
			rankBtn:Hide()
		end
		return
	end

	local showRankInName = Database.Get("showRankInName")
	local highlightDownranks = Database.Get("highlightDownranks")
	local showRankSwitcher = Database.Get("showRankSwitcher")

	local hasMultipleRanks = rankEntry and rankEntry.group and #rankEntry.group.entries > 1
	local maxEntry = hasMultipleRanks and rankEntry.group.maxEntry or nil
	local isMaxRank = (not hasMultipleRanks) or (maxEntry and maxEntry.actionID == rankEntry.actionID)
	local isDisabled = elementData.unbound

	local formattedName
	if not showRankInName then
		formattedName = (isDisabled and DISABLED_FONT_COLOR)
			and DISABLED_FONT_COLOR:WrapTextInColorCode(baseName)
			or baseName
	elseif isDisabled and DISABLED_FONT_COLOR then
		if highlightDownranks and hasMultipleRanks and not isMaxRank and maxEntry and maxEntry.rankNum then
			local maxHint = string.format(L["MAX_RANK_HINT_FORMAT"], maxEntry.rankNum)
			formattedName = DISABLED_FONT_COLOR:WrapTextInColorCode(string.format("%s (%s%s)", baseName, subtext, maxHint))
		else
			formattedName = DISABLED_FONT_COLOR:WrapTextInColorCode(string.format("%s (%s)", baseName, subtext))
		end
	else
		if highlightDownranks and hasMultipleRanks then
			if isMaxRank then
				formattedName = string.format("%s %s(%s)%s %s%s%s", baseName, Colors.RANK_MAX, subtext, Colors.RESET, Colors.TAG_MAX, L["TAG_MAX"], Colors.RESET)
			else
				local maxHint = (maxEntry and maxEntry.rankNum) and string.format(L["MAX_RANK_HINT_FORMAT"], maxEntry.rankNum) or ""
				formattedName = string.format("%s %s(%s%s)%s", baseName, Colors.RANK_DOWN, subtext, maxHint, Colors.RESET)
			end
		else
			formattedName = string.format("%s %s(%s)%s", baseName, Colors.RANK_MAX, subtext, Colors.RESET)
		end
	end

	if lineFrame.Name then
		lineFrame.Name:SetText(formattedName)
	end

	if rankBtn then
		if showRankSwitcher and hasMultipleRanks then
			local shortRank = SpellRanks.ExtractShortRankText(subtext) or subtext
			if highlightDownranks and isMaxRank then
				rankBtn.Text:SetText(string.format("%s%s (%s)%s", Colors.TAG_MAX, shortRank, L["TAG_MAX_SHORT"], Colors.RESET))
				if rankBtn.Bg then
					rankBtn.Bg:SetVertexColor(0.82, 1.0, 0.85, 1.0)
				end
			elseif highlightDownranks and not isMaxRank then
				rankBtn.Text:SetText(string.format("%s%s%s", Colors.RANK_DOWN, shortRank, Colors.RESET))
				if rankBtn.Bg then
					rankBtn.Bg:SetVertexColor(1.0, 0.88, 0.72, 1.0)
				end
			else
				rankBtn.Text:SetText(string.format("%s%s%s", Colors.RANK_MAX, shortRank, Colors.RESET))
				if rankBtn.Bg then
					rankBtn.Bg:SetVertexColor(1.0, 1.0, 1.0, 1.0)
				end
			end
			rankBtn:Show()
		else
			rankBtn:Hide()
		end
	end
end

function ClickBindingUI.UpdateLineWithRank(lineFrame, elementData)
	if not lineFrame then
		return
	end

	elementData = elementData or (lineFrame.GetElementData and lineFrame:GetElementData())
	local delBtn = EnsureDeleteButtonStyled(lineFrame)
	local showDelete = ShouldShowDeleteButton(lineFrame, elementData)
	if delBtn then
		delBtn._bccAllowHide = not showDelete
		delBtn:SetShown(showDelete)
		delBtn._bccAllowHide = false
	end

	if lineFrame.BCCRankButton then
		lineFrame.BCCRankButton:Hide()
	end

	if not elementData or not elementData.bindingInfo or not Constants.IsSpellOrPetBinding(elementData.bindingInfo) then
		return
	end

	local actionID = elementData.bindingInfo.actionID
	if not actionID then
		return
	end

	local subtext = SpellRanks.GetSpellSubtextForAction(actionID)
	if subtext then
		ApplyRankToLine(lineFrame, elementData, subtext)
		return
	end

	local rankEntry = SpellRanks.GetRankEntryForAction(actionID)
	if rankEntry and rankEntry.subName and rankEntry.subName ~= "" then
		ApplyRankToLine(lineFrame, elementData, rankEntry.subName)
		return
	end

	-- C_Spell.GetSpellSubtext lädt laut Blizzard-Dokumentation asynchron nach;
	-- vor dem Schreiben wird geprüft, ob das recycelte Frame noch dasselbe elementData hält.
	if Spell and Spell.CreateFromSpellID then
		local spell = Spell:CreateFromSpellID(actionID)
		spell:ContinueOnSpellLoad(function()
			local currentData = lineFrame.GetElementData and lineFrame:GetElementData() or elementData
			if currentData ~= elementData then
				return
			end
			if not elementData.bindingInfo or elementData.bindingInfo.actionID ~= actionID then
				return
			end
			local loadedSubtext = SpellRanks.GetSpellSubtextForAction(actionID)
			if loadedSubtext then
				ApplyRankToLine(lineFrame, elementData, loadedSubtext)
			end
		end)
	end
end

local function HookHeaderFrame(headerFrame)
	if not headerFrame or headerFrame._bccHeaderHooked then
		return
	end
	if type(headerFrame.Init) == "function" and (not ClickBindingHeaderMixin or headerFrame.Init ~= ClickBindingHeaderMixin.Init) then
		hooksecurefunc(headerFrame, "Init", function(self, elementData)
			UpdateHeaderFrame(self, elementData)
		end)
	end
	headerFrame._bccHeaderHooked = true
end

local function HookLineFrame(lineFrame)
	if not lineFrame then
		return
	end

	if not lineFrame._bccInitHooked and type(lineFrame.Init) == "function" then
		if not ClickBindingLineMixin or lineFrame.Init ~= ClickBindingLineMixin.Init then
			hooksecurefunc(lineFrame, "Init", function(self, elementData)
				ClickBindingUI.UpdateLineWithRank(self, elementData)
			end)
		end
		lineFrame._bccInitHooked = true
	end

	if not lineFrame._bccHoverHooked then
		lineFrame:HookScript("OnEnter", function(self)
			ClickBindingUI.ShowLineTooltip(self)
		end)
		lineFrame:HookScript("OnLeave", function(self)
			if self.DeleteButton and ShouldShowDeleteButton(self) then
				self.DeleteButton:Show()
			end
			if self.BCCRankButton and self.BCCRankButton:IsMouseMotionFocus() then
				return
			end
			if GameTooltip:GetOwner() == self then
				GameTooltip:Hide()
			end
		end)
		lineFrame._bccHoverHooked = true
	end
end

function ClickBindingUI.RefreshVisibleLines()
	if ClickBindingFrame and ClickBindingFrame:IsShown() and ClickBindingFrame.ScrollBox and ClickBindingFrame.ScrollBox.ForEachFrame then
		ClickBindingFrame.ScrollBox:ForEachFrame(function(frame)
			local elementData = frame.GetElementData and frame:GetElementData()
			if elementData and (elementData.elementType == ElementDataTypes.DefaultsHeader or elementData.elementType == ElementDataTypes.CustomsHeader) then
				HookHeaderFrame(frame)
				UpdateHeaderFrame(frame, elementData)
			else
				HookLineFrame(frame)
				ClickBindingUI.UpdateLineWithRank(frame, elementData)
			end
		end)
	end
end

local function RefreshSpellBookRanksDisplay()
	if PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame and PlayerSpellsFrame.SpellBookFrame.UpdateDisplayedSpells then
		PlayerSpellsFrame.SpellBookFrame:UpdateDisplayedSpells(true, false)
	end
end

function ClickBindingUI.SyncAutoShowAllRanks()
	if InCombatLockdown and InCombatLockdown() then
		return
	end
	if not ClickBindingFrame or not GetCVarBool or not SetCVar then
		return
	end

	if ClickBindingFrame:IsShown() then
		if Database.Get("autoShowAllRanks") then
			if not GetCVarBool("ShowAllSpellRanks") then
				restoredAllRanksOnClose = true
				SetCVar("ShowAllSpellRanks", 1)
				RefreshSpellBookRanksDisplay()
			end
		elseif restoredAllRanksOnClose then
			restoredAllRanksOnClose = false
			SetCVar("ShowAllSpellRanks", 0)
			RefreshSpellBookRanksDisplay()
		end
	elseif restoredAllRanksOnClose then
		restoredAllRanksOnClose = false
		SetCVar("ShowAllSpellRanks", 0)
		RefreshSpellBookRanksDisplay()
	end
end

function ClickBindingUI.SetupHooks()
	if isHooked or not ClickBindingFrame or not ClickBindingLineMixin then
		return
	end
	isHooked = true

	-- 0. Settings-Button im ClickBindingFrame einrichten
	if SettingsUI and SettingsUI.AttachToClickBindingFrame then
		SettingsUI.AttachToClickBindingFrame()
	end

	-- Auto-Show-All-Spell-Ranks und Zauberbuch-Sync beim Öffnen und Schließen des ClickBindingFrames
	ClickBindingFrame:HookScript("OnShow", function()
		ClickBindingUI.SyncAutoShowAllRanks()
		ClickBindingUI.RebuildGroups()
		if SpellBookUI and SpellBookUI.RefreshBadges then
			SpellBookUI.RefreshBadges()
		end
	end)

	ClickBindingFrame:HookScript("OnHide", function()
		ClickBindingUI.SyncAutoShowAllRanks()
		if SpellBookUI and SpellBookUI.RefreshBadges then
			SpellBookUI.RefreshBadges()
		end
	end)

	-- 1. Hooks auf Mixin-Ebene für Zeilen und Header
	hooksecurefunc(ClickBindingLineMixin, "Init", function(lineFrame, elementData)
		HookLineFrame(lineFrame)
		ClickBindingUI.UpdateLineWithRank(lineFrame, elementData)
	end)

	if ClickBindingHeaderMixin and ClickBindingHeaderMixin.Init then
		hooksecurefunc(ClickBindingHeaderMixin, "Init", function(headerFrame, elementData)
			HookHeaderFrame(headerFrame)
			UpdateHeaderFrame(headerFrame, elementData)
		end)
	end

	-- 2. Bestehende und neu erworbene Frames in der ScrollBox nachrüsten
	if ClickBindingFrame.ScrollBox then
		if ClickBindingFrame.ScrollBox.ForEachFrame then
			ClickBindingFrame.ScrollBox:ForEachFrame(function(frame)
				local elementData = frame.GetElementData and frame:GetElementData()
				if elementData and (elementData.elementType == ElementDataTypes.DefaultsHeader or elementData.elementType == ElementDataTypes.CustomsHeader) then
					HookHeaderFrame(frame)
					UpdateHeaderFrame(frame, elementData)
				else
					HookLineFrame(frame)
					ClickBindingUI.UpdateLineWithRank(frame, elementData)
				end
			end)
		end

		if ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnAcquiredFrame then
			ClickBindingFrame.ScrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnAcquiredFrame, function(_, frame, elementData)
				if elementData and (elementData.elementType == ElementDataTypes.DefaultsHeader or elementData.elementType == ElementDataTypes.CustomsHeader) then
					HookHeaderFrame(frame)
					UpdateHeaderFrame(frame, elementData)
				else
					HookLineFrame(frame)
					ClickBindingUI.UpdateLineWithRank(frame, elementData)
				end
			end, ns)
		end
	end

	-- 3. Bei Refresh, CleanDataProvider und ResetToDefaultProfile Gruppen und Cache aktualisieren
	if ClickBindingFrame.Refresh then
		hooksecurefunc(ClickBindingFrame, "Refresh", function()
			SpellRanks.InvalidateCache()
			ClickBindingUI.RebuildGroups()
			if SpellBookUI and SpellBookUI.RefreshBadges then
				SpellBookUI.RefreshBadges()
			end
		end)
	end

	if ClickBindingFrame.CleanDataProvider then
		hooksecurefunc(ClickBindingFrame, "CleanDataProvider", function()
			ClickBindingUI.RebuildGroups()
		end)
	end

	if ClickBindingFrame.ResetToDefaultProfile then
		hooksecurefunc(ClickBindingFrame, "ResetToDefaultProfile", function()
			ClickBindingUI.RebuildGroups()
		end)
	end

	-- Falls ClickBindingFrame beim erstmaligen Laden bereits offen ist, sofort synchronisieren
	if ClickBindingFrame:IsShown() then
		ClickBindingUI.SyncAutoShowAllRanks()
		ClickBindingUI.RebuildGroups()
		ClickBindingUI.RefreshVisibleLines()
	end

	-- 4. Warnmeldung beim Überschreiben einer Taste ebenfalls mit Zauberrang versehen
	if ClickBindingFrame.SetUnboundText and CLICK_BINDING_UNBOUND_OUTPUT then
		hooksecurefunc(ClickBindingFrame, "SetUnboundText", function(self, elementData)
			if not elementData or not elementData.bindingInfo or not Constants.IsSpellOrPetBinding(elementData.bindingInfo) then
				return
			end
			local actionID = elementData.bindingInfo.actionID
			local baseName = SpellRanks.GetSpellBaseNameForAction(actionID)
			local subtext = SpellRanks.GetSpellSubtextForAction(actionID)
			if baseName and subtext and subtext ~= "" and self.UnboundText then
				local fullSpellName = string.format("%s (%s)", baseName, subtext)
				self.UnboundText:SetText(string.format(CLICK_BINDING_UNBOUND_OUTPUT, fullSpellName))
			end
		end)
	end

	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("ClickBindingFrame.UpdateFrames", function()
			if SpellBookUI and SpellBookUI.RefreshBadges then
				SpellBookUI.RefreshBadges()
			end
		end, ns)
	end
end
