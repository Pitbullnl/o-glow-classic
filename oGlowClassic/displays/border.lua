local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local argcheck = oGlowClassic.argcheck
local colorTable = ns.colorTable

local updateBorderSize = function(border, owner)
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

		updateBorderSize(bc, owner)
	end

	return bc
end

local borderDisplay = function(frame, color)
	if(color) then
		local bc = createBorder(frame)
		updateBorderSize(bc, bc:GetParent() or frame)
		local rgb = colorTable[color]

		if(rgb) then
			bc:SetVertexColor(rgb[1], rgb[2], rgb[3])
			bc:Show()
		end

		return true
	elseif(frame.oGlowClassicBorder) then
		frame.oGlowClassicBorder:Hide()
	end
end

oGlowClassic:RegisterDisplay('Border', borderDisplay)
