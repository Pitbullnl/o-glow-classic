local _, ns = ...
local oGlowClassic = ns.oGlowClassic
local colorTable = ns.colorTable
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
            if not item:IsItemEmpty() then
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

        local border = owner:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0.8)
        border:SetSize(70, 70)
        border:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.oGlowBorder = border
    end

    local rgb = colorTable and colorTable[quality]
    if rgb then
        slot.oGlowBorder:SetVertexColor(rgb[1], rgb[2], rgb[3])
    else
        local r, g, b = C_Item.GetItemQualityColor(quality)
        slot.oGlowBorder:SetVertexColor(r, g, b)
    end
    slot.oGlowBorder:Show()
end

function oGlowClassic:ClearBorder(slot)
    if not slot then return end
    if slot.oGlowBorder then
        slot.oGlowBorder:Hide()
    end
end
