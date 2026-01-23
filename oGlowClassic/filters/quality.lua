local _, ns = ...
local oGlowClassic = ns.oGlowClassic
local colorTable = ns.colorTable
local threshold = 1
local questEnabled = true

local function updateBorderSize(border, owner)
	    if not (border and owner and UIParent and UIParent.GetEffectiveScale and owner.GetEffectiveScale) then
	        return
	    end

    local uiScale = UIParent:GetEffectiveScale()
    local ownerScale = owner:GetEffectiveScale()

    if type(uiScale) ~= "number" or uiScale <= 0 or type(ownerScale) ~= "number" or ownerScale <= 0 then
        return
    end

    local scaleFix = uiScale / ownerScale
	border:SetSize(70 * scaleFix, 70 * scaleFix)
end

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

local function scheduleDelayedBorderSizeRefresh(slot)
	if not (slot and slot.oGlowClassicIsBaganator and C_Timer and C_Timer.After) then
		return
	end

	if slot.oGlowClassicPendingScaleFix then
		return
	end
	slot.oGlowClassicPendingScaleFix = true

	local function refresh()
		if slot and slot.oGlowBorder then
			updateBorderSize(slot.oGlowBorder, slot.oGlowBorder:GetParent() or slot)
		end
	end

	C_Timer.After(0, refresh)
	C_Timer.After(0.1, function()
		refresh()
		if slot then
			slot.oGlowClassicPendingScaleFix = nil
		end
	end)
end

local function scheduleDelayedBaganatorIconBorderOverride(slot)
	if not (slot and slot.oGlowClassicIsBaganator and C_Timer and C_Timer.After) then
		return
	end

	if slot.oGlowClassicPendingIconBorderFix then
		return
	end
	slot.oGlowClassicPendingIconBorderFix = true

	local function apply()
		if not slot then
			return
		end

		local filters = oGlowClassicDB and oGlowClassicDB.FilterSettings
		local overrideBorder = not (filters and filters.baganatorOverride == false)

		if slot.IconBorder then
			if overrideBorder and slot.oGlowBorder and slot.oGlowBorder:IsShown() then
				if slot.oGlowClassicIconBorderAlpha == nil then
					slot.oGlowClassicIconBorderAlpha = slot.IconBorder:GetAlpha()
				end
				slot.IconBorder:SetAlpha(0)
			elseif slot.oGlowClassicIconBorderAlpha ~= nil then
				slot.IconBorder:SetAlpha(slot.oGlowClassicIconBorderAlpha)
				slot.oGlowClassicIconBorderAlpha = nil
			end
		end
	end

	C_Timer.After(0, apply)
	C_Timer.After(0.1, function()
		apply()
		if slot then
			slot.oGlowClassicPendingIconBorderFix = nil
		end
	end)
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

local qualityFunc = function(slot, ...)

    local quality = -1
    local hasQuestItem = false
    local pending = 0
    local completed = false

    local function applyFilter()
        if questEnabled and hasQuestItem and rawget(colorTable, 'quest') then
            oGlowClassic:ApplyBorder(slot, 'quest')
        elseif quality > threshold then
            oGlowClassic:ApplyBorder(slot, quality)
        else
            oGlowClassic:ClearBorder(slot)
        end
    end

    for i = 1, select('#', ...) do
        local itemRef = normalizeItemLink(select(i, ...))
        if itemRef then
            local item
            if type(itemRef) == "number" and Item and Item.CreateFromItemID then
                item = Item:CreateFromItemID(itemRef)
            elseif type(itemRef) == "number" and Item and Item.CreateFromItemLink then
                item = Item:CreateFromItemLink("item:" .. itemRef)
            elseif type(itemRef) == "string" then
                item = Item:CreateFromItemLink(itemRef)
            end

            if item and not item:IsItemEmpty() then
                pending = pending + 1

                item:ContinueOnItemLoad(function()
                    local itemQuality = item:GetItemQuality()
                    if itemQuality then
                        quality = math.max(quality, itemQuality)
                    end

                    if not hasQuestItem then
                        local linkOrID = item:GetItemLink() or itemRef
                        if isQuestItem(linkOrID) then
                            hasQuestItem = true
                        end
                    end

                    pending = pending - 1
                    if pending == 0 and not completed then
                        completed = true
                        applyFilter()
                    end
                end)
            end
        end
    end

    if pending == 0 then
        applyFilter()
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

function oGlowClassic:ApplyBorder(slot, quality)
    if not slot or not slot.CreateTexture then
        return
    end

    if not slot.oGlowBorder then
        local owner = slot
        if slot.GetClipsChildren and slot:GetClipsChildren() then
            local parent = slot:GetParent()
            if parent and parent.CreateTexture then
                if not slot.oGlowBorderFrame then
                    local frame = CreateFrame("Frame", nil, parent)
                    frame:SetFrameStrata(slot:GetFrameStrata())
                    frame:SetFrameLevel(slot:GetFrameLevel() + 10)
                    slot.oGlowBorderFrame = frame
                end
                owner = slot.oGlowBorderFrame
            end
        end

        local border = owner:CreateTexture(nil, "OVERLAY", nil, 7)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0.8)
        updateBorderSize(border, owner)
        border:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.oGlowBorder = border
    end

    updateBorderSize(slot.oGlowBorder, slot.oGlowBorder:GetParent() or slot)

    local rgb
    if type(quality) == 'number' then
        rgb = colorTable and colorTable[quality]
    else
        rgb = colorTable and rawget(colorTable, quality)
    end

    if rgb then
        slot.oGlowBorder:SetVertexColor(rgb[1], rgb[2], rgb[3])
    elseif type(quality) == 'number' then
        local r, g, b = C_Item.GetItemQualityColor(quality)
        slot.oGlowBorder:SetVertexColor(r, g, b)
    else
        return
    end
    slot.oGlowBorder:Show()

    local filters = oGlowClassicDB and oGlowClassicDB.FilterSettings
    local overrideBorder = not (filters and filters.baganatorOverride == false)
    if overrideBorder and slot.oGlowClassicIsBaganator and slot.IconBorder then
        if slot.oGlowClassicIconBorderAlpha == nil then
            slot.oGlowClassicIconBorderAlpha = slot.IconBorder:GetAlpha()
        end
        slot.IconBorder:SetAlpha(0)
    elseif slot.oGlowClassicIconBorderAlpha ~= nil and slot.IconBorder then
        slot.IconBorder:SetAlpha(slot.oGlowClassicIconBorderAlpha)
        slot.oGlowClassicIconBorderAlpha = nil
    end

    scheduleDelayedBorderSizeRefresh(slot)
    scheduleDelayedBaganatorIconBorderOverride(slot)
end

function oGlowClassic:ClearBorder(slot)
    if not slot then return end
    if slot.oGlowBorder then
        slot.oGlowBorder:Hide()
    end

    if slot.oGlowClassicIconBorderAlpha ~= nil and slot.IconBorder then
        slot.IconBorder:SetAlpha(slot.oGlowClassicIconBorderAlpha)
        slot.oGlowClassicIconBorderAlpha = nil
    end

    slot.oGlowClassicPendingIconBorderFix = nil
end
