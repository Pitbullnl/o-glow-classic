-- Bagnon and Bagnonium use the same BagBrother item class. Cached items need
-- their stored hyperlink, since the live container API can refer to another item.
local hooked = {}
local seen = setmetatable({}, {__mode = 'k'})

local function getPipe(button)
	local frame = button and button.frame
	if frame and frame.id == 'inventory' then
		return 'bags'
	elseif frame and frame.id == 'bank' then
		return 'bank'
	end
end

local function updateButton(button)
	local pipe = getPipe(button)
	if not pipe then return end

	seen[button] = pipe
	local info = button.info
	if not info and button.GetInfo then
		info = button:GetInfo()
	end
	local itemRef = info and (info.hyperlink or info.itemID)
	if pipe == 'bags' and button.IsCached and not button:IsCached()
		and button.GetBag and button.GetID and C_Container and C_Container.GetContainerItemLink then
		local bag, slot = button:GetBag(), button:GetID()
		if bag ~= nil and slot ~= nil then
			itemRef = C_Container.GetContainerItemLink(bag, slot)
		end
	end
	oGlowClassic:CallFilters(pipe, 'Border', button, oGlowClassic:IsPipeEnabled(pipe) and itemRef or false)
end

function oGlowClassic:RefreshBagnonButtons(pipe, clear)
	for button, buttonPipe in pairs(seen) do
		if buttonPipe == pipe then
			if clear then
				self:CallFilters(pipe, 'Border', button, false)
			else
				updateButton(button)
			end
		end
	end
end

if hooksecurefunc then
	hooksecurefunc(oGlowClassic, 'EnablePipe', function(self, pipe)
		if pipe == 'bags' or pipe == 'bank' then
			self:RefreshBagnonButtons(pipe)
		end
	end)
	hooksecurefunc(oGlowClassic, 'DisablePipe', function(self, pipe)
		if pipe == 'bags' or pipe == 'bank' then
			self:RefreshBagnonButtons(pipe, true)
		end
	end)
	hooksecurefunc(oGlowClassic, 'UpdatePipe', function(self, pipe)
		if pipe == 'bags' or pipe == 'bank' then
			self:RefreshBagnonButtons(pipe)
		end
	end)
end

local function hookAddon(name)
	if hooked[name] or not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(name)) then
		return
	end
	local addon = _G[name]
	if addon and addon.Item and type(addon.Item.Update) == 'function' and hooksecurefunc then
		hooksecurefunc(addon.Item, 'Update', updateButton)
		hooked[name] = true
	end
end

oGlowClassic:RegisterEvent('ADDON_LOADED', function(self, event, name)
	if name == 'Bagnon' or name == 'Bagnonium' then
		hookAddon(name)
	end
end)

oGlowClassic:RegisterEvent('BAG_UPDATE_DELAYED', function()
	for button, pipe in pairs(seen) do
		if pipe == 'bags' and button.IsShown and button:IsShown() then
			updateButton(button)
		end
	end
end)

hookAddon('Bagnon')
hookAddon('Bagnonium')
