
OneButtonConfig = CreateFrame("Frame", "OneButtonConfigFrame")
OneButtonConfig.modes = {}

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}

local OneButtonConfig = OneButtonConfig
local modes = OneButtonConfig.modes
local state

SLASH_ONEBUTTONCONFIG1 = "/onebuttonconfig"
SLASH_ONEBUTTONCONFIG2 = "/obc"
SlashCmdList["ONEBUTTONCONFIG"] = function() OneButtonConfig:Toggle() end

local function HandlePCallResult(success, ...)
	if success then
		return ...
	else
		local msg = ...
		geterrorhandler()(msg)
	end
end

local function CallHandler(name, ...)
	local handler = CONFIGMODE_CALLBACKS[name]
	if handler and type(handler) == "function" then
		return HandlePCallResult(pcall(handler, ...))
	end
end

local function RegisterModes(name, defaultMode, ...)
	if modes[name] ~= nil then return end
	if defaultMode ~= nil then
		modes[name] = { defaultMode, ... }
	else
		modes[name] = false
	end
end

local function ScanModes()
	for name in pairs(CONFIGMODE_CALLBACKS) do
		RegisterModes(name, CallHandler(name, "GETMODES"))
	end
end

OneButtonConfig:SetScript('OnEvent', function(self, event, ...)
	self:UnregisterEvent('VARIABLES_LOADED')
	self:RegisterEvent('ADDON_LOADED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')

	local toggled
	self:SetScript('OnEvent', function(self, event)
		if event == 'ADDON_LOADED' then
			ScanModes()
		elseif event == 'PLAYER_REGEN_DISABLED' then
			if state then
				toggled = true
				self:SetState(false)
			end
		elseif event == 'PLAYER_REGEN_ENABLED' then
			self:SetState(toggled)
			toggled = nil
		end
	end)

	OneButtonConfigDB = OneButtonConfigDB or {}
	OneButtonConfigDB.modes = OneButtonConfigDB.modes or {}

	ScanModes()
end)

-- Initialize on VARIABLES_LOADED')
OneButtonConfig:RegisterEvent('VARIABLES_LOADED')

-- Core function
function OneButtonConfig:SetState(v)
	if state == v or InCombatLockdown() then return end
	state = v
	if v then
		for name in pairs(CONFIGMODE_CALLBACKS) do
			local mode = modes[name] and (OneButtonConfigDB.modes[name] or modes[name][1])
			CallHandler(name, "ON", mode)
		end
	else
		for name in pairs(CONFIGMODE_CALLBACKS) do
			CallHandler(name, "OFF")
		end
	end
end

function OneButtonConfig:GetState()
	return state
end

function OneButtonConfig:Toggle()
	self:SetState(not state)
end
