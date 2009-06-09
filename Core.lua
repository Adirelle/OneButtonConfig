
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

OneButtonConfig:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)

function OneButtonConfig:PLAYER_REGEN_ENABLED()
	if toggled then
		self:SetState(true)
		toggled = nil
	end
end

function OneButtonConfig:PLAYER_REGEN_DISABLED()
	if state then
		toggled = true
		self:SetState(false)
	end
end

function OneButtonConfig:PLAYER_LOGOUT()
	self:SetState(false)
end

function OneButtonConfig:Initialize()
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_LOGOUT')
	OneButtonConfigDB = OneButtonConfigDB or {}
	OneButtonConfigDB.modes = OneButtonConfigDB.modes or {}
	ScanModes()
end

OneButtonConfig:RegisterEvent('ADDON_LOADED')
function OneButtonConfig:ADDON_LOADED(_, name)
	if name:lower() == "onebuttonconfig" then
		self:Initialize()
	end
end

function OneButtonConfig:CreateLoadingHandler(name, ...)
	local modes = { ... }
	CONFIGMODE_CALLBACKS[name] = function(action, mode)
		if action == "ON" then
			CONFIGMODE_CALLBACKS[name] = nil
			if LoadAddOn(name) then
				if type(CONFIGMODE_CALLBACKS[name]) == "function" then
					return CONFIGMODE_CALLBACKS[name](action, mode)
				end
			end
		elseif action == "GETMODES" then
			return unpack(modes)
		end
	end
end

-- Register LoD handlers
for index = 1, GetNumAddOns() do
	if not IsAddOnLoaded(index) then
		local name, _, _, enabled, loadable, _, _ = GetAddOnInfo(index)
		local header = GetAddOnMetadata(name, "X-ConfigMode")
		if enabled and loadable and header and not CONFIGMODE_CALLBACKS[name] then			
			if header:match(",") then
				OneButtonConfig:CreateLoadingHandler(name, header:gmatch("[^ ,]+"))
			else
				OneButtonConfig:CreateLoadingHandler(name)
			end
		end
	end
end

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
