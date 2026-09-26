-- TODO:
--  - Write a description.

local _E
local hook
local outputHooked
local reagentHooked
local modernButtons = setmetatable({}, {__mode = 'k'})

local function updateModernOutput(form)
	if not (form and form.OutputIcon and form.transaction and C_TradeSkillUI and C_TradeSkillUI.GetRecipeOutputItemData) then
		return
	end
	local transaction = form.transaction
	if not (transaction.GetRecipeID and transaction.CreateCraftingReagentInfoTbl and transaction.GetAllocationItemGUID) then
		return
	end
	local itemInfo = C_TradeSkillUI.GetRecipeOutputItemData(
		transaction:GetRecipeID(), transaction:CreateCraftingReagentInfoTbl(), transaction:GetAllocationItemGUID())
	modernButtons[form.OutputIcon] = true
	oGlowClassic:CallFilters('tradeskill', 'Border', form.OutputIcon,
		_E and itemInfo and (itemInfo.hyperlink or itemInfo.itemID))
end

local function updateModernReagent(slot)
	if not (slot and slot.Button and slot.GetReagent) then return end
	local reagent = slot:GetReagent()
	modernButtons[slot.Button] = true
	oGlowClassic:CallFilters('tradeskill', 'Border', slot.Button, _E and reagent and reagent.itemID)
end

local function hookModernProfessions()
	if not hooksecurefunc then return end
	if not outputHooked and ProfessionsRecipeSchematicFormMixin and type(ProfessionsRecipeSchematicFormMixin.UpdateOutputItem) == 'function' then
		hooksecurefunc(ProfessionsRecipeSchematicFormMixin, 'UpdateOutputItem', updateModernOutput)
		outputHooked = true
	end
	if not reagentHooked and ProfessionsReagentSlotMixin and type(ProfessionsReagentSlotMixin.Update) == 'function' then
		hooksecurefunc(ProfessionsReagentSlotMixin, 'Update', updateModernReagent)
		reagentHooked = true
	end
end

local function updateModernProfessions()
	local form = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm
	if not (form and form.IsShown and form:IsShown()) then return end
	updateModernOutput(form)
	if form.GetSlots then
		for _, slot in ipairs(form:GetSlots()) do
			updateModernReagent(slot)
		end
	end
end

local pipe = function(id)
	if type(GetTradeSkillItemLink) ~= "function"
		or type(GetTradeSkillNumReagents) ~= "function"
		or type(GetTradeSkillReagentItemLink) ~= "function" then
		return
	end
	local itemLink = GetTradeSkillItemLink(id)

	if(itemLink) then
		oGlowClassic:CallFilters('tradeskill', 'Border', TradeSkillSkillIcon, _E and itemLink)
	end

	for i=1, GetTradeSkillNumReagents(id) do
		local reagentFrame = _G['TradeSkillReagent' .. i .. 'IconTexture']
		local reagentLink = GetTradeSkillReagentItemLink(id, i)

		oGlowClassic:CallFilters('tradeskill', 'Border', reagentFrame, _E and reagentLink)
	end
end

local doHook = function()
	if(not hook and type(TradeSkillFrame_SetSelection) == "function") then
		hook = function(...)
			if(_E) then return pipe(...) end
		end

		hooksecurefunc('TradeSkillFrame_SetSelection', hook)
	end
end

local function ADDON_LOADED(self, event, addon)
	if(addon == 'Blizzard_TradeSkillUI') then
		doHook()
	elseif addon == 'Blizzard_ProfessionsTemplates' or addon == 'Blizzard_Professions' then
		hookModernProfessions()
		updateModernProfessions()
	end
end

local update = function(self)
	updateModernProfessions()
	local id = type(GetTradeSkillSelectionIndex) == "function" and GetTradeSkillSelectionIndex()
	if(id and C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Blizzard_TradeSkillUI')) then
		return pipe(id)
	end
end

local enable = function(self)
	_E = true
	hookModernProfessions()

	if(C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_TradeSkillUI")) then
		doHook()
	end
	self:RegisterEvent("ADDON_LOADED", ADDON_LOADED)
	updateModernProfessions()
end

local disable = function(self)
	_E = nil
	for button in pairs(modernButtons) do
		self:CallFilters('tradeskill', 'Border', button, false)
	end

	self:UnregisterEvent('ADDON_LOADED', ADDON_LOADED)
end

oGlowClassic:RegisterPipe('tradeskill', enable, disable, update, 'Profession frame', nil)
