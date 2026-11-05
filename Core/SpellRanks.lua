local _, ns = ...

local Constants = ns.Constants

local SpellRanks = {}
ns.SpellRanks = SpellRanks

local cache = {
	dirty = true,
	byActionID = {}, -- [actionID] = rankEntry
	bySpellKey = {}, -- ["bank:spellName"] = { name, spellBank, entries = { ... }, maxEntry = rankEntry }
}

function SpellRanks.InvalidateCache()
	cache.dirty = true
end

function SpellRanks.ExtractRankNumber(subtext)
	if not subtext or subtext == "" then
		return nil
	end
	local num = string.match(subtext, "(%d+)")
	return num and tonumber(num) or nil
end

function SpellRanks.ExtractShortRankText(subtext)
	local rankNum = SpellRanks.ExtractRankNumber(subtext)
	if rankNum then
		return "R" .. rankNum
	end
	return nil
end

function SpellRanks.GetSpellSubtextForAction(actionID)
	if not actionID or not C_Spell or not C_Spell.GetSpellSubtext then
		return nil
	end

	local subtext = C_Spell.GetSpellSubtext(actionID)
	if subtext and subtext ~= "" then
		return subtext
	end

	if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
		local overrideID = C_SpellBook.FindSpellOverrideByID(actionID)
		if overrideID and overrideID ~= actionID then
			subtext = C_Spell.GetSpellSubtext(overrideID)
			if subtext and subtext ~= "" then
				return subtext
			end
		end
	end

	return nil
end

function SpellRanks.GetSpellBaseNameForAction(actionID)
	if not actionID or not C_Spell or not C_Spell.GetSpellInfo then
		return nil
	end

	local spellIDToQuery = actionID
	if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
		local overrideID = C_SpellBook.FindSpellOverrideByID(actionID)
		if overrideID then
			spellIDToQuery = overrideID
		end
	end

	local spellInfo = C_Spell.GetSpellInfo(spellIDToQuery)
	return spellInfo and spellInfo.name or nil
end

function SpellRanks.GetSpellPowerCostString(spellID)
	if not spellID or not C_Spell or not C_Spell.GetSpellPowerCost then
		return nil
	end
	local costs = C_Spell.GetSpellPowerCost(spellID)
	if not costs or #costs == 0 then
		return nil
	end
	local first = costs[1]
	if first and first.cost and first.cost > 0 then
		local powerName = (first.name and _G[first.name]) or first.name or ""
		if powerName ~= "" then
			return string.format("%d %s", first.cost, powerName)
		end
		return tostring(first.cost)
	end
	return nil
end

local function MakeSpellGroupKey(spellBank, spellName)
	return tostring(spellBank or 0) .. ":" .. tostring(spellName or "")
end

local function ScanSlotIntoCache(slotIndex, spellBank)
	if not C_SpellBook or not C_SpellBook.GetSpellBookItemInfo then
		return
	end

	local info = C_SpellBook.GetSpellBookItemInfo(slotIndex, spellBank)
	if not info or info.isPassive or info.isOffSpec then
		return
	end

	local isSpell = (Enum and Enum.SpellBookItemType and info.itemType == Enum.SpellBookItemType.Spell)
	local isPetAction = (Enum and Enum.SpellBookItemType and info.itemType == Enum.SpellBookItemType.PetAction)
	if not isSpell and not isPetAction then
		return
	end

	local actionID = info.actionID
	local spellID = info.spellID or actionID
	local name = info.name
	if not actionID or not name or name == "" then
		return
	end

	local subName = info.subName
	if not subName or subName == "" then
		subName = SpellRanks.GetSpellSubtextForAction(spellID) or SpellRanks.GetSpellSubtextForAction(actionID) or ""
	end

	local isLowRank = false
	if C_SpellBook.IsSpellBookItemLowRank then
		isLowRank = C_SpellBook.IsSpellBookItemLowRank(slotIndex, spellBank) or false
	end

	local rankNum = SpellRanks.ExtractRankNumber(subName)
	local groupKey = MakeSpellGroupKey(spellBank, name)
	local group = cache.bySpellKey[groupKey]
	if not group then
		group = {
			name = name,
			spellBank = spellBank,
			entries = {},
			seenActionIDs = {},
			maxEntry = nil,
		}
		cache.bySpellKey[groupKey] = group
	end

	local entry = group.seenActionIDs[actionID]
	if not entry then
		entry = {
			actionID = actionID,
			spellID = spellID,
			slotIndex = slotIndex,
			spellBank = spellBank,
			name = name,
			subName = subName,
			rankNum = rankNum,
			isLowRank = isLowRank,
			group = group,
		}
		group.seenActionIDs[actionID] = entry
		table.insert(group.entries, entry)
	else
		entry.slotIndex = slotIndex
		if (not entry.subName or entry.subName == "") and subName ~= "" then
			entry.subName = subName
			entry.rankNum = rankNum
		end
		entry.isLowRank = isLowRank
	end

	cache.byActionID[actionID] = entry
	if spellID and spellID ~= actionID then
		cache.byActionID[spellID] = entry
	end
end

function SpellRanks.EnsureCache()
	if not cache.dirty then
		return cache
	end

	cache.byActionID = {}
	cache.bySpellKey = {}

	if C_SpellBook and Enum and Enum.SpellBookSpellBank then
		local playerBank = Enum.SpellBookSpellBank.Player
		local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or 0
		for skillLineIndex = 1, numSkillLines do
			local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
			if skillLineInfo and not skillLineInfo.offSpecID and skillLineInfo.numSpellBookItems and skillLineInfo.itemIndexOffset then
				for i = 1, skillLineInfo.numSpellBookItems do
					local slotIndex = skillLineInfo.itemIndexOffset + i
					ScanSlotIntoCache(slotIndex, playerBank)
				end
			end
		end

		local petBank = Enum.SpellBookSpellBank.Pet
		local numPetSpells = C_SpellBook.HasPetSpells and C_SpellBook.HasPetSpells() or 0
		for slotIndex = 1, numPetSpells do
			ScanSlotIntoCache(slotIndex, petBank)
		end
	end

	for _, group in pairs(cache.bySpellKey) do
		table.sort(group.entries, function(a, b)
			if a.rankNum and b.rankNum and a.rankNum ~= b.rankNum then
				return a.rankNum < b.rankNum
			end
			return a.slotIndex < b.slotIndex
		end)

		local maxEntry = nil
		for i, entry in ipairs(group.entries) do
			entry.rankIndex = i
			if not entry.isLowRank then
				maxEntry = entry
			end
		end
		if not maxEntry and #group.entries > 0 then
			maxEntry = group.entries[#group.entries]
		end
		group.maxEntry = maxEntry
	end

	cache.dirty = false
	return cache
end

function SpellRanks.GetRankEntryForAction(actionID)
	if not actionID then
		return nil
	end
	local currentCache = SpellRanks.EnsureCache()
	local entry = currentCache.byActionID[actionID]
	if entry then
		return entry
	end

	if C_SpellBook and C_SpellBook.FindSpellOverrideByID then
		local overrideID = C_SpellBook.FindSpellOverrideByID(actionID)
		if overrideID and currentCache.byActionID[overrideID] then
			return currentCache.byActionID[overrideID]
		end
	end

	return nil
end

function SpellRanks.GetActiveBindingsByActionID()
	local map = {}

	local function AddBindingInfo(info)
		if info and info.button and info.actionID and Constants.IsSpellOrPetBinding(info) then
			local list = map[info.actionID]
			if not list then
				list = {}
				map[info.actionID] = list
			end
			table.insert(list, info)
		end
	end

	-- Solange das ClickBindingFrame geöffnet ist, hat dessen dataProvider Vorrang
	-- (damit auch noch ungespeicherte Änderungen live im Zauberbuch sichtbar sind).
	if ClickBindingFrame and ClickBindingFrame:IsShown() and ClickBindingFrame.dataProvider then
		for _, element in ClickBindingFrame.dataProvider:Enumerate() do
			if element and not element.unbound then
				AddBindingInfo(element.bindingInfo)
			end
		end
		return map
	end

	-- Ist das ClickBindingFrame geschlossen oder noch nicht geladen, liefert die native
	-- C-API C_ClickBindings.GetProfileInfo() jederzeit alle gespeicherten Belegungen.
	if C_ClickBindings and C_ClickBindings.GetProfileInfo then
		local profile = C_ClickBindings.GetProfileInfo()
		if type(profile) == "table" then
			for _, bindingInfo in ipairs(profile) do
				AddBindingInfo(bindingInfo)
			end
		end
	end

	return map
end
