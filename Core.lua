
OneButtonConfig = CreateFrame("Frame", "OneButtonConfigFrame")

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}

local OneButtonConfig = OneButtonConfig
local state = false
local lodRegistry = {}
local modeCache = {}

OneButtonConfig.lodRegistry = lodRegistry

SLASH_ONEBUTTONCONFIG1 = "/onebuttonconfig"
SLASH_ONEBUTTONCONFIG2 = "/obc"
SlashCmdList["ONEBUTTONCONFIG"] = function() OneButtonConfig:Toggle() end

--------------------------------------------------------------------------------
-- Protected calls
--------------------------------------------------------------------------------

local SafeCall
do
	local function HandlePCallResult(success, ...)
		if success then return ... end
		geterrorhandler()((...))
	end

	function SafeCall(func, ...)
		if type(func) == "function" then
			return HandlePCallResult(pcall(func, ...))
		end
	end
end
OneButtonConfig.SafeCall = SafeCall

--------------------------------------------------------------------------------
-- Event handling
--------------------------------------------------------------------------------

OneButtonConfig:SetScript('OnEvent', function(self, event, ...)
	return self[event](self, event, ...) 
end)

do
	local wasEnabled
	function OneButtonConfig:PLAYER_REGEN_ENABLED()
		if wasEnabled then
			self:SetState(true)
			wasEnabled = nil
		end
	end

	function OneButtonConfig:PLAYER_REGEN_DISABLED()
		wasEnabled = self:GetState()
		self:SetState(false)
	end
end

function OneButtonConfig:PLAYER_LOGOUT()
	self:SetState(false)
end

function OneButtonConfig:ADDON_LOADED(_, name)
	if name:lower() == "onebuttonconfig" then
		self:Initialize()
	end
	lodRegistry[name] = nil
end

OneButtonConfig:RegisterEvent('ADDON_LOADED')

--------------------------------------------------------------------------------
-- Mode API
--------------------------------------------------------------------------------

-- This build the mode tables, reusing the same tables as most as possible
local GetModes
do
	local modes = setmetatable({}, {__mode='v'})
	function GetModes(name, ...)
		local num = select('#', ...)
		if num > 0 then
			local t = modes[name]
			if t then
				wipe(t)
			else
				modes[name] = {}
				t = modes[name]
			end
			for i = 1,  num do
				t[select(i, ...)] = true
			end
			return t
		end
	end
end

function OneButtonConfig:RefreshModes()
	wipe(modeCache)
	for name, handler in pairs(CONFIGMODE_CALLBACKS) do
		modeCache[name] = GetModes(name, SafeCall(handler, "GETMODES"))
	end
end

function OneButtonConfig:GetModes(name)
	return name and modeCache[name]
end

--------------------------------------------------------------------------------
-- Core function
--------------------------------------------------------------------------------

function OneButtonConfig:SetState(v)
	if state == v or InCombatLockdown() then return end
	state = v
	if v then
		for addon in pairs(lodRegistry) do
			LoadAddOn(addon)
		end
		for name, handler in pairs(CONFIGMODE_CALLBACKS) do
			SafeCall(handler, "ON", OneButtonConfigDB.modes[name])
		end
	else
		for name, handler in pairs(CONFIGMODE_CALLBACKS) do
			SafeCall(handler, "OFF")
		end
	end
end

function OneButtonConfig:GetState()
	return state
end

function OneButtonConfig:Toggle()
	self:SetState(not state)
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function OneButtonConfig:RegisterLoD(addon, title)
	lodRegistry[addon] = title
end

function OneButtonConfig:Initialize()
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_LOGOUT')
	
	-- database initialization
	OneButtonConfigDB = OneButtonConfigDB or {}
	OneButtonConfigDB.modes = OneButtonConfigDB.modes or {}
	
	-- Scan all LoD addons
	for index = 1, GetNumAddOns() do
		if not IsAddOnLoaded(index) then
			local name, title, _, enabled, loadable, _, _ = GetAddOnInfo(index)
			if enabled and loadable and not CONFIGMODE_CALLBACKS[name] then
				local header = GetAddOnMetadata(name, "X-ConfigMode")
				if header and tostring(header):trim():lower() ~= "false" then
					OneButtonConfig:RegisterLoD(name, title)
				end
			end
		end
	end
end
