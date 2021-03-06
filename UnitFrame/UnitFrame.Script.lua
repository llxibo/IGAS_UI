IGAS:NewAddon "IGAS_UI.UnitFrame"

--==========================
-- Script for UnitFrame
--==========================
_LockMode = true

Toggle = {
	Message = L"Lock Unit Frame",
	Get = function()
		return _LockMode
	end,
	Set = function (value)
		_LockMode = value

		if not _LockMode then
			for _, frm in ipairs(arUnit) do
				frm.NoUnitWatch = true
			end
			IFMovable._ModeOn(_IGASUI_UNITFRAME_GROUP)
			IFResizable._ModeOn(_IGASUI_UNITFRAME_GROUP)
			IFToggleable._ModeOn(_IGASUI_UNITFRAME_GROUP)
		else
			_Menu.Visible = false
			IFMovable._ModeOff(_IGASUI_UNITFRAME_GROUP)
			IFResizable._ModeOff(_IGASUI_UNITFRAME_GROUP)
			IFToggleable._ModeOff(_IGASUI_UNITFRAME_GROUP)
			for _, frm in ipairs(arUnit) do
				frm.NoUnitWatch = false
				if not frm.Unit then
					frm.Visible = false
				elseif UnitExists(frm.Unit) then
					frm.Visible = true
				end
				frm:RefreshForAutoHide()
			end
		end

		Toggle.Update()
	end,
	Update = function() end,
}

------------------------------------------------------
-- Module Script Handler
------------------------------------------------------
_Addon.OnSlashCmd = _Addon.OnSlashCmd + function(self, option, info)
	if option and (option:lower() == "uf" or option:lower() == "unitframe") then
		if InCombatLockdown() then return end

		info = info and info:lower()

		if info == "unlock" then
			Toggle.Set(true)
		elseif info == "lock" then
			Toggle.Set(false)
		else
			Log(2, "/iu uf unlock - unlock the unit frames.")
			Log(2, "/iu uf lock - lock the unit frames.")
		end

		return true
	elseif option and (option:lower() == "show" or option:lower() == "hide") then
		if info then
			if not info:match("%d$") then
				info = info .. "%d*"
			end
			local visible = (option:lower() == "show")

			Task.NoCombatCall(function()
				if visible then
					for i = 1, #arUnit do
						if not arUnit[i].ToggleState and arUnit[i].OldUnit:match(info) then
							arUnit[i].ToggleState = true
						end
					end
				else
					for i = 1, #arUnit do
						if arUnit[i].ToggleState and arUnit[i].Unit:match(info) then
							arUnit[i].ToggleState = false
						end
					end
				end
			end)
		else
			Log(2, "/iu show|hide unit - show or hide unit's frame")
		end

		return true
	end
end

_HiddenFrame = CreateFrame("Frame")
_HiddenFrame:Hide()

function HideBlzUnitFrame(name)
	self = _G[name]

	self:UnregisterAllEvents()
	self:Hide()

	self:SetParent(_HiddenFrame)

	if self.healthbar then
		self.healthbar:UnregisterAllEvents()
	end

	if self.manabar then
		self.manabar:UnregisterAllEvents()
	end

	if self.spellbar then
		self.spellbar:UnregisterAllEvents()
	end

	if self.powerBarAlt then
		self.powerBarAlt:UnregisterAllEvents()
	end
end

function OnEnable(self)
	for _, unitset in ipairs(Config.Units) do
		local index = 1
		local name = unitset["HideFrame" .. index]

		while name do
			for i = 1, unitset.Max or 1 do
				HideBlzUnitFrame(name:format(i))
			end

			index = index + 1
			name = unitset["HideFrame" .. index]
		end
	end

	_M:SecureHook("ShowPartyFrame")
end

function ShowPartyFrame()
	Task.NoCombatCall(HidePartyFrame)
end

function OnLoad(self)
	_DB = _Addon._DB.UnitFrame or {}
	_Addon._DB.UnitFrame = _DB

	-- Convert old save data
	for i = 1, #arUnit do
		if _DB[i] then
			_DB[arUnit[i].Unit] = _DB[i]
			_DB[i] = nil
		end
	end

	for i = 1, #arUnit do
		local db = _DB[arUnit[i].Unit]

		if db and db.Size then
			arUnit[i].Size = db.Size
		end
		if db and db.Location then
			arUnit[i].Location = db.Location
		end
	end

	-- Hide no need unitframe
	_DB.HideUnit = _DB.HideUnit or {}
	_DB.AutoHideData = _DB.AutoHideData or {}

	for i, unitf in ipairs(arUnit) do
		local unit = unitf.Unit

		if _DB.HideUnit[unit] then
			unitf.ToggleState = false
		else
			unitf.AutoHideCondition = _DB.AutoHideData[unit]
		end

		unitf.OnAutoHideChanged = function(self, new, old, prop)
			if prop == "ToggleState" then
				if not new then
					_DB.AutoHideData[unit] = nil
				end
			end
		end
	end

	-- Fix for PETBATTLES taint error
	if _G.FRAMELOCK_STATES and _G.FRAMELOCK_STATES.PETBATTLES then
		wipe(_G.FRAMELOCK_STATES.PETBATTLES)
	end
end

function _MenuAutoHide:OnClick()
	local unitf = _Menu.Parent
	local unit = unitf.Unit
	local data = _Addon:SelectMacroCondition(_DB.AutoHideData[unit])

	if data then
		_DB.AutoHideData[unit] = data
		unitf.AutoHideCondition = data
	end
end

function _MenuModifyAnchorPoints:OnClick()
	local unitf = _Menu.Parent
	local unit = unitf.Unit or unitf.OldUnit

	IGAS:ManageAnchorPoint(unitf, nil, true)

	_DB[unit] = _DB[unit] or {}
	_DB[unit].Location = unitf.Location
end

--------------------
-- Script Handler
--------------------
function arUnit:OnPositionChanged(i)
	local unit = arUnit[i].Unit or arUnit[i].OldUnit
	if unit then
		_DB[unit] = _DB[unit] or {}
		_DB[unit].Location = arUnit[i].Location
	end
end

function arUnit:OnSizeChanged(i)
	local unit = arUnit[i].Unit or arUnit[i].OldUnit
	if unit then
		_DB[unit] = _DB[unit] or {}
		_DB[unit].Size = arUnit[i].Size
	end
end

function arUnit:OnEnter(i)
	if not _LockMode then
		_Menu.Visible = false
		_Menu:ClearAllPoints()
		_Menu.Parent = arUnit[i]
		_Menu:SetPoint("TOPLEFT", arUnit[i], "TOPRIGHT")

		-- Refresh
		_MenuAutoHide.Enabled = arUnit[i].ToggleState

		_Menu:Show()
	end
end