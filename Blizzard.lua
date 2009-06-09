
local chatWindowWasLocked = {}
function CONFIGMODE_CALLBACKS.BlizzardChatWindows(action)
	if action == "ON" then
		wipe(chatWindowWasLocked)
		for index = 1, NUM_CHAT_WINDOWS do
			local shown, locked, docked = select(7, GetChatWindowInfo(index))
			if shown and not docked and locked then
				chatWindowWasLocked[index] = true
				SetChatWindowLocked(index, false)
			end
		end
	elseif action == "OFF" then
		for index in pairs(chatWindowWasLocked) do
			SetChatWindowLocked(index, true)
		end
	end
end

local focusFrameWasLocked
function CONFIGMODE_CALLBACKS.BlizzardFocusFrame(action)
	if action == "ON" then
		focusFrameWasLocked = FocusFrame_IsLocked()
		if focusFrameWasLocked then
			FocusFrame_SetLock(false)
		end
	elseif action == "OFF" and focusFrameWasLocked then
		FocusFrame_SetLock(true)
		focusFrameWasLocked = nil
	end
end

local watchFrameWasLocked
function CONFIGMODE_CALLBACKS.BlizzardWatchFrame(action)
	if action == "ON" then
		watchFrameWasLocked = WatchFrame.locked
		if watchFrameWasLocked then
			WatchFrame_Unlock(WatchFrame)
		end
	elseif action == "OFF" and watchFrameWasLocked then
		WatchFrame_Lock(WatchFrame)
		watchFrameWasLocked = nil
	end
end

local battlefieldMinimapWasLocked
local battlefieldMinimapWasHidden
function CONFIGMODE_CALLBACKS.BlizzardBattlefieldMinimap(action)
	if not BattlefieldMinimap then return end
	if action == "ON" then
		battlefieldMinimapWasHidden =	not BattlefieldMinimap:IsShown()
		battlefieldMinimapWasLocked = BattlefieldMinimapOptions.locked
		if battlefieldMinimapWasHidden then
			BattlefieldMinimap:Show()
		end
		if battlefieldMinimapWasLocked then
			BattlefieldMinimapOptions.locked = false
		end
	elseif action == "OFF" then
		if battlefieldMinimapWasHidden then
			BattlefieldMinimap:Hide()
			battlefieldMinimapWasHidden = nil
		end
		if battlefieldMinimapWasLocked then
			BattlefieldMinimapOptions.locked = true
			battlefieldMinimapWasLocked = nil
		end
	end
end
