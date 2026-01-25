local _, ns = ...
local oGlowClassic = ns.oGlowClassic
local colorTable = ns.colorTable
local threshold = 1
local questEnabled = true

local questCacheByItemID = {}

local function isQuestItemByTooltip(itemLink, itemID)
	if not (C_TooltipInfo and (C_TooltipInfo.GetHyperlink or C_TooltipInfo.GetItemByID)) then
		return false
	end

	local tooltipInfo
	if itemLink and C_TooltipInfo.GetHyperlink then
		tooltipInfo = C_TooltipInfo.GetHyperlink(itemLink)
	elseif itemID and C_TooltipInfo.GetItemByID then
		tooltipInfo = C_TooltipInfo.GetItemByID(itemID)
	end

	if not (tooltipInfo and tooltipInfo.lines) then
		return false
	end

	local questItemText = _G.ITEM_BIND_QUEST
	local startsQuestText = _G.ITEM_STARTS_QUEST
	for _, line in ipairs(tooltipInfo.lines) do
		local leftText = line and line.leftText
		if leftText then
			if questItemText and leftText:find(questItemText, 1, true) then
				return true
			end
			if startsQuestText and leftText:find(startsQuestText, 1, true) then
				return true
			end
			-- Fallback for cases where globals aren't present/complete.
			if leftText == "Quest Item" or leftText == "Starts a Quest" then
				return true
			end
		end
	end

	return false
end

local function isQuestItem(itemLinkOrID)
	if not itemLinkOrID then
		return false
	end

	local itemLink = type(itemLinkOrID) == "string" and itemLinkOrID or nil
	local itemID = type(itemLinkOrID) == "number" and itemLinkOrID or nil

	-- Fast path: item info instant classification.
	if C_Item and C_Item.GetItemInfoInstant then
		local classID = select(6, C_Item.GetItemInfoInstant(itemLinkOrID))
		if classID ~= nil then
			local questClass = (Enum and Enum.ItemClass and Enum.ItemClass.Questitem) or _G.LE_ITEM_CLASS_QUESTITEM
			if questClass ~= nil and classID == questClass then
				return true
			end
		end
	end

	-- Cache by itemID when possible to avoid repeated tooltip scans.
	if not itemID and itemLink and C_Item and C_Item.GetItemInfoInstant then
		itemID = select(1, C_Item.GetItemInfoInstant(itemLink))
	end

	if itemID and questCacheByItemID[itemID] ~= nil then
		return questCacheByItemID[itemID]
	end

	local isQuest = isQuestItemByTooltip(itemLink, itemID)
	if itemID then
		questCacheByItemID[itemID] = isQuest
	end
	return isQuest
end

local function normalizeItemLink(itemLinkOrID)
	if not itemLinkOrID then
		return nil
	end

	if type(itemLinkOrID) == "string" then
		-- Sometimes callers pass an itemID as a string.
		local asNumber = tonumber(itemLinkOrID)
		if asNumber and not itemLinkOrID:find(":") then
			itemLinkOrID = asNumber
		else
			return itemLinkOrID
		end
	end

	if type(itemLinkOrID) == "number" then
		return itemLinkOrID
	end

	return nil
end

local function getCachedItemQuality(itemRef)
	if not itemRef then
		return nil
	end

	if C_Item and C_Item.GetItemInfo then
		local itemName, itemLink, itemQuality = C_Item.GetItemInfo(itemRef)
		return itemQuality
	end

	if type(GetItemInfo) == "function" then
		local itemName, itemLink, itemQuality = GetItemInfo(itemRef)
		return itemQuality
	end

	return nil
end

local function scheduleRefreshAfterLoad(slot, itemRef)
	if not (slot and Item and (Item.CreateFromItemLink or Item.CreateFromItemID)) then
		return
	end

	if slot.oGlowClassicQualityLoadPending then
		return
	end
	slot.oGlowClassicQualityLoadPending = true

	local item
	if type(itemRef) == "number" then
		if Item.CreateFromItemID then
			item = Item:CreateFromItemID(itemRef)
		elseif Item.CreateFromItemLink then
			item = Item:CreateFromItemLink("item:" .. itemRef)
		end
	elseif type(itemRef) == "string" then
		if Item.CreateFromItemLink then
			item = Item:CreateFromItemLink(itemRef)
		end
	end

	if not (item and not item:IsItemEmpty()) then
		slot.oGlowClassicQualityLoadPending = nil
		return
	end

	item:ContinueOnItemLoad(function()
		slot.oGlowClassicQualityLoadPending = nil
		if oGlowClassic and oGlowClassic.RefreshFrame then
			oGlowClassic:RefreshFrame(slot)
		end
	end)
end

local qualityFunc = function(slot, ...)
	local bestQuality = -1
	local hasQuestItem = false
	local missingInfo = false

	for i = 1, select('#', ...) do
		local itemRef = normalizeItemLink(select(i, ...))
		if itemRef then
			if questEnabled and not hasQuestItem and rawget(colorTable, 'quest') then
				if isQuestItem(itemRef) then
					hasQuestItem = true
				end
			end

			local q = getCachedItemQuality(itemRef)
			if q ~= nil then
				bestQuality = math.max(bestQuality, q)
			else
				missingInfo = true
				scheduleRefreshAfterLoad(slot, itemRef)
			end
		end
	end

	if questEnabled and hasQuestItem and rawget(colorTable, 'quest') then
		return 'quest'
	end

	if bestQuality > threshold then
		return bestQuality
	end

	-- If we don't have enough info yet, return nil for now and refresh later.
	if missingInfo then
		return nil
	end
end

oGlowClassic:RegisterOptionCallback(function(db)
    local filters = db.FilterSettings
    if filters and filters.quality then
        threshold = filters.quality
    else
        threshold = 1
    end

    questEnabled = not (filters and filters.questItems == false)
end)

oGlowClassic:RegisterFilter(
    'Quality border',
    'Border',
    qualityFunc,
    [[Adds a border to the icons, indicating the quality the items have.]]
)
