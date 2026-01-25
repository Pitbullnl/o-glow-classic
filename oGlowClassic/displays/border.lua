local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local argcheck = oGlowClassic.argcheck
local colorTable = ns.colorTable
local questBorderIntensity = 1

local updateBorderSize = function(border, owner, frame, color)
	if not (border and owner and UIParent and UIParent.GetEffectiveScale and owner.GetEffectiveScale) then
		return
	end

	local uiScale = UIParent:GetEffectiveScale()
	local ownerScale = owner:GetEffectiveScale()

	if type(uiScale) ~= "number" or uiScale <= 0 or type(ownerScale) ~= "number" or ownerScale <= 0 then
		return
	end

	local scaleFix = uiScale / ownerScale

	local baseSize = 70
	if frame and frame.oGlowClassicIsBaganator and frame.GetWidth and frame.GetHeight then
		local w = frame:GetWidth()
		local h = frame:GetHeight()
		if type(w) == "number" and type(h) == "number" and w > 0 and h > 0 then
			baseSize = math.max(w, h) * 1.9
		end
	end

	border:SetSize(baseSize * scaleFix, baseSize * scaleFix)
end

local createBorder = function(self, point)
	local bc = self.oGlowClassicBorder
	if(not bc) then
		local owner = self
		if self.GetClipsChildren and self:GetClipsChildren() then
			local parent = self.GetParent and self:GetParent()
			if parent and parent.CreateTexture then
				if not self.oGlowClassicBorderFrame then
					local frame = CreateFrame("Frame", nil, parent)
					frame:SetFrameStrata(self:GetFrameStrata())
					frame:SetFrameLevel(self:GetFrameLevel() + 10)
					self.oGlowClassicBorderFrame = frame
				end
				owner = self.oGlowClassicBorderFrame
			end
		end

		bc = owner:CreateTexture(nil, 'OVERLAY', nil, 7)

		bc:SetTexture"Interface\\Buttons\\UI-ActionButton-Border"
		bc:SetBlendMode"ADD"
		bc:SetAlpha(.8)

		bc:SetPoint("CENTER", point or self)
		self.oGlowClassicBorder = bc

		updateBorderSize(bc, owner, self, nil)
	end

	return bc
end

local function applyBaganatorIconBorderOverride(frame, visible)
	if not (frame and frame.oGlowClassicIsBaganator) then
		return
	end

	local function hideAlphaRegion(region, key)
		if not (region and region.GetAlpha and region.SetAlpha) then
			return
		end

		local storeKey = "oGlowClassic_" .. key .. "_Alpha"

		if visible then
			if frame[storeKey] == nil then
				frame[storeKey] = region:GetAlpha()
			end
			region:SetAlpha(0)
		elseif frame[storeKey] ~= nil then
			region:SetAlpha(frame[storeKey])
			frame[storeKey] = nil
		end
	end

	-- Blizzard-style border.
	hideAlphaRegion(frame.IconBorder, "IconBorder")

	-- Baganator sometimes uses its own thin border textures.
	local bgr = frame.BGR
	if type(bgr) == "table" then
		hideAlphaRegion(bgr.border, "BGR_border")
		hideAlphaRegion(bgr.Border, "BGR_Border")
		hideAlphaRegion(bgr.thinBorder, "BGR_thinBorder")
		hideAlphaRegion(bgr.ThinBorder, "BGR_ThinBorder")
		hideAlphaRegion(bgr.iconBorder, "BGR_iconBorder")
		hideAlphaRegion(bgr.IconBorder, "BGR_IconBorder")
	end

	-- Some skins attach border textures directly to the button.
	hideAlphaRegion(frame.border, "border")
	hideAlphaRegion(frame.Border, "Border")
	hideAlphaRegion(frame.thinBorder, "thinBorder")
	hideAlphaRegion(frame.ThinBorder, "ThinBorder")
end

local borderDisplay = function(frame, color)
	if(color) then
		local bc = createBorder(frame)
		updateBorderSize(bc, bc:GetParent() or frame, frame, color)
		local rgb = colorTable[color]

		if(rgb) then
			bc:SetVertexColor(rgb[1], rgb[2], rgb[3])
			if color == "quest" and type(questBorderIntensity) == "number" then
				local intensity = math.max(0.05, math.min(1, questBorderIntensity))
				-- Quest borders tend to look "thicker/glowier" with ADD blend mode.
				-- Use BLEND for quests so intensity mainly controls visibility.
				bc:SetBlendMode("ADD")
				bc:SetAlpha(.8 * intensity)
			else
				bc:SetBlendMode("ADD")
				bc:SetAlpha(.8)
			end
			bc:Show()
			applyBaganatorIconBorderOverride(frame, true)
		end

		return true
	elseif(frame.oGlowClassicBorder) then
		frame.oGlowClassicBorder:Hide()
		applyBaganatorIconBorderOverride(frame, false)
	end
end

oGlowClassic:RegisterOptionCallback(function(db)
	local filters = db and db.FilterSettings
	if filters and type(filters.questBorderIntensity) == "number" then
		questBorderIntensity = filters.questBorderIntensity
	elseif filters and type(filters.questBorderScale) == "number" then
		-- Back-compat: previously this value was stored as "scale".
		questBorderIntensity = filters.questBorderScale
	else
		questBorderIntensity = 1
	end
end)

oGlowClassic:RegisterDisplay('Border', borderDisplay)
