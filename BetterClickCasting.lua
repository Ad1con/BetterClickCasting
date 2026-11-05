local addonName, ns = ...

if SlashCmdList["BETTERCLICKCASTING"] then
	return
end

local L = ns.L
local Database = ns.Database
local SpellRanks = ns.SpellRanks
local ClickBindingUI = ns.ClickBindingUI
local SpellBookUI = ns.SpellBookUI
local MinimapButton = ns.MinimapButton

local loaderFrame = CreateFrame("Frame")
loaderFrame:RegisterEvent("ADDON_LOADED")
loaderFrame:RegisterEvent("PLAYER_LOGIN")
loaderFrame:RegisterEvent("SPELLS_CHANGED")
loaderFrame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")

loaderFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == addonName or arg1 == "BetterClickCasting" or arg1 == "BetterClickCastings" then
			Database.Init()
			MinimapButton.Init()
		end
		if ClickBindingFrame then
			ClickBindingUI.SetupHooks()
		end
		if SpellBookItemMixin then
			SpellBookUI.SetupHooks()
		end
	elseif event == "PLAYER_LOGIN" then
		Database.Init()
		MinimapButton.Init()
		if ClickBindingFrame then
			ClickBindingUI.SetupHooks()
		end
		if SpellBookItemMixin then
			SpellBookUI.SetupHooks()
		end
	elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_SKILL_LINE" then
		SpellRanks.InvalidateCache()
		ClickBindingUI.RefreshVisibleLines()
		SpellBookUI.RefreshBadges()
	end
end)

if ToggleClickBindingFrame then
	hooksecurefunc("ToggleClickBindingFrame", function()
		if ClickBindingFrame then
			ClickBindingUI.SetupHooks()
		end
	end)
end

--------------------------------------------------------------------------------
-- Slash-Commands (/bcc, /betterclickcasting)
--------------------------------------------------------------------------------

SLASH_BETTERCLICKCASTING1 = "/bcc"
SLASH_BETTERCLICKCASTING2 = "/betterclickcasting"
SLASH_BETTERCLICKCASTING3 = "/betterclickcastings"
SlashCmdList["BETTERCLICKCASTING"] = function(msg)
	local cmd = string.lower(strtrim(msg or ""))
	if cmd == "minimap" or cmd == "mm" then
		Database.Toggle("showMinimapButton")
	elseif cmd == "help" or cmd == "?" then
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(L["CHAT_HELP_HINT"])
		end
	else
		MinimapButton.ToggleClickCastingWindow()
	end
end
