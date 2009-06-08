local OneButtonConfig = OneButtonConfig

local toggleInfo = {
	text = 'Enable',
	checked = function() return OneButtonConfig:GetState() end,
	func = function() OneButtonConfig:Toggle() end,
	keepShownOnClick = true,
}
local subMenuInfo = {
	hasArrow = true
}
local modeInfo = {
	keepShownOnClick = true,
	func = function(button, name, mode)
		OneButtonConfigDB.modes[name] = mode
		UIDropDownMenu_SetSelectedValue(UIDropDownMenu_GetCurrentDropDown(), button.value)
	end,
}

local function initialize(frame, level)
	if level == 1 then		
		UIDropDownMenu_AddButton(toggleInfo, level)
		for name, values in pairs(OneButtonConfig.modes) do
			if type(values) == 'table' then
				subMenuInfo.text = name
				subMenuInfo.value = name
				UIDropDownMenu_AddButton(subMenuInfo, level)
			end
		end
	elseif level == 2 then
		local name = UIDROPDOWNMENU_MENU_VALUE
		for i,mode in ipairs(OneButtonConfig.modes[name]) do
			modeInfo.text = mode
			modeInfo.value = mode
			modeInfo.arg1 = name
			modeInfo.arg2 = (i ~= 1) and mode or nil
			modeInfo.checked = OneButtonConfigDB.modes[name] == modeInfo.arg2
			UIDropDownMenu_AddButton(modeInfo, level)
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
	UIDropDownMenu_Initialize(dropdown, initialize, "MENU", nil)	
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

