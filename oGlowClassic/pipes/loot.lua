local hook
local modernHook
local _E

local function updateModernElement(element)
	if not (element and element.Item and element.GetSlotIndex and type(GetLootSlotLink) == 'function') then
		return
	end

	local slot = element:GetSlotIndex()
	oGlowClassic:CallFilters('loot', 'Border', element.Item, _E and slot and GetLootSlotLink(slot))
end

local function updateModernLoot()
	local scrollBox = LootFrame and LootFrame.ScrollBox
	if scrollBox and scrollBox.ForEachFrame then
		scrollBox:ForEachFrame(updateModernElement)
	end
end

local function hookModernLoot()
	if not modernHook and hooksecurefunc and LootFrameElementMixin and type(LootFrameElementMixin.Init) == 'function' then
		hooksecurefunc(LootFrameElementMixin, 'Init', updateModernElement)
		modernHook = true
	end
end

local update = function()
	if(LootFrame and LootFrame:IsShown()) then
		hookModernLoot()
		updateModernLoot()
		for i=1, LOOTFRAME_NUMBUTTONS or 4 do
			local slotFrame = _G['LootButton' .. i]
			if(slotFrame) then
				local slot = slotFrame.slot

				local itemLink
				if(slot and type(GetLootSlotLink) == 'function') then
					itemLink = GetLootSlotLink(slot)
				end

				oGlowClassic:CallFilters('loot', 'Border', slotFrame, _E and itemLink)
			end
		end
	end
end

local enable = function(self)
	_E = true
	hookModernLoot()

	if(not hook and LootFrameUpButton and LootFrameDownButton) then
		LootFrameUpButton:HookScript("OnClick", update)
		LootFrameDownButton:HookScript("OnClick", update)

		hook = true
	end

	self:RegisterEvent('LOOT_OPENED', update)
	self:RegisterEvent('LOOT_SLOT_CLEARED', update)
	self:RegisterEvent('LOOT_SLOT_CHANGED', update)
	update()
end

local disable = function(self)
	_E = nil

	self:UnregisterEvent('LOOT_OPENED', update)
	self:UnregisterEvent('LOOT_SLOT_CLEARED', update)
	self:UnregisterEvent('LOOT_SLOT_CHANGED', update)
	update()
end

oGlowClassic:RegisterPipe('loot', enable, disable, update, 'Loot frame', nil)
