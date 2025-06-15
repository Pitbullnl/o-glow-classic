local _, ns = ...
local oGlowClassic = ns.oGlowClassic
local threshold = 1

local qualityFunc = function(slot, ...)

    local quality = -1
    local pending = 0
    local completed = false

    local function applyFilter()
        if quality > threshold then
            oGlowClassic:ApplyBorder(slot, quality)
        else
            oGlowClassic:ClearBorder(slot)
        end
    end

    for i = 1, select('#', ...) do
        local itemLink = select(i, ...)
        if itemLink then
            local item = Item:CreateFromItemLink(itemLink)
            pending = pending + 1

            item:ContinueOnItemLoad(function()
                local itemQuality = item:GetItemQuality()
                if itemQuality then
                    quality = math.max(quality, itemQuality)
                end

                pending = pending - 1
                if pending == 0 and not completed then
                    completed = true
                    applyFilter()
                end
            end)
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
end)

oGlowClassic:RegisterFilter(
    'Quality border',
    'Border',
    qualityFunc,
    [[Adds a border to the icons, indicating the quality the items have.]]
)

function oGlowClassic:ApplyBorder(slot, quality)
    if not slot then return end
    if not slot.oGlowBorder then
        local border = slot:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0.8)
        border:SetSize(slot:GetWidth() * 1.6, slot:GetHeight() * 1.6)
        border:SetPoint("CENTER", slot, "CENTER")
        slot.oGlowBorder = border
    end

    local r, g, b = C_Item.GetItemQualityColor(quality)
    slot.oGlowBorder:SetVertexColor(r, g, b)
    slot.oGlowBorder:Show()
end

function oGlowClassic:ClearBorder(slot)
    if not slot then return end
    if slot.oGlowBorder then
        slot.oGlowBorder:Hide()
    end
end
