-- TODO:
--  - Write a description.

local _E
local letterHooked
local inboxHooked
local stack = {}

local send = function(self)
	if(not SendMailFrame or not SendMailFrame:IsShown()) then return end
	if type(GetSendMailItemLink) ~= 'function' then return end

	for i=1, ATTACHMENTS_MAX_SEND or 12 do
		local slotLink = GetSendMailItemLink(i)
		local slotFrame = _G["SendMailAttachment"..i]
		self:CallFilters('mail', 'Border', slotFrame, _E and slotLink)
	end
end

local inbox = function()
	if type(GetInboxNumItems) ~= "function" or type(GetInboxItemLink) ~= "function" or not InboxFrame then return end
	local numItems = GetInboxNumItems()
	local index = (((InboxFrame.pageNum or 1) - 1) * (INBOXITEMS_TO_DISPLAY or 7)) + 1

	for i=1, INBOXITEMS_TO_DISPLAY or 7 do
		local slotFrame = _G["MailItem"..i.."Button"]
		if (index <= numItems) then
			for j=1, ATTACHMENTS_MAX_RECEIVE or 16 do
				local attachLink = GetInboxItemLink(index, j)
				if(attachLink) then
					table.insert(stack, attachLink)
				end
			end
		end

		oGlowClassic:CallFilters('mail', 'Border', slotFrame, _E and unpack(stack))
		wipe(stack)

		index = index + 1
	end
end

local letter = function()
	if not InboxFrame then return end
	local mailID = InboxFrame.openMailID

	for i=1, ATTACHMENTS_MAX_RECEIVE or 16 do
		local itemLink
		if mailID and mailID > 0 and type(GetInboxItemLink) == 'function' then
			itemLink = GetInboxItemLink(mailID, i)
		end
		local slotFrame = _G["OpenMailAttachmentButton"..i]
		oGlowClassic:CallFilters('mail', 'Border', slotFrame, _E and itemLink)
	end
end

local update = function(self)
	send(self)
	inbox()
	letter()
end

local hookLetter = function(...)
	if(_E) then return letter(...) end
end

local hookInbox = function(...)
	if(_E) then return inbox(...) end
end

local function hookMailUpdates()
	if not hooksecurefunc then return end
	if(not letterHooked and type(OpenMail_Update) == "function") then
		hooksecurefunc("OpenMail_Update", hookLetter)
		letterHooked = true
	end
	if(not inboxHooked and type(InboxFrame_Update) == "function") then
		hooksecurefunc("InboxFrame_Update", hookInbox)
		inboxHooked = true
	end
end

local function addonLoaded(self, event, addon)
	if addon == 'Blizzard_MailFrame' then
		hookMailUpdates()
		update(self)
	end
end

local enable = function(self)
	_E = true

	self:RegisterEvent('MAIL_SHOW', update)
	self:RegisterEvent('MAIL_INBOX_UPDATE', update)
	self:RegisterEvent('MAIL_SEND_INFO_UPDATE', send)
	self:RegisterEvent('MAIL_SEND_SUCCESS', send)
	self:RegisterEvent('ADDON_LOADED', addonLoaded)

	hookMailUpdates()
	update(self)
end

local disable = function(self)
	_E =  nil
	update(self)

	self:UnregisterEvent('MAIL_SHOW', update)
	self:UnregisterEvent('MAIL_INBOX_UPDATE', update)
	self:UnregisterEvent('MAIL_SEND_INFO_UPDATE', send)
	self:UnregisterEvent('MAIL_SEND_SUCCESS', send)
	self:UnregisterEvent('ADDON_LOADED', addonLoaded)
end

oGlowClassic:RegisterPipe('mail', enable, disable, update, 'Mail frame', nil)
