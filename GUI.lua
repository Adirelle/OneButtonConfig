if not OneButtonConfig then return end

local OneButtonConfig = OneButtonConfig

-- Use table as unique values
local LOD_SUBMENU = {}
local DEFAULT_MODE = {}

local toggleInfo = {
	text = 'Enable config mode',
	tooltipTitle = 'Enable config mode',
	tooltipText = 'Check this entry to enable or disable all addon ConfigMode.',
	checked = function() return OneButtonConfig:GetState() end,
	func = function() OneButtonConfig:Toggle() end,
	keepShownOnClick = true,
}

local toggleIcon

local subMenuInfo = {
	hasArrow = true
}

local lodSubMenuInfo = {
	text = 'Load-on-Demand',
	value = LOD_SUBMENU,
	tooltipTitle = 'Load-On-Demand addons',
	tooltipText = 'These addons supports ConfigMode but are not loaded yet. ' ..
		'This sub-menu allows you to load them manually (this will NOT enable their ConfigMode). ' ..
		"\nPlease note they are automatically loaded when you enable the ConfigMode.",
	hasArrow = true
}

local lodInfo = {
	func = function(button) LoadAddOn(button.value)	end,
	keepShownOnClick = true,
}

local modeInfo = {
	keepShownOnClick = true,
	func = function(button, name)
		local mode = button.value
		OneButtonConfigDB.modes[name] = (mode ~= DEFAULT_MODE) and mode or nil
		UIDropDownMenu_SetSelectedValue(UIDropDownMenu_GetCurrentDropDown(), mode)
	end,
}

local function InitializeDropDownMenu(frame, level)
	if level == 1 then		
		UIDropDownMenu_AddButton(toggleInfo, level)
		if toggleIcon then
			UIDropDownMenu_AddButton(toggleIcon, level)
		end
		OneButtonConfig:RefreshModes()
		for name, handler in pairs(CONFIGMODE_CALLBACKS) do
			if OneButtonConfig:GetModes(name) then
				subMenuInfo.tooltipTitle =  name..' config modes'
				subMenuInfo.tooltipText = name..' proposes several alternatives ConfigModes. '..
					'Select the one you want to be enabled using this sub-menu.'
				subMenuInfo.text = name
				subMenuInfo.value = name
				UIDropDownMenu_AddButton(subMenuInfo, level)
			end
		end
		if next(OneButtonConfig.lodRegistry) then
			UIDropDownMenu_AddButton(lodSubMenuInfo, level)		
		end
	elseif level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == LOD_SUBMENU then
			for name, title in pairs(OneButtonConfig.lodRegistry) do
				lodInfo.text = title
				lodInfo.value = name
				lodInfo.tooltipTitle = 'Load '..name
				lodInfo.tooltipText = name.." supports ConfigMode but is not loaded yet.\nClick this entry to load it (this will not enable its ConfigMode)."
				UIDropDownMenu_AddButton(lodInfo, level)
			end		
		else
			local name = UIDROPDOWNMENU_MENU_VALUE
			modeInfo.text = "Default"
			modeInfo.value = DEFAULT_MODE
			modeInfo.arg1 = name
			modeInfo.tooltipTitle = 'Default ConfigMode'
			modeInfo.tooltipText = 'Select this entry to have '..name..' uses its default ConfigMode when enabled.'
			UIDropDownMenu_AddButton(modeInfo, level)		
			for mode in pairs(OneButtonConfig:GetModes(name)) do
				modeInfo.text = mode
				modeInfo.value = mode
				modeInfo.tooltipTitle = mode..' ConfigMode'
				modeInfo.tooltipText = 'Select this entry to have '..name..' uses this ConfigMode when enabled.'
				UIDropDownMenu_AddButton(modeInfo, level)
			end
			UIDropDownMenu_SetSelectedValue(UIDropDownMenu_GetCurrentDropDown(), OneButtonConfigDB.modes[name] or DEFAULT_MODE)
		end
	end
end

local function GetAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local dropdown
local function OpenMenu(anchor)
	if not dropdown then
		dropdown = CreateFrame("Frame", "OneButtonConfigDropDown", UIParent, "UIDropDownMenuTemplate")
		dropdown.xOffset, dropdown.yOffset = 0, 0
	end	
	UIDropDownMenu_Initialize(dropdown, InitializeDropDownMenu, "MENU", nil)	
	dropdown.point, dropdown.relativePoint = GetAnchor(anchor)
	ToggleDropDownMenu(1, nil, dropdown, anchor)
end

local LDB = LibStub('LibDataBroker-1.1')
local dataobj = LDB:GetDataObjectByName('OneButtonConfig') or LDB:NewDataObject('OneButtonConfig', { type = 'launcher',  icon = [[Interface\Icons\INV_Gizmo_01]] })
dataobj.OnTooltipShow = nil
dataobj.OnClick = function(frame, button)
	if button == "RightButton" then
		OpenMenu(frame)
	else
		OneButtonConfig:Toggle()
	end
end

local function InitializeMinimapIcon()
	local LibDBIcon = LibStub('LibDBIcon-1.0')
	local ICON_NAME = "OneButtonConfig"
	if not OneButtonConfigDB.icon then
		OneButtonConfigDB.icon = {}
	end
	local iconDB = OneButtonConfigDB.icon
	LibDBIcon:Register(ICON_NAME, dataobj, iconDB)
	toggleIcon = {
		text = 'Show minimap icon',
		tooltipTitle = 'Minimap icon',
		tooltipText = 'Check this entry to have the OneButtonClick icon displayed on the Minimap.',
		checked = function() return not iconDB.hide end,
		func = function() 
			iconDB.hide = not iconDB.hide
			if iconDB.hide then
				LibDBIcon:Hide(ICON_NAME)
			else
				LibDBIcon:Show(ICON_NAME)
			end
		end,
		keepShownOnClick = true,
	}
	InitializeIconDB = nil
end

hooksecurefunc(OneButtonConfig, "Initialize", InitializeMinimapIcon)
