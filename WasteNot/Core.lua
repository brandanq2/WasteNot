local ADDON_NAME, ns = ...

ns.COOKING_SKILL_LINE = 185

local DEFAULTS = {
	enabled = true,
	maxLines = 6,
	showEffect = true,
	showReagents = true,
}

local CHAR_DEFAULTS = {
	recipes = {},   -- [recipeID] = { name, outputItemID, difficulty, reagents = { [itemID] = qty } }
	scannedAt = nil,
}

-- itemID -> array of recipeIDs that use it. Rebuilt from WasteNotCharDB.recipes.
ns.usedIn = {}
ns.madeBy = {}

local function applyDefaults(db, defaults)
	for k, v in pairs(defaults) do
		if db[k] == nil then
			db[k] = type(v) == "table" and {} or v
		end
	end
end

function ns.Print(msg)
	print("|cff7fbf5fWasteNot|r: " .. msg)
end

function ns.RebuildIndex()
	local usedIn = {}
	local madeBy = {} -- outputItemID -> array of recipeIDs that create it
	for recipeID, recipe in pairs(WasteNotCharDB.recipes) do
		if recipe.outputItemID then
			local list = madeBy[recipe.outputItemID]
			if not list then
				list = {}
				madeBy[recipe.outputItemID] = list
			end
			list[#list + 1] = recipeID
		end
		for itemID in pairs(recipe.reagents) do
			local list = usedIn[itemID]
			if not list then
				list = {}
				usedIn[itemID] = list
			end
			list[#list + 1] = recipeID
		end
	end
	for _, list in pairs(usedIn) do
		table.sort(list, function(a, b)
			return (WasteNotCharDB.recipes[a].name or "") < (WasteNotCharDB.recipes[b].name or "")
		end)
	end
	ns.usedIn = usedIn
	ns.madeBy = madeBy
end

function ns.CountRecipes()
	local n = 0
	for _ in pairs(WasteNotCharDB.recipes) do n = n + 1 end
	return n
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		WasteNotDB = WasteNotDB or {}
		WasteNotCharDB = WasteNotCharDB or {}
		applyDefaults(WasteNotDB, DEFAULTS)
		applyDefaults(WasteNotCharDB, CHAR_DEFAULTS)
		ns.RebuildIndex()
		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		if not WasteNotCharDB.scannedAt then
			ns.Print("open your Cooking window once so I can learn your recipes.")
		end
		ns.Prewarm()
	end
end)

SLASH_WASTENOT1 = "/wastenot"
SLASH_WASTENOT2 = "/wn"
SlashCmdList.WASTENOT = function(input)
	local cmd = strtrim(input or ""):lower()
	if cmd == "toggle" then
		WasteNotDB.enabled = not WasteNotDB.enabled
		ns.Print("tooltips " .. (WasteNotDB.enabled and "enabled" or "disabled") .. ".")
	elseif cmd == "effects" then
		WasteNotDB.showEffect = not WasteNotDB.showEffect
		ns.Print("food effects " .. (WasteNotDB.showEffect and "shown" or "hidden") .. ".")
	elseif cmd == "reagents" then
		WasteNotDB.showReagents = not WasteNotDB.showReagents
		ns.Print("other ingredients " .. (WasteNotDB.showReagents and "shown" or "hidden") .. ".")
	elseif cmd == "reset" then
		wipe(WasteNotCharDB.recipes)
		WasteNotCharDB.scannedAt = nil
		ns.RebuildIndex()
		ns.Print("recipe cache cleared. Open your Cooking window to rescan.")
	elseif cmd:match("^lines %d+$") then
		WasteNotDB.maxLines = tonumber(cmd:match("%d+"))
		ns.Print("showing up to " .. WasteNotDB.maxLines .. " recipes per tooltip.")
	else
		local when = WasteNotCharDB.scannedAt and date("%Y-%m-%d %H:%M", WasteNotCharDB.scannedAt) or "never"
		ns.Print(("%d known Cooking recipes cached (last scan: %s)."):format(ns.CountRecipes(), when))
		ns.Print("/wn toggle | /wn effects | /wn reagents | /wn lines <n> | /wn reset")
	end
end
