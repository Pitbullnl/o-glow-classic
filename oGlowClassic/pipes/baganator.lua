-- Baganator integration
-- Applies oGlowClassic borders to Baganator item buttons.

local _E
local hooked
local hookedSetItemButtonQuality
local hookedBagOpenFuncs

local function shouldOverrideBaganatorBorder()
	local filters = oGlowClassicDB and oGlowClassicDB.FilterSettings
	return not (filters and filters.baganatorOverride == false)
end

local function debugEnabled()
	local filters = oGlowClassicDB and oGlowClassicDB.FilterSettings
	return (filters and filters.baganatorDebug == true) or _G.oGlowClassicBaganatorDebug == true
end

local function dprint(...)
	if debugEnabled() then
		local parts = { ... }
		for i = 1, #parts do
			parts[i] = tostring(parts[i])
		end
		local msg = "|cff33ff99oGlowClassic:|r(Baganator) " .. table.concat(parts, " ")
		if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
			DEFAULT_CHAT_FRAME:AddMessage(msg)
		else
			print(msg)
		end
	end
end

local function getItemLink(button, passedLink)
	if passedLink then
		return passedLink
	end

	local bgr = button and button.BGR
	if bgr and bgr.itemLink then
		return bgr.itemLink
	end
end

local function updateButton(button, passedLink, force)
	if not _E or not button then
		return
	end

	button.oGlowClassicIsBaganator = true

	local link = getItemLink(button, passedLink)

	local overrideBorder = shouldOverrideBaganatorBorder()

	-- If override is disabled, let Baganator handle borders (restore IconBorder and
	-- remove any existing oGlow border).
	if not overrideBorder then
		button.oGlowClassicLastItemLink = nil
		if oGlowClassic.ClearBorder then
			oGlowClassic:ClearBorder(button)
		end
		if button.oGlowClassicBorder then
			button.oGlowClassicBorder:Hide()
		end
		if button.IconBorder and button.oGlowClassicIconBorderAlpha ~= nil then
			button.IconBorder:SetAlpha(button.oGlowClassicIconBorderAlpha)
			button.oGlowClassicIconBorderAlpha = nil
		end
		dprint("updateButton: override off", button:GetName() or "<unnamed>")
		return
	end

	-- Always clear when empty but previously had a border.
	if not link then
		button.oGlowClassicLastItemLink = nil
		dprint("updateButton: no link", button:GetName() or "<unnamed>")
		if button.oGlowBorder and button.oGlowBorder:IsShown() then
			oGlowClassic:CallFilters('baganator', 'Border', button)
		end

		if overrideBorder and button.IconBorder then
			if button.oGlowClassicIconBorderAlpha then
				button.IconBorder:SetAlpha(button.oGlowClassicIconBorderAlpha)
				button.oGlowClassicIconBorderAlpha = nil
			end
		end
		return
	end

	if not force and button.oGlowClassicLastItemLink == link then
		return
	end
	button.oGlowClassicLastItemLink = link

	dprint("updateButton: apply", button:GetName() or "<unnamed>")
	oGlowClassic:CallFilters('baganator', 'Border', button, link)

	if overrideBorder and button.IconBorder then
		if button.oGlowBorder and button.oGlowBorder:IsShown() then
			if not button.oGlowClassicIconBorderAlpha then
				button.oGlowClassicIconBorderAlpha = button.IconBorder:GetAlpha()
			end
			button.IconBorder:SetAlpha(0)
		elseif button.oGlowClassicIconBorderAlpha then
			button.IconBorder:SetAlpha(button.oGlowClassicIconBorderAlpha)
			button.oGlowClassicIconBorderAlpha = nil
		end
	end
end

local function scanExistingButtons(force)
	if not (Baganator and Baganator.API and Baganator.API.Skins and Baganator.API.Skins.GetAllFrames) then
		dprint("scanExistingButtons: Baganator frames API not available yet")
		return
	end

	local frames = Baganator.API.Skins.GetAllFrames()
	if type(frames) ~= "table" then
		dprint("scanExistingButtons: frames not a table")
		return
	end

	local found = 0
	for i = 1, #frames do
		local details = frames[i]
		if details and details.regionType == "ItemButton" and details.region then
			updateButton(details.region, nil, force)
			found = found + 1
		end
	end
	dprint("scanExistingButtons: updated", found, "buttons")
end

local function hookBaganator()
	if hooked then
		return
	end

	if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Baganator")) then
		dprint("hookBaganator: Baganator not loaded yet")
		return
	end

	-- Baganator is often load-on-demand; it can build some frames during its load
	-- before ADDON_LOADED fires. Register hooks, then force a refresh + rescan.
	dprint("hookBaganator: installing hooks")

	if Baganator and Baganator.API and Baganator.API.Skins and Baganator.API.Skins.RegisterListener then
		Baganator.API.Skins.RegisterListener(function(details)
			if not oGlowClassic:IsPipeEnabled('baganator') then
				return
			end
			if details and details.regionType == "ItemButton" and details.region then
				dprint("listener: ItemButton added")
				updateButton(details.region)
			end
		end)
	else
		dprint("hookBaganator: RegisterListener not available")
	end

	if not hookedSetItemButtonQuality and hooksecurefunc then
		hooksecurefunc("SetItemButtonQuality", function(button, quality, itemLink)
			if not oGlowClassic:IsPipeEnabled('baganator') then
				return
			end
			if button and button.BGR ~= nil then
				dprint("hook: SetItemButtonQuality", button:GetName() or "<unnamed>", quality or "<nil>")
				updateButton(button, itemLink)
			end
		end)
		hookedSetItemButtonQuality = true
	else
		if not hooksecurefunc then
			dprint("hookBaganator: hooksecurefunc not available")
		end
	end

	hooked = true

	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			dprint("after(0): scan + refresh")
			scanExistingButtons()
			if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
				Baganator.API.RequestItemButtonsRefresh()
			end
		end)
		C_Timer.After(0.1, function()
			dprint("after(0.1): rescan")
			scanExistingButtons()
		end)
	else
		dprint("no C_Timer.After: immediate scan + refresh")
		scanExistingButtons()
		if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
			Baganator.API.RequestItemButtonsRefresh()
		end
	end
end

local function hookBagOpenFunctions()
	if hookedBagOpenFuncs or not hooksecurefunc then
		return
	end

	local function onOpen(funcName)
		if not oGlowClassic:IsPipeEnabled('baganator') then
			return
		end

		dprint("hook:", funcName)
		hookBaganator()

		if C_Timer and C_Timer.After then
			C_Timer.After(0, scanExistingButtons)
			C_Timer.After(0.1, scanExistingButtons)
		else
			scanExistingButtons()
		end
	end

	if type(ToggleBackpack) == "function" then
		hooksecurefunc("ToggleBackpack", function() onOpen("ToggleBackpack") end)
	end
	if type(OpenAllBags) == "function" then
		hooksecurefunc("OpenAllBags", function() onOpen("OpenAllBags") end)
	end
	if type(ToggleAllBags) == "function" then
		hooksecurefunc("ToggleAllBags", function() onOpen("ToggleAllBags") end)
	end
	if type(ToggleBag) == "function" then
		hooksecurefunc("ToggleBag", function() onOpen("ToggleBag") end)
	end

	hookedBagOpenFuncs = true
end

local ADDON_LOADED = function(self, event, addon)
	if addon == "Baganator" then
		dprint("event: ADDON_LOADED(Baganator)")
		hookBaganator()
	end
end

local update = function(self)
	if oGlowClassic:IsPipeEnabled('baganator') then
		dprint("pipe update")
		hookBaganator()
		-- Force a pass so toggling settings immediately restores/hides IconBorder as needed.
		scanExistingButtons(true)
	end
end

local enable = function(self)
	_E = true
	dprint("pipe enable")
	self:RegisterEvent('ADDON_LOADED', ADDON_LOADED)
	hookBagOpenFunctions()
	hookBaganator()
end

local disable = function(self)
	_E = nil
	dprint("pipe disable")
	self:UnregisterEvent('ADDON_LOADED', ADDON_LOADED)
end

oGlowClassic:RegisterPipe('baganator', enable, disable, update, 'Baganator', 'Adds oGlowClassic borders to Baganator item buttons')
