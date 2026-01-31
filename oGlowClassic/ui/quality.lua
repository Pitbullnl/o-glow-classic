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

	local questBorderScaleSlider = CreateFrame('Slider', 'oGlowClassicOptFQualityQuestBorderScale', self, 'OptionsSliderTemplate')
	questBorderScaleSlider:SetPoint('TOPLEFT', questCheckbox, 'BOTTOMLEFT', 0, -20)
	questBorderScaleSlider:SetWidth(240)
	questBorderScaleSlider:SetMinMaxValues(0.2, 1.0)
	questBorderScaleSlider:SetValueStep(0.05)
	questBorderScaleSlider:SetValue(0.35)
	if questBorderScaleSlider.ObeyStepOnDrag then
		questBorderScaleSlider:ObeyStepOnDrag(true)
	end
	if questBorderScaleSlider.Text and questBorderScaleSlider.Text.SetText then
		questBorderScaleSlider.Text:SetText('Quest border intensity')
	end
	if questBorderScaleSlider.Low and questBorderScaleSlider.Low.SetText then
		questBorderScaleSlider.Low:SetText('0.2x')
	end
	if questBorderScaleSlider.High and questBorderScaleSlider.High.SetText then
		questBorderScaleSlider.High:SetText('1.0x')
	end
	if questBorderScaleSlider.Text and questBorderScaleSlider.Text.SetText then
		questBorderScaleSlider.Text:SetText(('Quest border intensity: %.2fx'):format(questBorderScaleSlider:GetValue()))
	end

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

		local UpdateQuestBorderScaleSlider = function()
			local filters = oGlowClassicDB.FilterSettings
			local v = 0.35
			if filters and type(filters.questBorderIntensity) == "number" then
				v = filters.questBorderIntensity
			elseif filters and type(filters.questBorderScale) == "number" then
				v = filters.questBorderScale
			end
			questBorderScaleSlider:SetValue(v)
			if questBorderScaleSlider.Text and questBorderScaleSlider.Text.SetText then
				questBorderScaleSlider.Text:SetText(('Quest border intensity: %.2fx'):format(v))
			end
		end

		local Quest_OnClick = function(self)
			if not oGlowClassicDB.FilterSettings then
				oGlowClassicDB.FilterSettings = {}
			end

			oGlowClassicDB.FilterSettings.questItems = self:GetChecked() and true or false
			oGlowClassic:CallOptionCallbacks()
			updateAllActivePipes()
		end

		local QuestBorderScale_OnValueChanged = function(self, value)
			if not oGlowClassicDB.FilterSettings then
				oGlowClassicDB.FilterSettings = {}
			end

			local stepped = math.floor((value / 0.05) + 0.5) * 0.05
			-- clamp for intensity (0.2 - 1.0)
			stepped = math.max(0.2, math.min(1.0, stepped))

			if self.Text and self.Text.SetText then
				self.Text:SetText(('Quest border intensity: %.2fx'):format(stepped))
			end

			oGlowClassicDB.FilterSettings.questBorderIntensity = stepped
			-- Back-compat for older versions that read questBorderScale.
			oGlowClassicDB.FilterSettings.questBorderScale = stepped
			oGlowClassic:CallOptionCallbacks()
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

		questBorderScaleSlider:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			GameTooltip:SetText('Adjusts the intensity of the quest-item border only (lower = less thick/glowy look).', nil, nil, nil, nil, 1)
		end)
		questBorderScaleSlider:SetScript('OnLeave', DropDown_OnLeave)
		questBorderScaleSlider:SetScript('OnValueChanged', QuestBorderScale_OnValueChanged)
	
		function frame:refresh()
			UIDropDownMenu_Initialize(thesDDown, DropDown_init)
			UpdateSelected()
			UpdateQuestCheckbox()
			UpdateQuestBorderScaleSlider()
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
