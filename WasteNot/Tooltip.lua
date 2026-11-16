local _, ns = ...

-- Recipe colours match the profession window: orange / yellow / green / grey.
local DIFFICULTY_COLOR = {
	[0] = "ffff8040", -- Optimal
	[1] = "ffffff00", -- Medium
	[2] = "ff40bf40", -- Easy
	[3] = "ff808080", -- Trivial
}

local HAVE_COLOR = "ff40bf40"
local MISSING_COLOR = "ffff5050"
local INDENT = "      "

local function recipeLine(recipe, recipeID)
	local icon = recipe.icon or ns.ItemIcon(recipe.outputItemID)
	local left = (icon and ("|T%s:0|t "):format(icon) or "") ..
		("|c%s%s|r"):format(DIFFICULTY_COLOR[recipe.difficulty] or "ffffffff", recipe.name or ("Recipe " .. recipeID))
	local right = WasteNotDB.showEffect and ns.FoodEffect(recipe.outputItemID) or ""
	return left, right
end

-- One line per ingredient ("Tender Crocolisk Meat 20/1"): firstItemID (the hovered
-- reagent, if any) first, then the rest alphabetically, each coloured by whether you
-- carry enough.
local function reagentLines(recipe, firstItemID)
	local others = {}
	for reagentID, need in pairs(recipe.reagents) do
		if reagentID ~= firstItemID then
			others[#others + 1] = { id = reagentID, name = ns.ItemName(reagentID) or "...", need = need }
		end
	end
	table.sort(others, function(a, b) return a.name < b.name end)
	if firstItemID and recipe.reagents[firstItemID] then
		table.insert(others, 1, { id = firstItemID, name = ns.ItemName(firstItemID) or "...", need = recipe.reagents[firstItemID] })
	end

	local lines = {}
	for i, r in ipairs(others) do
		local have = ns.BagCount(r.id)
		lines[i] = ("%s|c%s%s %d/%d|r"):format(INDENT, have >= r.need and HAVE_COLOR or MISSING_COLOR, r.name, have, r.need)
	end
	return lines
end

-- How many times the recipe can be cooked from what's in your bags.
local function craftableCount(recipe)
	local count
	for reagentID, need in pairs(recipe.reagents) do
		local n = math.floor(ns.BagCount(reagentID) / need)
		if not count or n < count then count = n end
	end
	return count or 0
end

-- Hovering a food you can cook: show its ingredients.
local function addMadeByLines(tooltip, itemID)
	local recipeIDs = ns.madeBy[itemID]
	if not recipeIDs then return end

	tooltip:AddLine(" ")
	tooltip:AddDoubleLine("Cooked from", "WasteNot", 0.5, 0.75, 0.37, 0.45, 0.45, 0.45)
	for _, recipeID in ipairs(recipeIDs) do
		local recipe = WasteNotCharDB.recipes[recipeID]
		if #recipeIDs > 1 then
			tooltip:AddLine((recipeLine(recipe, recipeID))) -- name only; effect is already in the item's tooltip
		end
		local n = craftableCount(recipe)
		for i, line in ipairs(reagentLines(recipe)) do
			if i == 1 and n > 0 then
				tooltip:AddDoubleLine(line, "Can make " .. n, 1, 1, 1, 0.25, 0.75, 0.25)
			else
				tooltip:AddLine(line)
			end
		end
	end
end

local function addLines(tooltip, itemID)
	if not WasteNotDB or not WasteNotDB.enabled or not itemID then return end
	if issecretvalue and issecretvalue(itemID) then return end

	addMadeByLines(tooltip, itemID)

	local recipeIDs = ns.usedIn[itemID]
	if not recipeIDs then return end

	tooltip:AddLine(" ")
	tooltip:AddDoubleLine("Cooking recipes that use this", "WasteNot", 0.5, 0.75, 0.37, 0.45, 0.45, 0.45)

	local maxLines = WasteNotDB.maxLines or 6
	for i, recipeID in ipairs(recipeIDs) do
		if i > maxLines then
			tooltip:AddLine(("%s...and %d more"):format(INDENT, #recipeIDs - maxLines), 0.6, 0.6, 0.6)
			break
		end
		local recipe = WasteNotCharDB.recipes[recipeID]
		local left, right = recipeLine(recipe, recipeID)
		tooltip:AddDoubleLine(left, right, 1, 1, 1, 0.85, 0.85, 0.85)

		if WasteNotDB.showReagents then
			for _, line in ipairs(reagentLines(recipe, itemID)) do
				tooltip:AddLine(line)
			end
		end
	end
end

if TooltipDataProcessor and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		if data then addLines(tooltip, data.id) end
	end)
else
	-- Fallback if Forever turns out not to ship the 10.0+ tooltip data system.
	local function onSetItem(tooltip)
		local _, link = tooltip:GetItem()
		if link then addLines(tooltip, (GetItemInfoInstant(link))) end
	end
	GameTooltip:HookScript("OnTooltipSetItem", onSetItem)
	ItemRefTooltip:HookScript("OnTooltipSetItem", onSetItem)
end
