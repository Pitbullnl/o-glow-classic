local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local colorTable = ns.colorTable

local frame = CreateFrame('Frame')
frame:Hide()
frame.name = 'Filter: Quality'
frame.parent = 'oGlowClassic'

frame:SetScript('OnShow', function(self)
	self:CreateOptions()
	self:SetScript('OnShow', nil)
end)

function frame:CreateOptions()
	local title = ns.createFontString(self, 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 16, -16)
	title:SetText'oGlowClassic: Filter: Quality'

	local thresLabel = ns.createFontString(self, 'GameFontNormalSmall')
	thresLabel:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -16)
	thresLabel:SetText('Quality Threshold')

	local thesDDown = CreateFrame('Button', 'oGlowClassicOptFQualityThreshold', self, 'UIDropDownMenuTemplate')
	thesDDown:SetPoint('TOPLEFT', thresLabel, 'BOTTOMLEFT', -16, 0)

	local questCheckbox = CreateFrame('CheckButton', nil, self, 'InterfaceOptionsCheckButtonTemplate')
	questCheckbox:SetPoint('TOPLEFT', thesDDown, 'BOTTOMLEFT', 16, -8)
	questCheckbox.Text:SetText('Quest item override')

	local baganatorCheckbox = CreateFrame('CheckButton', nil, self, 'InterfaceOptionsCheckButtonTemplate')
	baganatorCheckbox:SetPoint('TOPLEFT', questCheckbox, 'BOTTOMLEFT', 0, -4)
	baganatorCheckbox.Text:SetText('Use oGlowClassic borders in Baganator')

	local baganatorDebugCheckbox = CreateFrame('CheckButton', nil, self, 'InterfaceOptionsCheckButtonTemplate')
	baganatorDebugCheckbox:SetPoint('TOPLEFT', baganatorCheckbox, 'BOTTOMLEFT', 0, -4)
	baganatorDebugCheckbox.Text:SetText('Debug Baganator integration')

	do
		local updateAllActivePipes = function()
			for pipe, active, name, desc in oGlowClassic.IteratePipes() do
				if(active) then
					oGlowClassic:UpdatePipe(pipe)
				end
			end
		end

		local DropDown_OnClick = function(self)
			oGlowClassicDB.FilterSettings.quality = self.value - 1
			oGlowClassic:CallOptionCallbacks()

			updateAllActivePipes()
			UIDropDownMenu_SetSelectedID(self:GetParent().dropdown, self:GetID())
		end

		local DropDown_OnEnter = function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			GameTooltip:SetText('Controls the lowest item quality color that should be displayed.', nil, nil, nil, nil, 1)
		end

		local DropDown_OnLeave = GameTooltip_Hide

		local UpdateSelected = function(self)
			local filters = oGlowClassicDB.FilterSettings
			local threshold = 1
			if(filters and filters.quality) then
				threshold = filters.quality
			end

			UIDropDownMenu_SetSelectedID(thesDDown, threshold + 2)
		end

		local UpdateQuestCheckbox = function()
			local filters = oGlowClassicDB.FilterSettings
			local enabled = not (filters and filters.questItems == false)
			questCheckbox:SetChecked(enabled)
		end

		local UpdateBaganatorCheckbox = function()
			local filters = oGlowClassicDB.FilterSettings
			local enabled = not (filters and filters.baganatorOverride == false)
			baganatorCheckbox:SetChecked(enabled)
		end

		local UpdateBaganatorDebugCheckbox = function()
			local filters = oGlowClassicDB.FilterSettings
			local enabled = filters and filters.baganatorDebug == true
			baganatorDebugCheckbox:SetChecked(enabled)
		end

		local Quest_OnClick = function(self)
			if not oGlowClassicDB.FilterSettings then
				oGlowClassicDB.FilterSettings = {}
			end

			oGlowClassicDB.FilterSettings.questItems = self:GetChecked() and true or false
			oGlowClassic:CallOptionCallbacks()
			updateAllActivePipes()
		end

		local Baganator_OnClick = function(self)
			if not oGlowClassicDB.FilterSettings then
				oGlowClassicDB.FilterSettings = {}
			end

			oGlowClassicDB.FilterSettings.baganatorOverride = self:GetChecked() and true or false
			updateAllActivePipes()
		end

		local BaganatorDebug_OnClick = function(self)
			if not oGlowClassicDB.FilterSettings then
				oGlowClassicDB.FilterSettings = {}
			end

			oGlowClassicDB.FilterSettings.baganatorDebug = self:GetChecked() and true or false
			if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99oGlowClassic:|r(Baganator) debug " .. (oGlowClassicDB.FilterSettings.baganatorDebug and "enabled" or "disabled"))
			else
				print("|cff33ff99oGlowClassic:|r(Baganator) debug " .. (oGlowClassicDB.FilterSettings.baganatorDebug and "enabled" or "disabled"))
			end
			updateAllActivePipes()
		end

		local DropDown_init = function(self)
			local info

			for i=0,7 do
				info = UIDropDownMenu_CreateInfo()
				info.text = ns.Hex(colorTable[i]) .._G['ITEM_QUALITY' .. i .. '_DESC']
				info.value = i
				info.func = DropDown_OnClick

				UIDropDownMenu_AddButton(info)
			end
		end

		thesDDown:SetScript('OnEnter', DropDown_OnEnter)
		thesDDown:SetScript('OnLeave', DropDown_OnLeave)

		questCheckbox:SetScript('OnClick', Quest_OnClick)
		questCheckbox:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			GameTooltip:SetText('If enabled, quest items use the quest-item color instead of the quality color.', nil, nil, nil, nil, 1)
		end)
		questCheckbox:SetScript('OnLeave', DropDown_OnLeave)

		baganatorCheckbox:SetScript('OnClick', Baganator_OnClick)
		baganatorCheckbox:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			GameTooltip:SetText("If enabled, oGlowClassic will display its borders on Baganator item buttons (and hide Baganator's own thin border). If disabled, Baganator's borders are used.", nil, nil, nil, nil, 1)
		end)
		baganatorCheckbox:SetScript('OnLeave', DropDown_OnLeave)

		baganatorDebugCheckbox:SetScript('OnClick', BaganatorDebug_OnClick)
		baganatorDebugCheckbox:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			GameTooltip:SetText('If enabled, prints debug messages for the oGlowClassic Baganator integration (useful for troubleshooting first-open behavior).', nil, nil, nil, nil, 1)
		end)
		baganatorDebugCheckbox:SetScript('OnLeave', DropDown_OnLeave)

		function frame:refresh()
			UIDropDownMenu_Initialize(thesDDown, DropDown_init)
			UpdateSelected()
			UpdateQuestCheckbox()
			UpdateBaganatorCheckbox()
			UpdateBaganatorDebugCheckbox()
		end
		self:refresh()
	end
end


if Settings and SettingsPanel then
	ns.QueueSettingsSubcategory(function()
		local subcategory = Settings.RegisterCanvasLayoutSubcategory(ns.mainCategory, frame, frame.name)
		Settings.RegisterAddOnCategory(subcategory)
	end)
elseif InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(frame)
end
