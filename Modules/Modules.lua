-- Most handlers there are dirty and hackish and should better be implemented in the addon themselves

local loadableModules
local function RegisterModule(name, callback)
	local safe_callback = function(...)
		local res, msg = pcall(callback, ...)
		if not res then
			geterrorhandler()(msg)
		end
	end
	if IsAddOnLoaded(name) then
		safe_callback()
	else
		local realName, _, _, enabled, loadable = GetAddOnInfo(name)
		if realName and enabled and loadable then
			if not loadableModules then loadableModules = {} end			
			loadableModules[name] = safe_callback
		end
	end
end

-- ag_UnitFrames
RegisterModule('ag_unitframes', function()
	local aUF = LibStub("AceAddon-3.0"):GetAddon("ag_UnitFrames")
	local backup = aUF.db.profile.Locked
	function CONFIGMODE_CALLBACKS.ag_UnitFrames(action, mode)
		if action == 'GETMODES' then
			return 'party', 'raid'
		end
		if not IsAddOnLoaded('ag_Options') then
			LoadAddOn('ag_Options')
		end
		if not aUF.UpdateSetupMode then
			return
		end
		if action == 'ON' then
			backup = aUF.db.profile.Locked
			aUF:UpdateSetupMode(mode)
			aUF.db.profile.Locked = false
		elseif action == 'OFF' then
			aUF:UpdateSetupMode('off')
			aUF.db.profile.Locked = backup
		end
	end
end)

-- Dominos
RegisterModule('dominos', function()
	local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
	local backup = Dominos:Locked()
	function CONFIGMODE_CALLBACKS.Dominos(action)
		if action == 'ON' then
			backup = Dominos:Locked()
			Dominos:SetLock(false)
		elseif action == 'OFF' then
			Dominos:SetLock(backup)
		end
	end
end)

-- SexyMap
RegisterModule('sexymap', function()
	local SexyMap = LibStub("AceAddon-3.0"):GetAddon("SexyMap")
	local General = SexyMap:GetModule('General')
	function CONFIGMODE_CALLBACKS.SexyMap(action)
		if action == 'ON' then
			General:SetLock(false)
		elseif action == 'OFF' then
			General:SetLock(true)
		end
	end
end)

-- Quartz
RegisterModule('quartz', function()
	local Quartz = _G.Quartz
	local qmodules = {
		Player = 'lock',
		Focus = 'lock',
		Target = 'lock',
		Pet = 'lock',
		Mirror = 'mirrorlock',
	}
	local toggled = {}
	function CONFIGMODE_CALLBACKS.Quartz(action)
		local options = Quartz.options.args
		if action == 'ON' then
			for module,optName in pairs(qmodules) do
				local opt = options[module] and options[module].args and options[module].args[optName]
				if opt and opt.get() then
					toggled[module] = optName
					opt.set(false)
				end
			end
		elseif action == 'OFF' then
			for module,optName in pairs(toggled) do
				local opt = options[module] and options[module].args and options[module].args[optName]
				opt.set(true)
			end
			wipe(toggled)
		end
	end
end)

-- Cork
RegisterModule('cork', function()
	local Cork = _G.Cork
	local backup = Cork.anchor:IsShown()
	function CONFIGMODE_CALLBACKS.Cork(action)
		if action == 'ON' then
			backup = Cork.anchor:IsShown()
			Cork.anchor:Show()
		elseif action =='OFF' then
			if not backup then
				Cork.anchor:Hide()
			end
		end
	end
end)

--- If there a modules to load, do what need be
if loadableModules then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent('ADDON_LOADED')
	frame:SetScript('OnEvent', function(self, event, addon)
		addon = addon:lower()
		if loadableModules[addon] then
			loadableModules[addon]()
			loadableModules[addon] = nil
		end
	end)	
end

