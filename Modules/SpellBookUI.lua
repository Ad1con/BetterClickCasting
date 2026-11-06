local _, ns = ...

local L = ns.L
local Constants = ns.Constants
local Colors = Constants.Colors
local Database = ns.Database
local SpellRanks = ns.SpellRanks

local SpellBookUI = {}
ns.SpellBookUI = SpellBookUI

local isHooked = false

local function AppendSpellBookBindingTooltip(spellBookItemFrame)
	if not Database.Get("showSpellbookBadges") then
		return
	end
	if not spellBookItemFrame or not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() or spellBookItemFrame.isUnlearned then
		return
	end
	local itemInfo = spellBookItemFrame.spellBookItemInfo
	local actionID = itemInfo and itemInfo.actionID
	local spellID = itemInfo and itemInfo.spellID
	if not actionID and not spellID then
		return
	end

	local bindingsMap = SpellRanks.GetActiveBindingsByActionID()
	local bindings = (actionID and bindingsMap[actionID]) or (spellID and bindingsMap[spellID])
	local inClickBind = InClickBindingMode and InClickBindingMode()
	local showQuickHint = inClickBind and Database.Get("quickBindSpellbook") and spellBookItemFrame.canClickBind

	if (bindings and #bindings > 0) or showQuickHint then
		GameTooltip:AddLine(" ")
		if bindings and #bindings > 0 then
			for _, bInfo in ipairs(bindings) do
				GameTooltip:AddDoubleLine(
					L["SPELLBOOK_ALREADY_BOUND_LABEL"],
					Constants.GetFullBindingString(bInfo),
					0.25, 1.0, 0.25,
					1.0, 1.0, 1.0
				)
			end
		end
		if showQuickHint then
			GameTooltip:AddLine(L["SPELLBOOK_QUICK_BIND_HINT"], 0.6, 0.85, 1.0, true)
		end
		GameTooltip:Show()
	end
end

-- Taint-freier Tooltip-Helfer für unser Quick-Bind-Overlay:
-- Ruft ausschließlich GameTooltip-APIs auf, ohne SpellBookItemMixin:OnIconEnter/OnIconLeave
-- auszulösen (welche sonst PetActionBar:ClearPetActionHighlightMarks() und PetActionBar:Update()
-- aus dem Addon-Kontext aufrufen und PetActionBar.isShownExternal für den Kampf tainten).
local function ShowQuickBindSpellBookTooltip(spellBookItemFrame)
	if not spellBookItemFrame or not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() then
		return
	end
	if not GameTooltip or not spellBookItemFrame.Button then
		return
	end

	GameTooltip:SetOwner(spellBookItemFrame.Button, "ANCHOR_RIGHT")
	if spellBookItemFrame.inClickBindMode and not spellBookItemFrame.canClickBind and CLICK_BINDING_NOT_AVAILABLE then
		if GameTooltip_AddErrorLine then
			GameTooltip_AddErrorLine(GameTooltip, CLICK_BINDING_NOT_AVAILABLE)
		else
			GameTooltip:SetText(CLICK_BINDING_NOT_AVAILABLE, 1.0, 0.1, 0.1, 1.0, true)
		end
		GameTooltip:Show()
		return
	end

	if spellBookItemFrame.slotIndex and spellBookItemFrame.spellBank then
		GameTooltip:SetSpellBookItem(spellBookItemFrame.slotIndex, spellBookItemFrame.spellBank)
	end
	AppendSpellBookBindingTooltip(spellBookItemFrame)
	GameTooltip:Show()
end

local function EnsureSpellBookBindBadge(spellBookItemFrame)
	if not spellBookItemFrame or not spellBookItemFrame.Button then
		return nil
	end
	if spellBookItemFrame.BCCBindBadge then
		return spellBookItemFrame.BCCBindBadge
	end

	local badgeFrame = CreateFrame("Frame", nil, spellBookItemFrame.Button)
	badgeFrame:SetAllPoints(spellBookItemFrame.Button)
	badgeFrame:SetFrameLevel(spellBookItemFrame.Button:GetFrameLevel() + 6)

	-- Modernes abgerundetes Pill-Badge oben links auf dem Zauber-Icon (ohne eingebrannten Pfeil)
	local bg = badgeFrame:CreateTexture(nil, "OVERLAY", nil, 1)
	bg:SetAtlas("common-dropdown-c-button")
	bg:SetVertexColor(0.08, 0.12, 0.16, 0.92)
	bg:SetPoint("TOPLEFT", spellBookItemFrame.Button, "TOPLEFT", -2, 2)

	local text = badgeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	local fontPath, fontSize = text:GetFont()
	if fontPath and fontSize then
		text:SetFont(fontPath, math.max(10, fontSize - 1), "OUTLINE")
	end
	text:SetPoint("TOPLEFT", spellBookItemFrame.Button, "TOPLEFT", 2, -1)
	text:SetJustifyH("LEFT")

	bg:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 4, -2)

	badgeFrame.Bg = bg
	badgeFrame.Text = text
	badgeFrame:Hide()
	spellBookItemFrame.BCCBindBadge = badgeFrame
	return badgeFrame
end

local function EnsureSpellBookQuickBindOverlay(spellBookItemFrame)
	if not spellBookItemFrame or not spellBookItemFrame.Button then
		return nil
	end
	if spellBookItemFrame.BCCQuickBindButton then
		return spellBookItemFrame.BCCQuickBindButton
	end

	-- Eigenes Overlay-Button-Frame: Ist nur sichtbar, solange ClickBindingFrame offen
	-- und 1-Klick Direkt-Binden aktiv ist. Im normalen Spielbetrieb komplett versteckt (:Hide()),
	-- sodass Blizzards SpellBookItemButton zu 100 % untainted bleibt.
	local overlay = CreateFrame("Button", nil, spellBookItemFrame.Button)
	overlay:SetAllPoints(spellBookItemFrame.Button)
	overlay:SetFrameLevel(spellBookItemFrame.Button:GetFrameLevel() + 4)
	overlay:RegisterForClicks("AnyUp")
	overlay:RegisterForDrag("LeftButton")

	-- Wichtig: Niemals spellBookItemFrame:OnIconEnter() oder :OnIconLeave() aus dem Overlay aufrufen,
	-- da Blizzard dort PetActionBar:ClearPetActionHighlightMarks() und PetActionBar:Update() -> :Hide()
	-- aufruft und damit PET_ACTION_HIGHLIGHT_MARKS sowie PetActionBar.isShownExternal taintet.
	overlay:SetScript("OnEnter", function()
		if not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() then
			return
		end
		ShowQuickBindSpellBookTooltip(spellBookItemFrame)
		if not spellBookItemFrame.isUnlearned then
			if spellBookItemFrame.Button and spellBookItemFrame.Button.IconHighlight then
				spellBookItemFrame.Button.IconHighlight:Show()
			end
			if spellBookItemFrame.Backplate and spellBookItemFrame.hoverBackplateAlpha then
				spellBookItemFrame.Backplate:SetAlpha(spellBookItemFrame.hoverBackplateAlpha)
			end
		end
	end)

	overlay:SetScript("OnLeave", function()
		if spellBookItemFrame.Button and spellBookItemFrame.Button.IconHighlight then
			spellBookItemFrame.Button.IconHighlight:Hide()
			if spellBookItemFrame.iconHighlightHoverAlpha then
				spellBookItemFrame.Button.IconHighlight:SetAlpha(spellBookItemFrame.iconHighlightHoverAlpha)
			end
		end
		if spellBookItemFrame.Backplate and spellBookItemFrame.defaultBackplateAlpha then
			spellBookItemFrame.Backplate:SetAlpha(spellBookItemFrame.defaultBackplateAlpha)
		end
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)

	overlay:SetScript("OnMouseDown", function()
		if not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() then
			return
		end
		if not spellBookItemFrame.isUnlearned and spellBookItemFrame.Button and spellBookItemFrame.Button.IconHighlight and spellBookItemFrame.iconHighlightPressAlpha then
			spellBookItemFrame.Button.IconHighlight:SetAlpha(spellBookItemFrame.iconHighlightPressAlpha)
		end
	end)

	overlay:SetScript("OnMouseUp", function()
		if not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() then
			return
		end
		if not spellBookItemFrame.isUnlearned and spellBookItemFrame.Button and spellBookItemFrame.Button.IconHighlight and spellBookItemFrame.iconHighlightHoverAlpha then
			spellBookItemFrame.Button.IconHighlight:SetAlpha(spellBookItemFrame.iconHighlightHoverAlpha)
		end
	end)

	overlay:SetScript("OnDragStart", function()
		if not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() then
			return
		end
		if C_SpellBook and C_SpellBook.PickupSpellBookItem and spellBookItemFrame.slotIndex and spellBookItemFrame.spellBank then
			C_SpellBook.PickupSpellBookItem(spellBookItemFrame.slotIndex, spellBookItemFrame.spellBank)
		end
	end)

	overlay:SetScript("OnClick", function(_, mouseButton)
		if not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() then
			return
		end
		if not spellBookItemFrame.inClickBindMode or not spellBookItemFrame.canClickBind then
			return
		end
		local actionID = spellBookItemFrame.spellBookItemInfo and spellBookItemFrame.spellBookItemInfo.actionID
		if not actionID or not ns.ClickBindingUI or not ns.ClickBindingUI.QuickBindSpell then
			return
		end

		local actionType = nil
		if spellBookItemFrame.spellBank == Enum.SpellBookSpellBank.Player then
			actionType = Enum.ClickBindingType.Spell
		elseif spellBookItemFrame.spellBank == Enum.SpellBookSpellBank.Pet then
			actionType = Enum.ClickBindingType.PetAction
		end

		if actionType then
			local modifiers = (MakeModifiers and MakeModifiers()) or 0
			ns.ClickBindingUI.QuickBindSpell(actionType, actionID, mouseButton, modifiers)
			if GameTooltip and GameTooltip:IsOwned(spellBookItemFrame.Button) then
				ShowQuickBindSpellBookTooltip(spellBookItemFrame)
			end
		end
	end)

	overlay:Hide()
	spellBookItemFrame.BCCQuickBindButton = overlay
	return overlay
end

local function EnsureSpellBookQuickBindCheckbox()
	if not PlayerSpellsFrame or not PlayerSpellsFrame.SpellBookFrame then
		return nil
	end
	local sbFrame = PlayerSpellsFrame.SpellBookFrame
	if sbFrame.BCCQuickBindCheckbox then
		return sbFrame.BCCQuickBindCheckbox
	end

	-- Moderne abgerundete Pill-Leiste mit Checkbox und Maus-Icon unten links im Zauberbuch
	local cb = CreateFrame("CheckButton", nil, sbFrame, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	cb:SetPoint("BOTTOMLEFT", sbFrame, "BOTTOMLEFT", 36, 35)
	cb:SetFrameLevel(sbFrame.PagedSpellsFrame and (sbFrame.PagedSpellsFrame:GetFrameLevel() + 10) or 20)

	local pillBg = cb:CreateTexture(nil, "BACKGROUND")
	pillBg:SetAtlas("common-dropdown-c-button")
	pillBg:SetVertexColor(0.12, 0.10, 0.08, 0.88)

	local mouseIcon = cb:CreateTexture(nil, "ARTWORK")
	mouseIcon:SetSize(16, 16)
	mouseIcon:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	mouseIcon:SetAtlas(Constants.ICON_ATLAS)
	cb.MouseIcon = mouseIcon

	local label = cb.Text or cb.text or cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:ClearAllPoints()
	label:SetPoint("LEFT", mouseIcon, "RIGHT", 4, 0)
	label:SetText(L["SPELLBOOK_QUICK_BIND_CHECKBOX"])
	cb.Label = label

	pillBg:SetPoint("TOPLEFT", cb, "TOPLEFT", -6, 3)
	pillBg:SetPoint("BOTTOMRIGHT", label, "BOTTOMRIGHT", 10, -5)
	cb.PillBg = pillBg

	cb:SetHitRectInsets(-4, -180, -2, -2)

	cb:SetScript("OnClick", function(self)
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		Database.Set("quickBindSpellbook", self:GetChecked() and true or false)
	end)

	cb:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip_SetTitle(GameTooltip, L["SETTING_QUICK_BIND_SPELLBOOK"])
		GameTooltip_AddNormalLine(GameTooltip, L["SETTING_QUICK_BIND_SPELLBOOK_DESC"], true)
		GameTooltip:Show()
	end)

	cb:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	cb:Hide()
	sbFrame.BCCQuickBindCheckbox = cb
	return cb
end

function SpellBookUI.UpdateQuickBindCheckbox()
	local cb = EnsureSpellBookQuickBindCheckbox()
	if not cb then
		return
	end
	local inClickBind = (InClickBindingMode and InClickBindingMode()) and true or false
	local isChecked = Database.Get("quickBindSpellbook") and true or false
	cb:SetChecked(isChecked)
	if cb.Label then
		if isChecked then
			cb.Label:SetTextColor(0.35, 1.0, 0.45)
		else
			cb.Label:SetTextColor(0.85, 0.85, 0.85)
		end
	end
	cb:SetShown(inClickBind)
end

local function HookSpellBookItemInstance(spellBookItemFrame)
	if not spellBookItemFrame then
		return
	end
	if not spellBookItemFrame._bccTooltipHooked and type(spellBookItemFrame.ShowSpellBookTooltip) == "function" then
		if not SpellBookItemMixin or spellBookItemFrame.ShowSpellBookTooltip ~= SpellBookItemMixin.ShowSpellBookTooltip then
			hooksecurefunc(spellBookItemFrame, "ShowSpellBookTooltip", function(self)
				AppendSpellBookBindingTooltip(self)
			end)
		end
		spellBookItemFrame._bccTooltipHooked = true
	end
	if not spellBookItemFrame._bccStateHooked and type(spellBookItemFrame.UpdateClickBindState) == "function" then
		if not SpellBookItemMixin or spellBookItemFrame.UpdateClickBindState ~= SpellBookItemMixin.UpdateClickBindState then
			hooksecurefunc(spellBookItemFrame, "UpdateClickBindState", function(self)
				SpellBookUI.UpdateItemClickBindVisuals(self)
			end)
		end
		spellBookItemFrame._bccStateHooked = true
	end
	if not spellBookItemFrame._bccClearHooked and type(spellBookItemFrame.ClearSpellData) == "function" then
		if not SpellBookItemMixin or spellBookItemFrame.ClearSpellData ~= SpellBookItemMixin.ClearSpellData then
			hooksecurefunc(spellBookItemFrame, "ClearSpellData", function(self)
				if self.BCCBindBadge then
					self.BCCBindBadge:Hide()
				end
				if self.BCCQuickBindButton then
					self.BCCQuickBindButton:Hide()
				end
			end)
		end
		spellBookItemFrame._bccClearHooked = true
	end
end

function SpellBookUI.UpdateItemClickBindVisuals(spellBookItemFrame, bindingsMap)
	if not spellBookItemFrame then
		return
	end
	HookSpellBookItemInstance(spellBookItemFrame)

	local badgeFrame = EnsureSpellBookBindBadge(spellBookItemFrame)
	local quickBindOverlay = EnsureSpellBookQuickBindOverlay(spellBookItemFrame)

	if not spellBookItemFrame.HasValidData or not spellBookItemFrame:HasValidData() or spellBookItemFrame.isUnlearned then
		if badgeFrame then
			badgeFrame:Hide()
		end
		if quickBindOverlay then
			quickBindOverlay:Hide()
		end
		return
	end

	local inClickBind = (InClickBindingMode and InClickBindingMode()) and true or false
	local quickBindActive = inClickBind and Database.Get("quickBindSpellbook") and spellBookItemFrame.canClickBind

	if quickBindOverlay then
		quickBindOverlay:SetShown(quickBindActive and true or false)
	end

	-- Im 1-Klick-Direktbinde-Modus leuchten alle bindbaren Zauber im Zauberbuch
	if quickBindActive and spellBookItemFrame.Button and spellBookItemFrame.Button.ClickBindingHighlight then
		spellBookItemFrame.Button.ClickBindingHighlight:SetShown(true)
	end

	if not badgeFrame then
		return
	end

	if not Database.Get("showSpellbookBadges") then
		badgeFrame:Hide()
		return
	end

	bindingsMap = bindingsMap or SpellRanks.GetActiveBindingsByActionID()
	local itemInfo = spellBookItemFrame.spellBookItemInfo
	local actionID = itemInfo and itemInfo.actionID
	local spellID = itemInfo and itemInfo.spellID
	local bindings = (actionID and bindingsMap[actionID]) or (spellID and bindingsMap[spellID])
	if bindings and #bindings > 0 then
		local firstShort = Constants.GetShortBindingString(bindings[1]) or "✓"
		if #bindings > 1 then
			firstShort = string.format("%s +%d", firstShort, #bindings - 1)
		end
		badgeFrame.Text:SetText(Colors.BIND_BADGE .. firstShort .. Colors.RESET)
		badgeFrame:Show()
	else
		badgeFrame:Hide()
	end
end

function SpellBookUI.RefreshBadges()
	SpellBookUI.UpdateQuickBindCheckbox()
	if not PlayerSpellsFrame or not PlayerSpellsFrame.SpellBookFrame then
		return
	end
	local sbFrame = PlayerSpellsFrame.SpellBookFrame
	if not sbFrame.ForEachDisplayedSpell then
		return
	end
	local bindingsMap = SpellRanks.GetActiveBindingsByActionID()
	sbFrame:ForEachDisplayedSpell(function(itemFrame)
		SpellBookUI.UpdateItemClickBindVisuals(itemFrame, bindingsMap)
	end)
end

function SpellBookUI.SetupHooks()
	if isHooked or not SpellBookItemMixin then
		return
	end
	isHooked = true

	-- 1. Hooks auf Mixin-Ebene für alle künftig erzeugten Frames
	hooksecurefunc(SpellBookItemMixin, "UpdateClickBindState", function(self)
		SpellBookUI.UpdateItemClickBindVisuals(self)
	end)

	if SpellBookItemMixin.ClearSpellData then
		hooksecurefunc(SpellBookItemMixin, "ClearSpellData", function(self)
			if self and self.BCCBindBadge then
				self.BCCBindBadge:Hide()
			end
			if self and self.BCCQuickBindButton then
				self.BCCQuickBindButton:Hide()
			end
		end)
	end

	hooksecurefunc(SpellBookItemMixin, "ShowSpellBookTooltip", function(self)
		AppendSpellBookBindingTooltip(self)
	end)

	-- 2. Falls im Standard-Modus (Checkbox aus) im Zauberbuch geklickt wird, während NewSlot voll ist,
	-- bestehenden ungebundenen Zauber behalten statt ihn zu überschreiben
	hooksecurefunc(SpellBookItemMixin, "OnIconClick", function(self)
		if Database.Get("quickBindSpellbook") then
			return
		end
		if not self or not self.HasValidData or not self:HasValidData() then
			return
		end
		if not self.inClickBindMode or not self.canClickBind or not ClickBindingFrame then
			return
		end
		local actionID = self.spellBookItemInfo and self.spellBookItemInfo.actionID
		if not actionID or ClickBindingFrame:HasNewSlot() then
			return
		end

		local actionType = nil
		if self.spellBank == Enum.SpellBookSpellBank.Player then
			actionType = Enum.ClickBindingType.Spell
		elseif self.spellBank == Enum.SpellBookSpellBank.Pet then
			actionType = Enum.ClickBindingType.PetAction
		end

		if actionType and ClickBindingFrame.AddNewAction then
			ClickBindingFrame:AddNewAction(actionType, actionID)
		end
	end)

	-- 3. EventRegistry-Callbacks des Zauberbuchs (deckt auch bereits vorab erzeugte Pool-Frames ab)
	if EventRegistry and EventRegistry.RegisterCallback then
		EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged", function()
			SpellBookUI.RefreshBadges()
		end, ns)
		EventRegistry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Show", function()
			if ns.ClickBindingUI and ns.ClickBindingUI.SyncAutoShowAllRanks then
				ns.ClickBindingUI.SyncAutoShowAllRanks()
			end
			SpellBookUI.RefreshBadges()
		end, ns)
	end

	SpellBookUI.RefreshBadges()
end
