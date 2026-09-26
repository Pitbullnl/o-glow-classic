-- TODO:
--  - Write a description.

local _E
local qualityHooked

local function updateModernBankButton(button, fallbackItemRef)
	if not (button and button.GetBankTabID and button.GetContainerSlotID) then
		return
	end

	local itemRef = false
	if _E and C_Container and C_Container.GetContainerItemLink then
		local tabID, slotID = button:GetBankTabID(), button:GetContainerSlotID()
		if tabID ~= nil and slotID ~= nil then
			itemRef = C_Container.GetContainerItemLink(tabID, slotID) or fallbackItemRef or false
		end
	end

	oGlowClassic:CallFilters('bank', 'Border', button, itemRef)
end

local function updateModernBankPanel(panel)
	if not (panel and panel.EnumerateValidItems and panel.IsShown and panel:IsShown()) then
		return false
	end

	-- BankPanel's pool enumerates buttons as keys, unlike bag containers.
	for button in panel:EnumerateValidItems() do
		updateModernBankButton(button)
	end
	return true
end

local function hookModernBankButtons()
	if qualityHooked or not (hooksecurefunc and type(SetItemButtonQuality) == 'function') then
		return
	end

	hooksecurefunc('SetItemButtonQuality', function(button, quality, itemRef)
		if button and button.GetBankTabID and button.GetContainerSlotID then
			updateModernBankButton(button, itemRef)
		end
	end)
	qualityHooked = true
end

local update = function(self)
	hookModernBankButtons()
	local panel = _G.BankPanel or (BankFrame and BankFrame.BankPanel)
	local accountPanel = _G.AccountBankPanel
	local hasModernPanel = panel and panel.EnumerateValidItems
	if hasModernPanel then
		updateModernBankPanel(panel)
	end
	if accountPanel and accountPanel ~= panel and accountPanel.EnumerateValidItems then
		hasModernPanel = true
		updateModernBankPanel(accountPanel)
	end
	if hasModernPanel then
		return
	end

	if(BankFrame and BankFrame:IsShown() and C_Container and C_Container.GetContainerItemLink) then
		for i=1, NUM_BANKGENERIC_SLOTS or 28 do
			local slotFrame = _G['BankFrameItem' .. i]
			local slotLink = C_Container.GetContainerItemLink(-1, i)

			self:CallFilters('bank', 'Border', slotFrame, _E and slotLink)
		end
	end
end

local enable = function(self)
	_E = true

	self:RegisterEvent('BANKFRAME_OPENED', update)
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', update)
	update(self)
end

local disable = function(self)
	_E = nil
	update(self)

	self:UnregisterEvent('BANKFRAME_OPENED', update)
	self:UnregisterEvent('PLAYERBANKSLOTS_CHANGED', update)
end

oGlowClassic:RegisterPipe('bank', enable, disable, update, 'Player bank frame', nil)
