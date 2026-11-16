local _, ns = ...

-- Item/spell lookups with fallbacks to the pre-namespace globals, and async
-- load requests so uncached names/descriptions show up on the next hover.

local GetItemNameByID = (C_Item and C_Item.GetItemNameByID) or function(id) return (GetItemInfo(id)) end
local GetItemIconByID = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
local GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local GetItemSpell = (C_Item and C_Item.GetItemSpell) or GetItemSpell
local GetSpellDescription = (C_Spell and C_Spell.GetSpellDescription) or GetSpellDescription
local RequestItem = (C_Item and C_Item.RequestLoadItemDataByID) or function() end
local RequestSpell = (C_Spell and C_Spell.RequestLoadSpellData) or function() end

local function isSecret(v)
	return issecretvalue and issecretvalue(v)
end

function ns.ItemName(itemID)
	local name = GetItemNameByID(itemID)
	if not name then RequestItem(itemID) end
	return name
end

function ns.ItemIcon(itemID)
	return itemID and GetItemIconByID(itemID)
end

function ns.BagCount(itemID)
	local n = GetItemCount(itemID)
	if not n or isSecret(n) then return 0 end
	return n
end

-- Food effect summary, e.g. "552 HP · +6 Sta & Spi". English descriptions only;
-- other locales simply show no effect text.
local STAT_ABBR = {
	Stamina = "Sta", Spirit = "Spi", Strength = "Str", Agility = "Agi", Intellect = "Int",
}

local function shortenBuff(s)
	s = s:gsub("^gain ", ""):gsub("^restore ", "")
	s = s:gsub(" mana every 5 seconds", " mp5"):gsub(" health every 5 seconds", " hp5")
	for long, short in pairs(STAT_ABBR) do
		s = s:gsub(long, short)
	end
	s = s:gsub(" and ", " & ")
	if s:match("^%d") then s = "+" .. s end
	return s
end

local effectCache = {} -- [itemID] = string, or false when there's nothing to show

function ns.FoodEffect(itemID)
	if not itemID then return nil end
	local cached = effectCache[itemID]
	if cached ~= nil then return cached or nil end

	local _, spellID = GetItemSpell(itemID)
	if not spellID then
		RequestItem(itemID)
		return nil
	end
	local desc = GetSpellDescription(spellID)
	if not desc or isSecret(desc) or desc == "" then
		RequestSpell(spellID)
		return nil
	end

	local parts = {}
	local heal = desc:match("[Rr]estores (%d+) health")
	if heal then parts[#parts + 1] = heal .. " HP" end
	local mana = desc:match("[Rr]estores %d+ health and (%d+) mana") or desc:match("[Rr]estores (%d+) mana")
	if mana then parts[#parts + 1] = mana .. " MP" end
	local buff = desc:match("well fed and (.-) for %d+")
	if buff then parts[#parts + 1] = shortenBuff(buff) end

	local effect = #parts > 0 and table.concat(parts, " · ") or false
	effectCache[itemID] = effect
	return effect or nil
end

-- Ask the client to cache everything the tooltip will need.
function ns.Prewarm()
	for _, recipe in pairs(WasteNotCharDB.recipes) do
		if recipe.outputItemID then ns.FoodEffect(recipe.outputItemID) end
		for itemID in pairs(recipe.reagents) do
			RequestItem(itemID)
		end
	end
end
