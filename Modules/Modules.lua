--[[
Most handlers there are dirty and hackish and should better be implemented in 
the addon themselves.

They all register a CONFIGMODE_CALLBACKS with the same as the addon except 
when such callback already exists. So it will NOT override addon-defined 
callback.

If the addon is not yet loaded but could be loaded later, a listener 
is set up to wait until the addon is loaded.
]]

local loadableModules
local function RegisterModule(names, callback, key)
	if type(names) ~= "table" then
		names = { names }
	end
	key = key or names[1]
	local safe_callback = function()
		if CONFIGMODE_CALLBACKS[key] then return debug("CONFIGMODE_CALLBACKS["..key.."] already exists") end
		local res, msg = pcall(callback)
		if not res then
			geterrorhandler()(msg)
		end
	end
	for _,name in pairs(names) do
		if IsAddOnLoaded(name) then
			return safe_callback()
		end
	end
	for _,name in pairs(names) do
		local realName, _, _, enabled, loadable = GetAddOnInfo(name)
		if realName and enabled and loadable then
			debug("Postpone", name, "registering")
			if not loadableModules then loadableModules = {} end
			loadableModules[name:lower()] = safe_callback
		end
	end
end

-- ag_UnitFrames
RegisterModule('ag_UnitFrames', function()
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
RegisterModule('Dominos', function()
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
RegisterModule('SexyMap', function()
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
RegisterModule('Quartz', function()
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
RegisterModule('Cork', function()
	local Cork = _G.Cork
	local toggled = Cork.anchor:IsShown()
	function CONFIGMODE_CALLBACKS.Cork(action)
		if action == 'ON' then
			toggled = Cork.anchor:IsShown()
			Cork.anchor:Show()
		elseif action =='OFF' then
			if not toggled then
				Cork.anchor:Hide()
			end
		end
	end
end)

-- Grid
RegisterModule('Grid', function()
	local toggled
	function CONFIGMODE_CALLBACKS.Grid(action)
		if action == 'ON' then	
			toggled = GridLayout.options.args.lock.get()
			GridLayout.options.args.lock.set(false)
		elseif action == 'OFF' then
			GridLayout.options.args.lock.set(toggled)
		end
	end
end)

-- BigWigs
RegisterModule("BigWigs", function()
	local function getModule(name)
		return BigWigs:HasModule(name) and BigWigs:GetModule(name)
	end
	local toggledMessages
	function CONFIGMODE_CALLBACKS.BigWigs(action)
		if action ~= 'ON' and action ~= 'OFF' then return end
		local show = (action == "ON")
		local plugin = getModule('Messages')
		if plugin then 
			if show then
				toggledMessages = plugin.consoleOptions.set("anchor")
				plugin.consoleOptions.set("anchor", true)				
			else
				plugin.consoleOptions.set("anchor", toggledMessages)				
			end
		end
		plugin = getModule('Proximity')
		if plugin then
			if show then
				plugin:TestProximity()
			else
				plugin:CloseProximity()
			end
		end
		plugin = getModule("Bars 2")
		if plugin then
			-- There is only a toggle, not lock/unlock
			plugin:ShowAnchors()
		end
	end
end)

-- Baggins
RegisterModule("Baggins", function()
	local toggledPlacementFrame
	local toggledLock
	function CONFIGMODE_CALLBACKS.Baggins(action)
		if Baggins.db.profile.layout == "auto" then
			if action == "ON" then
				toggledPlacementFrame = BagginsBagPlacement and BagginsBagPlacement:IsShown()
				Baggins:ShowPlacementFrame() 
			elseif action == "OFF" and BagginsBagPlacement then
				if not toggledPlacementFrame then
					BagginsBagPlacement:Hide()
				end
			end
		else
			if action == "ON" then
				toggledLock = Baggins.db.profile.lock
				Baggins.db.profile.lock = false
			elseif action == "OFF" then
				Baggins.db.profile.lock = toggledLock
			end
		end		
	end
end)

-- Auracle
RegisterModule('Auracle', function()
	function CONFIGMODE_CALLBACKS.Auracle(action)
		if action == 'ON' then
			Auracle:UnlockWindows()
		elseif action == 'OFF' then
			Auracle:LockWindows()
		end
	end
end)

-- Gladius
RegisterModule('Gladius', function()
	local savedLocked
	function CONFIGMODE_CALLBACKS.Gladius(action, mode)
		if action == 'ON' then
			savedLocked = Gladius.db.profile.locked
			Gladius.db.profile.locked = false
			
			local bracket = tonumber(mode:sub(1,1))
			if bracket ~= Gladius.currentBracket then
				Gladius:ToggleFrame(bracket)
			else
				Gladius:UpdateFrame()
			end
		elseif action == 'OFF' then
			Gladius.db.profile.locked = savedLocked
			Gladius:HideFrame()
			
		elseif action == "GETMODES" then
			return "5vs5", "3vs3", "2vs2"
		end
	end
end)

-- Omen
RegisterModule('Omen', function()
	local lockedInfo = {"Locked"}
	local opts
	local savedTestMode
	local savedLocked
	function CONFIGMODE_CALLBACKS.Omen(action)
		if not opts then
			if not Omen.Options then
				Omen.GenerateOptionsInternal()
			end
			opts = Omen.Options.args.General.args
		end
		if action == 'ON' then
			savedTestMode = opts.TestMode.get()
			savedLocked = Omen.Options.get(lockedInfo)
			opts.TestMode.get(nil, true)
			opts.Locked.set(lockedInfo, false)
			Omen:Toggle(true)
		elseif action == 'OFF' then
			opts.TestMode.set(nil, savedTestMode)
			opts.Locked.set(lockedInfo, savedLocked)
			Omen:Toggle(false)
		end
		
	end
end)

--- If there a modules to load, do what need be
if loadableModules then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent('ADDON_LOADED')
	frame:SetScript('OnEvent', function(self, event, addon)
		addon = addon:lower()
		local callback = loadableModules[addon]
		if callback then
			for name,func in pairs(loadableModules) do
				if func == callback then
					loadableModules[name] = nil
				end
			end
			callback()
		end
	end)
end
