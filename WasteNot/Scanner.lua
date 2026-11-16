local _, ns = ...

-- C_TradeSkillUI.GetAllRecipeIDs() only returns data while a profession window
-- is open, so we scan when Cooking is shown and cache the result per character.

-- Both checks return nil when the API needed to answer is unavailable.
local function isCookingRecipe(recipeID)
	if not C_TradeSkillUI.GetTradeSkillLineForRecipe then return nil end
	local tradeSkillID, _, parentTradeSkillID = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)
	return tradeSkillID == ns.COOKING_SKILL_LINE or parentTradeSkillID == ns.COOKING_SKILL_LINE
end

local function isCookingOpen()
	if not C_TradeSkillUI.GetBaseProfessionInfo then return nil end
	local info = C_TradeSkillUI.GetBaseProfessionInfo()
	if not info then return nil end
	return info.professionID == ns.COOKING_SKILL_LINE or info.parentProfessionID == ns.COOKING_SKILL_LINE
end

-- Viewing someone else's recipes (chat link, guild list, NPC crafting order) must not
-- overwrite our own cache.
local function isViewingOwnProfession()
	if C_TradeSkillUI.IsTradeSkillLinked and C_TradeSkillUI.IsTradeSkillLinked() then return false end
	if C_TradeSkillUI.IsTradeSkillGuild and C_TradeSkillUI.IsTradeSkillGuild() then return false end
	if C_TradeSkillUI.IsNPCCrafting and C_TradeSkillUI.IsNPCCrafting() then return false end
	return true
end

local function reagentItemID(reagent)
	return reagent.itemID or (reagent.reagent and reagent.reagent.itemID)
end

local function readReagents(recipeID)
	local reagents = {}

	if C_TradeSkillUI.GetRecipeSchematic then
		local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
		if not schematic or not schematic.reagentSlotSchematics then return nil end
		local basic = Enum.CraftingReagentType and Enum.CraftingReagentType.Basic
		for _, slot in ipairs(schematic.reagentSlotSchematics) do
			if not basic or slot.reagentType == basic then
				for _, reagent in ipairs(slot.reagents or {}) do
					local itemID = reagentItemID(reagent)
					if itemID then
						reagents[itemID] = slot.quantityRequired or 1
					end
				end
			end
		end
		return reagents, schematic.outputItemID
	end

	-- Legacy (7.x-9.x) API, in case Forever exposes this instead.
	if C_TradeSkillUI.GetRecipeNumReagents then
		for i = 1, C_TradeSkillUI.GetRecipeNumReagents(recipeID) do
			local _, _, count = C_TradeSkillUI.GetRecipeReagentInfo(recipeID, i)
			local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, i)
			local itemID = link and GetItemInfoInstant(link)
			if itemID then reagents[itemID] = count or 1 end
		end
		return reagents
	end

	return nil
end

function ns.Scan()
	if not isViewingOwnProfession() then return end
	local cookingOpen = isCookingOpen()
	if cookingOpen == false then return end

	local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
	if not recipeIDs or #recipeIDs == 0 then return end

	local scanned = {}
	for _, recipeID in ipairs(recipeIDs) do
		local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
		local cooking = isCookingRecipe(recipeID)
		if cooking == nil then cooking = cookingOpen end -- nil + nil: can't tell, skip
		if info and info.learned and cooking then
			local reagents, outputItemID = readReagents(recipeID)
			if reagents and next(reagents) then
				scanned[recipeID] = {
					name = info.name,
					icon = info.icon,
					outputItemID = outputItemID,
					difficulty = info.relativeDifficulty,
					reagents = reagents,
				}
			end
		end
	end
	if not next(scanned) then return end -- keep the old cache rather than wiping it

	local before = ns.CountRecipes()
	WasteNotCharDB.recipes = scanned
	WasteNotCharDB.scannedAt = time()
	ns.RebuildIndex()
	ns.Prewarm()

	local after = ns.CountRecipes()
	if after ~= before then
		ns.Print(("learned %d Cooking recipes."):format(after))
	end
end

local pending = false
local function scheduleScan()
	if pending then return end
	pending = true
	C_Timer.After(0.5, function()
		pending = false
		ns.Scan()
	end)
end

local frame = CreateFrame("Frame")
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "NEW_RECIPE_LEARNED" }) do
	pcall(frame.RegisterEvent, frame, event) -- not every event is guaranteed to exist on Forever
end
frame:SetScript("OnEvent", scheduleScan)
