-----------------------------------------
-- Definition for Action Bar
-----------------------------------------

IGAS:NewAddon "IGAS_UI.ActionBar"

import "System.Widget"
import "System.Widget.Action"

_IGASUI_ACTIONBAR_GROUP = "IActionButton"

-----------------------------------------------
--- IActionButton
-- @type class
-- @name IActionButton
-----------------------------------------------
class "IActionButton"
	inherit "ActionButton"
	extend "IFMovable" "IFResizable"

	_Prefix = "IActionButton"
	_Index = 1
	_MaxBrother = 12
	_TempActionBrother = {}
	_TempActionBranch = {}
	_IGASUI_ACTIONBAR_GROUP = _IGASUI_ACTIONBAR_GROUP

	-- Manager Frame
	_IActionButton_ManagerFrame = _IActionButton_ManagerFrame or SecureFrame("IGASUI_IActionButton_Manager", IGAS.UIParent, "SecureHandlerStateTemplate")
	_IActionButton_ManagerFrame.Visible = false

	-- Init manger frame's enviroment
	IFNoCombatTaskHandler._RegisterNoCombatTask(function ()
		_IActionButton_ManagerFrame:Execute[[
			Manager = self

			BranchMap = newtable()
			HeaderMap = newtable()
			BranchHeader = newtable()
			RootExpansion = newtable()
			HideBranchList = newtable()
			State = newtable()
			InCombatHeader = newtable()
			NoPetCombatHeader = newtable()
			NoVehicleHeader = newtable()
			PetHeader = newtable()
			AutoSwapHeader = newtable()

			ShowBrother = [==[
				local header = HeaderMap[self] or self

				for btn, hd in pairs(HeaderMap) do
					if hd == header then
						if not BranchMap[btn] or RootExpansion[ BranchMap[btn] ] then
							btn:Show()
						end
					end
				end
			]==]

			HideBrother = [==[
				local header = HeaderMap[self] or self

				for btn, hd in pairs(HeaderMap) do
					if hd == header then
						btn:Hide()
					end
				end
			]==]

			ShowBranch = [==[
				local branch = BranchMap[self] or self
				local needHide = not RootExpansion[branch]
				local regBtn

				for btn, root in pairs(BranchMap) do
					if root == branch then
						btn:Show()
						if needHide then
							if not regBtn then
								regBtn = branch
								regBtn:RegisterAutoHide(2)
							end
							regBtn:AddToAutoHide(btn)
						end
					end
				end

				if regBtn then
					HideBranchList[regBtn] = true
				end
			]==]

			HideBranch = [==[
				local branch = BranchMap[self] or self

				for btn, root in pairs(BranchMap) do
					if root == branch then
						btn:Hide()
					end
				end
			]==]

			StateCheck = [==[
				local hide = false
				if InCombatHeader[self] and not State["incombat"] then
					hide = true
				end

				if not hide and NoPetCombatHeader[self] and State["petbattle"] then
					hide = true
				end

				if not hide and NoVehicleHeader[self] and State["vehicle"] then
					hide = true
				end

				if hide then
					-- Unregister HideBranch
					for root in pairs(HideBranchList) do
						if root == self or HeaderMap[root] == self then
							root:UnregisterAutoHide()
							HideBranchList[root] = nil
						end
					end
					if self:IsShown() then
						self:Hide()
					end
				else
					if not self:IsShown() then
						self:Show()
					end
				end
			]==]

			UpdatePetHeader = [=[
				if State["pet"] then
					for btn in pairs(PetHeader) do
						if not btn:IsShown() then
							btn:Show()
						end
					end
				else
					for btn in pairs(PetHeader) do
						if btn:IsShown() then
							btn:Hide()
						end
					end
				end
			]=]
		]]

		_IActionButton_ManagerFrame:SetAttribute("_onstate-pet", [=[
			State["pet"] = newstate == "pet"
			Manager:Run(UpdatePetHeader)
		]=])
		_IActionButton_ManagerFrame:SetAttribute("_onstate-incombat", [=[
			State["incombat"] = newstate == "incombat"
			for btn in pairs(InCombatHeader) do
				Manager:RunFor(btn, StateCheck)
			end
		]=])
		_IActionButton_ManagerFrame:SetAttribute("_onstate-petbattle", [=[
			State["petbattle"] = newstate == "inpetcombat"
			for btn in pairs(NoPetCombatHeader) do
				Manager:RunFor(btn, StateCheck)
			end
		]=])
		_IActionButton_ManagerFrame:SetAttribute("_onstate-vehicle", [=[
			State["vehicle"] = newstate == "invehicle"
			for btn in pairs(NoVehicleHeader) do
				Manager:RunFor(btn, StateCheck)
			end
		]=])
		_IActionButton_ManagerFrame:RegisterStateDriver("pet", "[pet]pet;nopet;")
		_IActionButton_ManagerFrame:RegisterStateDriver("incombat", "[combat]incombat;nocombat;")
		_IActionButton_ManagerFrame:RegisterStateDriver("petbattle", "[petbattle]inpetcombat;nopetcombat;")
		_IActionButton_ManagerFrame:RegisterStateDriver("vehicle", "[vehicleui]invehicle;novehicle;")

		_IActionButton_ManagerFrame:Execute(("State['pet'] = '%s' == 'pet'"):format(SecureCmdOptionParse("[pet]pet;nopet;")))
		_IActionButton_ManagerFrame:Execute(("State['incombat'] = '%s' == 'incombat'"):format(SecureCmdOptionParse("[combat]incombat;nocombat;")))
		_IActionButton_ManagerFrame:Execute(("State['petbattle'] = '%s' == 'inpetcombat'"):format(SecureCmdOptionParse("[petbattle]inpetcombat;nopetcombat;")))
		_IActionButton_ManagerFrame:Execute(("State['vehicle'] = '%s' == 'invehicle'"):format(SecureCmdOptionParse("[vehicleui]invehicle;novehicle;")))
	end)

	_IActionButton_RegisterPetAction = [[
		local btn = Manager:GetFrameRef("StateButton")
		PetHeader[btn] = true
		Manager:Run(UpdatePetHeader)
	]]

	_IActionButton_UnregisterPetAction = [[
		local btn = Manager:GetFrameRef("StateButton")
		PetHeader[btn] = nil
		if not btn:IsShown() then
			btn:Show()
		end
	]]

	_IActionButton_RegisterOutCombat = [[
		local btn = Manager:GetFrameRef("StateButton")
		InCombatHeader[btn] = true
		Manager:RunFor(btn, StateCheck)
	]]

	_IActionButton_UnregisterOutCombat = [[
		local btn = Manager:GetFrameRef("StateButton")
		InCombatHeader[btn] = nil
		Manager:RunFor(btn, StateCheck)
	]]

	_IActionButton_RegisterNoPetBattle = [[
		local btn = Manager:GetFrameRef("StateButton")
		NoPetCombatHeader[btn] = true
		Manager:RunFor(btn, StateCheck)
	]]

	_IActionButton_UnregisterNoPetBattle = [[
		local btn = Manager:GetFrameRef("StateButton")
		NoPetCombatHeader[btn] = nil
		Manager:RunFor(btn, StateCheck)
	]]

	_IActionButton_RegisterNoVehicle = [[
		local btn = Manager:GetFrameRef("StateButton")
		NoVehicleHeader[btn] = true
		Manager:RunFor(btn, StateCheck)
	]]

	_IActionButton_UnregisterNoVehicle = [[
		local btn = Manager:GetFrameRef("StateButton")
		NoVehicleHeader[btn] = nil
		Manager:RunFor(btn, StateCheck)
	]]

	_IActionButton_RegisterAutoSwap = [[
		local btn = Manager:GetFrameRef("AutoSwapButton")
		AutoSwapHeader[btn] = true
	]]

	_IActionButton_UnregisterAutoSwap = [[
		local btn = Manager:GetFrameRef("AutoSwapButton")
		AutoSwapHeader[btn] = nil
	]]

	_IActionButton_RegisterBrother = [[
		local brother, header = Manager:GetFrameRef("BrotherButton"), Manager:GetFrameRef("HeaderButton")
		HeaderMap[brother] = header
	]]

	_IActionButton_RemoveBrother = [[
		local brother = Manager:GetFrameRef("BrotherButton")
		HeaderMap[brother] = nil
	]]

	_IActionButton_RegisterBranch = [[
		local branch, root = Manager:GetFrameRef("BranchButton"), Manager:GetFrameRef("RootButton")
		BranchMap[branch] = root
		BranchHeader[root] = true
	]]

	_IActionButton_RemoveBranch = [[
		local branch = Manager:GetFrameRef("BranchButton")
		local root = BranchMap[branch]
		BranchMap[branch] = nil
		local chk = false

		if root then
			for btn, rt in pairs(BranchMap) do
				if rt == root then
					chk = true
					break
				end
			end
			if not chk then
				BranchHeader[root] = nil
			end
		end
	]]

	_IActionButton_UpdateExpansion = [[
		local root = Manager:GetFrameRef("ExpansionButton")
		RootExpansion[root] = %s and BranchHeader[root] or nil
		if BranchHeader[root] then
			if RootExpansion[root] then
				Manager:RunFor(root, ShowBranch)
			else
				Manager:RunFor(root, HideBranch)
			end
		end
	]]

	_IActionButton_WrapClickPre = [[
		if button == "RightButton" then
			if RootExpansion[self] then
				RootExpansion[self] = nil
				self:CallMethod("IActionHandler_UpdateExpansion", nil)
			elseif not RootExpansion[self] then
				if BranchHeader[self] then
					RootExpansion[self] = true
					Manager:RunFor(self, ShowBranch)
					self:CallMethod("IActionHandler_UpdateExpansion", true)
				end
			end
		end
		return button, BranchMap[self] and "togglebranch" or BranchHeader[self] and "togglebranch" or nil
	]]

	_IActionButton_WrapClickPost = [=[
		local root = BranchMap[self] or self
		if BranchHeader[root] and not RootExpansion[root] then
			Manager:RunFor(self, HideBranch)
		end
		if AutoSwapHeader[root] and root ~= self then
			local rootKind = root:GetAttribute("type")
			if rootKind == "action" or rootKind == "pet" then return end
			local rootTarget = rootKind and root:GetAttribute(rootKind)

			local selfKind = self:GetAttribute("type")
			if not selfKind then return end
			local selfTarget = self:GetAttribute(selfKind)

			-- Update Root
			root:RunAttribute("UpdateAction", selfKind, selfTarget)

			-- Update self
			self:RunAttribute("UpdateAction", rootKind, rootTarget)
		end
	]=]

	_IActionButton_WrapEnter = [[
		if BranchHeader[self] and not RootExpansion[self] then
			Manager:RunFor(self, ShowBranch)
		end
	]]

	_IActionButton_WrapAttribute = [[
		if name == "statehidden" then
			if value then
				if HideBranchList[self] then
					self:Show()
					if RootExpansion[self] then return end
					Manager:RunFor(self, HideBranch)
				elseif not HeaderMap[self] then
					Manager:RunFor(self, HideBrother)
				elseif BranchHeader[self] then
					Manager:RunFor(self, HideBranch)
				end
			else
				if HideBranchList[self] then
					HideBranchList[self] = nil
				elseif not HeaderMap[self] then
					Manager:RunFor(self, ShowBrother)
				end
			end
		end
	]]

	local function RegisterPetAction(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterPetAction)
	end

	local function UnregisterPetAction(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_UnregisterPetAction)
	end

	local function RegisterOutCombat(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterOutCombat)
	end

	local function UnregisterOutCombat(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_UnregisterOutCombat)
	end

	local function RegisterNoPetBattle(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterNoPetBattle)
	end

	local function UnregisterNoPetBattle(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_UnregisterNoPetBattle)
	end

	local function RegisterNoVehicle(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterNoVehicle)
	end

	local function UnregisterNoVehicle(self)
		_IActionButton_ManagerFrame:SetFrameRef("StateButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_UnregisterNoVehicle)
	end

	local function RegisterAutoSwap(self)
		_IActionButton_ManagerFrame:SetFrameRef("AutoSwapButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterAutoSwap)
	end

	local function UnregisterAutoSwap(self)
		_IActionButton_ManagerFrame:SetFrameRef("AutoSwapButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_UnregisterAutoSwap)
	end

	local function RegisterBrother(brother, header)
		_IActionButton_ManagerFrame:SetFrameRef("BrotherButton", brother)
		_IActionButton_ManagerFrame:SetFrameRef("HeaderButton", header)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterBrother)
	end

	local function RemoveBrother(brother)
		_IActionButton_ManagerFrame:SetFrameRef("BrotherButton", brother)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RemoveBrother)
	end

	local function RegisterBranch(button, root)
		_IActionButton_ManagerFrame:SetFrameRef("BranchButton", button)
		_IActionButton_ManagerFrame:SetFrameRef("RootButton", root)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RegisterBranch)
	end

	local function RemoveBranch(button)
		_IActionButton_ManagerFrame:SetFrameRef("BranchButton", button)
		_IActionButton_ManagerFrame:Execute(_IActionButton_RemoveBranch)
	end

	local function SetupActionButton(self)
		_IActionButton_ManagerFrame:WrapScript(self, "OnEnter", _IActionButton_WrapEnter)
		_IActionButton_ManagerFrame:WrapScript(self, "OnClick", _IActionButton_WrapClickPre, _IActionButton_WrapClickPost)
		_IActionButton_ManagerFrame:WrapScript(self, "OnAttributeChanged", _IActionButton_WrapAttribute)
	end

	local function UpdateExpansion(self, flag)
		_IActionButton_ManagerFrame:SetFrameRef("ExpansionButton", self)
		_IActionButton_ManagerFrame:Execute(_IActionButton_UpdateExpansion:format(tostring(flag)))
	end

	local function IActionHandler_UpdateExpansion(self, flag)
		IGAS:GetWrapper(self).__Expansion = flag and true or false
	end

	------------------------------------------------------
	-- Script
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	------------------------------------
	--- Generate brother action buttons
	-- @name GenerateBrother
	-- @type function
	-- @param row, col
	-- @return brother last brother
	------------------------------------
	function GenerateBrother(self, row, col, force)
		row = row or self.__Row or 1
		col = col or self.__Col or 1

		if row <= 1 then row = 1 end
		if col <= 1 then col = 1 end
		if row > ceil(_MaxBrother / col) then row = ceil(_MaxBrother / col) end

		if self.Header == self and not self.FreeMode then
			if force or self.__Row ~= row or self.__Col ~= col then
				local w, h, marginX, marginY, index, brother, last = self.Width, self.Height, self.MarginX, self.MarginY, 1, self
				local tail

				for i = 1, row do
					if index > _MaxBrother then break end
					for j = 1, col do
						if index > _MaxBrother then break end

						if index > 1 then
							if not brother.Brother then
								brother.Brother = _Recycle_IButtons()
							end
							brother = brother.Brother
							brother:ClearAllPoints()
							brother:SetPoint("TOPLEFT", self, "TOPLEFT", (w + marginX) * (j-1), - (h + marginY) * (i-1))
						end

						if brother.ITail then
							tail = brother.ITail
						end

						index = index + 1
					end
				end

				-- Recycle useless button
				last = brother.Brother
				brother.Brother = nil

				while last do
					if last.ITail then
						tail = last.ITail
					end
					tinsert(_TempActionBrother, last)
					last = last.Brother
				end

				if tail then
					tail.ActionButton = brother
				end

				for i = #_TempActionBrother, 1, -1 do
					_TempActionBrother[i]:GenerateBranch(0)
				end

				for i = #_TempActionBrother, 1, -1 do
					_Recycle_IButtons(_TempActionBrother[i])
				end

				wipe(_TempActionBrother)

				self.__Row, self.__Col = row, col

				return brother
			end
		end
	end

	------------------------------------
	--- Generate Branch
	-- @name GenerateBranch
	-- @type function
	-- @param num
	-- @return nil
	------------------------------------
	function GenerateBranch(self, num, force)
		num = num or self.__BranchNum or 0

		if self.Root == self and not InCombatLockdown() then
			if force or self.__BranchNum ~= num then
				local w, h, marginX, marginY, branch, last = self.Width, self.Height, self.MarginX, self.MarginY, self
				local dir = self.FlyoutDirection

				for i = 1, num do
					if not branch.Branch then
						branch.Branch = _Recycle_IButtons()
					end
					branch = branch.Branch
					branch:ClearAllPoints()

					if dir == FlyoutDirection.LEFT then
						branch:SetPoint("LEFT", self, "LEFT", -(w + marginX) * i, 0)
					elseif dir == FlyoutDirection.RIGHT then
						branch:SetPoint("LEFT", self, "LEFT", (w + marginX) * i, 0)
					elseif dir == FlyoutDirection.UP then
						branch:SetPoint("TOP", self, "TOP", 0, (h + marginY) * i)
					elseif dir == FlyoutDirection.DOWN then
						branch:SetPoint("TOP", self, "TOP", 0, -(h + marginY) * i)
					end
				end

				-- Recycle useless button
				last = branch.Branch
				branch.Branch = nil

				while last do
					tinsert(_TempActionBranch, last)
					last = last.Branch
				end

				for i = #_TempActionBranch, 1, -1 do
					_Recycle_IButtons(_TempActionBranch[i])
				end

				wipe(_TempActionBranch)

				self.__BranchNum = num
				self.ShowFlyOut = num > 0 and (not self.LockMode or not self.FreeMode)
			end
		end
	end

	------------------------------------
	--- Update the action
	-- @name UpdateAction
	-- @type function
	-- @param kind, target, texture, tooltip
	------------------------------------
	function UpdateAction(self, kind, target, texture, tooltip)
		if kind == "flyout" then
			if self.Root ~= self then
				return IFNoCombatTaskHandler._RegisterNoCombatTask(function ()
					self:SetAction(nil)
				end)
			else
				IFNoCombatTaskHandler._RegisterNoCombatTask(GenerateBranch, self, 0)
			end
		end
		if self.UseBlizzardArt then
			return Super.UpdateAction(self, kind, target, texture, tooltip)
		end
	end

	------------------------------------------------------
	-- Interface Property
	------------------------------------------------------
	-- IFMovingGroup
	property "IFMovingGroup" {
		Get = function(self)
			return _IGASUI_ACTIONBAR_GROUP
		end,
	}
	-- IFResizingGroup
	property "IFResizingGroup" {
		Get = function(self)
			return _IGASUI_ACTIONBAR_GROUP
		end,
	}
	-- IFActionHandlerGroup
	property "IFActionHandlerGroup" {
		Get = function(self)
			return _IGASUI_ACTIONBAR_GROUP
		end,
	}

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	-- Visible
	property "Visible" {
		Get = function(self)
			return self:IsShown() and true or false
		end,
		Set = function(self, value)
			if self.Visible ~= value then
				if value then
					self:Show()
				else
					self:Hide()
				end
				if self.Brother then
					self.Brother.Visible = value
				end
				if not value and self.Branch then
					self.Branch.Visible = value
				end
			end
		end,
		Type = System.Boolean,
	}
	-- RowCount
	property "RowCount" {
		Get = function(self)
			return self.__Row or 1
		end,
	}
	-- ColCount
	property "ColCount" {
		Get = function(self)
			return self.__Col or 1
		end,
	}
	-- BranchCount
	property "BranchCount" {
		Get = function(self)
			return self.__BranchNum or 0
		end,
	}
	-- Expansion
	property "Expansion" {
		Get = function(self)
			return self.__Expansion or false
		end,
		Set = function(self, value)
			if self.__Expansion ~= value then
				self.__Expansion = value
				IFNoCombatTaskHandler._RegisterNoCombatTask(UpdateExpansion, self, value)
			end
		end,
		Type = System.Boolean,
	}
	-- Brother
	property "Brother" {
		Get = function(self)
			return self.__Brother
		end,
		Set = function(self, value)
			self.__Brother = value
			if value then
				value.Header = self.Header
				value.FreeMode = self.FreeMode
				value.Scale = self.Scale
				value.ID = self.ID + 1
				value.ActionBar = self.ActionBar
				value.MainBar = self.MainBar
				value.LockMode = self.LockMode
				value.AutoSwapRoot = self.AutoSwapRoot
				value:SetSize(self:GetSize())

				if self.ITail then
					self.ITail.ActionButton = value
				end
			end
		end,
		Type = IActionButton + nil,
	}
	-- Branch
	property "Branch" {
		Get = function(self)
			return self.__Branch
		end,
		Set = function(self, value)
			self.__Branch = value
			if value then
				value.Root = self.Root
				value.Header = self.Header
				value.FreeMode = self.FreeMode
				value.Scale = self.Scale
				value.LockMode = self.LockMode
				value:SetSize(self:GetSize())
			end
		end,
		Type = IActionButton + nil,
	}
	-- Header
	property "Header" {
		Get = function(self)
			return self.__Header or self
		end,
		Set = function(self, value)
			if value == self then value = nil end

			if self.__Header ~= value then
				self.__Header = value
				if value then
					RegisterBrother(self, value)
				else
					RemoveBrother(self)
				end
			end
		end,
		Type = IActionButton + nil,
	}
	-- Root
	property "Root" {
		Get = function(self)
			return self.__Root or self
		end,
		Set = function(self, value)
			if value == self then value = nil end

			if self.__Root ~= value then
				self.__Root = value
				if value then
					RegisterBranch(self, value)
				else
					RemoveBranch(self)
				end
			end
		end,
		Type = IActionButton + nil,
	}
	-- ActionBar
	property "ActionBar" {
		Get = function(self)
			return self.ActionPage
		end,
		Set = function(self, value)
			if self.ActionBar ~= value then
				self.ActionPage = value
				if self.Brother then
					self.Brother.ActionBar = value
				end
			end
		end,
		Type = System.Number + nil,
	}
	-- MainBar
	property "MainBar" {
		Get = function(self)
			return self.MainPage
		end,
		Set = function(self, value)
			if self.MainBar ~= value then
				self.MainPage = value
				if self.Brother then
					self.Brother.MainBar = value
				end
			end
		end,
		Type = System.Boolean,
	}
	-- PetBar
	property "PetBar" {
		Get = function(self)
			return self.__PetBar or false
		end,
		Set = function(self, value)
			if self.PetBar ~= value then
				if value and self.ReplaceBlzMainAction then return end
				self.__PetBar = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(function()
						self:GenerateBrother(1, _G.NUM_PET_ACTION_SLOTS)
						local brother = self
						while brother do
							brother:GenerateBranch(0)
							brother:SetAction("pet", brother.ID)
							brother = brother.Brother
						end
						RegisterPetAction(self)
					end)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(function()
						UnregisterPetAction(self)
						self:GenerateBrother(1, 1)
						self:SetAction(nil)
					end)
				end
			end
		end,
		Type = System.Boolean,
	}
	-- StanceBar
	property "StanceBar" {
		Get = function(self)
			return self.__StanceBar or false
		end,
		Set = function(self, value)
			if self.StanceBar ~= value then
				if value and self.ReplaceBlzMainAction then return end
				self.__StanceBar = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(function()
						self:GenerateBrother(1, _G.NUM_STANCE_SLOTS)
						self:GenerateBranch(0)
					end)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(function()
						self:GenerateBrother(1, 1)
						self:GenerateBranch(0)
						self:SetAction(nil)
					end)
				end
			end
		end,
		Type = System.Boolean,
	}
	-- QuestBar
	property "QuestBar" {
		Get = function(self)
			return self.__QuestBar or false
		end,
		Set = function(self, value)
			if self.QuestBar ~= value then
				self.__QuestBar = value
			end
		end,
		Type = System.Boolean,
	}
	-- HideOutOfCombat
	property "HideOutOfCombat" {
		Get = function(self)
			return self.__HideOutOfCombat or false
		end,
		Set = function(self, value)
			if self.HideOutOfCombat ~= value then
				if value and self.ReplaceBlzMainAction then return end
				self.__HideOutOfCombat = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(RegisterOutCombat, self)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(UnregisterOutCombat, self)
				end
			end
		end,
		Type = System.Boolean,
	}
	-- HideInPetBattle
	property "HideInPetBattle" {
		Get = function(self)
			return self.__HideInPetBattle or false
		end,
		Set = function(self, value)
			if self.HideInPetBattle ~= value then
				if value and self.ReplaceBlzMainAction then return end
				self.__HideInPetBattle = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(RegisterNoPetBattle, self)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(UnregisterNoPetBattle, self)
				end
			end
		end,
		Type = System.Boolean,
	}
	-- HideInVehicle
	property "HideInVehicle" {
		Get = function(self)
			return self.__HideInVehicle or false
		end,
		Set = function(self, value)
			if self.HideInVehicle ~= value then
				if value and self.ReplaceBlzMainAction then return end
				self.__HideInVehicle = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(RegisterNoVehicle, self)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(UnregisterNoVehicle, self)
				end
			end
		end,
		Type = System.Boolean,
	}
	-- AutoSwapRoot
	property "AutoSwapRoot" {
		Get = function(self)
			return self.__AutoSwapRoot or false
		end,
		Set = function(self, value)
			if self.AutoSwapRoot ~= value then
				self.__AutoSwapRoot = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(RegisterAutoSwap, self)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(UnregisterAutoSwap, self)
				end
			end
		end,
		Type = System.Boolean,
	}
	--- Parent
	property "Parent" {
		Get = function(self)
			return self:GetParent()
		end,
		Set = function(self, parent)
			self:SetParent(parent)
			if self.Brother then
				self.Brother.Parent = parent
			end
			if self.Branch then
				self.Branch.Parent = parent
			end
		end,
		Type = UIObject + nil,
	}
	-- FrameLevel
	property "FrameLevel" {
		Get = function(self)
			return self:GetFrameLevel()
		end,
		Set = function(self, level)
			self:SetFrameLevel(level)
			if self.Brother then
				self.Brother.FrameLevel = level
			end
			if self.Branch then
				self.Branch.FrameLevel = level
			end
		end,
		Type = Number,
	}
	-- FreeMode
	property "FreeMode" {
		Get = function(self)
			return self.IFMovable or self.IFResizable
		end,
		Set = function(self, value)
			if self.FreeMode == value then return end
			if value and self.ReplaceBlzMainAction then return end

			self.IFMovable = value
			self.IFResizable = value

			if self.Header == self and not value then
				self:SetSize(36, 36)
				self:GenerateBrother(nil, nil, true)
			end
			if self.Root == self and not value then
				self:GenerateBranch(nil, true)
			end
			if self.Brother then
				self.Brother.FreeMode = value
			end
			if self.Branch then
				self.Branch.FreeMode = value
			end
			if self.ITail then
				self.ITail.Visible = not self.LockMode and not self.FreeMode
			end

			self.ShowFlyOut = self.BranchCount > 0 and (not self.LockMode or not self.FreeMode)
		end,
		Type = System.Boolean,
	}
	-- LockMode
	property "LockMode" {
		Get = function(self)
			return not self.ShowGrid
		end,
		Set = function(self, value)
			if self.LockMode ~= value then
				if not value and self.ReplaceBlzMainAction then return end
				self.ShowGrid = not value
				if self.Brother then
					self.Brother.LockMode = value
				end
				if self.Branch then
					self.Branch.LockMode = value
				end
				if self.IHeader then
					self.IHeader.Checked = value
				end
				if self.ITail then
					self.ITail.Visible = not self.LockMode and not self.FreeMode
				end

				self.ShowFlyOut = self.BranchCount > 0 and (not self.LockMode or not self.FreeMode)
			end
		end,
		Type = System.Boolean,
	}
	-- MarginX
	property "MarginX" {
		Get = function(self)
			if self.Header == self then
				return self.__MarginX or 0
			else
				return self.Header.MarginX
			end
		end,
		Set = function(self, value)
			if self.Header == self and self.__MarginX ~= value then
				self.__MarginX = value
				self:GenerateBrother(nil, nil, true)
				while self do
					self:GenerateBranch(nil, true)
					self = self.Brother
				end
			end
		end,
		Type = System.Number,
	}
	-- MarginY
	property "MarginY" {
		Get = function(self)
			if self.Header == self then
				return self.__MarginY or 0
			else
				return self.Header.MarginY
			end
		end,
		Set = function(self, value)
			if self.Header == self and self.__MarginY ~= value then
				self.__MarginY = value
				self:GenerateBrother(nil, nil, true)
				while self do
					self:GenerateBranch(nil, true)
					self = self.Brother
				end
			end
		end,
		Type = System.Number,
	}
	-- Scale
	property "Scale" {
		Get = function(self)
			return self:GetScale()
		end,
		Set = function(self, scale)
			self:SetScale(scale)
			if self.Brother then
				self.Brother.Scale = scale
			end
			if self.Branch then
				self.Branch.Scale = value
			end
		end,
		Type = Number,
	}
	-- ReplaceBlzMainAction
	property "ReplaceBlzMainAction" {
		Get = function(self)
			if self.Header == self then
				return self.__ReplaceBlzMainAction or false
			else
				return self.Header.ReplaceBlzMainAction
			end
		end,
		Set = function(self, value)
			if self.Header == self and self.ReplaceBlzMainAction ~= value then
				self.__ReplaceBlzMainAction = value
				if value then
					IFNoCombatTaskHandler._RegisterNoCombatTask(function()
						self.FreeMode = false
						self.LockMode = true
						self.HideOutOfCombat = false
						self.HideInPetBattle = false
						self.HideInVehicle = false
						self:GenerateBrother(1, 12)
						self:ClearAllPoints()
						self:SetPoint("BOTTOMLEFT", IGAS.MainMenuBarArtFrame, "BOTTOMLEFT", 8, 4)
						self.Parent = IGAS.MainMenuBarArtFrame
						self.FrameLevel = _G["ActionButton1"]:GetFrameLevel() + 1
						local btn
						for i = 1, 12 do
							_G["ActionButton"..i]:SetAlpha(0)
						end
					end)
				else
					IFNoCombatTaskHandler._RegisterNoCombatTask(function()
						self.LockMode = false
						self:ClearAllPoints()
						self.Parent = IGAS.UIParent
						self:SetPoint("CENTER")
						local btn
						for i = 1, 12 do
							_G["ActionButton"..i]:SetAlpha(1)
						end
					end)
				end
			end
		end,
		Type = System.Boolean,
	}

	------------------------------------------------------
	-- Script Handler
	------------------------------------------------------
	local function OnMouseDown(self)
		if not InCombatLockdown() and IsAltKeyDown() and not self.Branch and not self.FlytoutID then
			return self.Root:ThreadCall(function(self)
				local l, b, w, h = self:GetRect()
				local e = self:GetEffectiveScale()
				local x, y, num

				while IsMouseButtonDown("LeftButton") and not InCombatLockdown() and IsAltKeyDown() do
					Threading.Sleep(0.1)

					x, y = GetCursorPosition()
					x, y = x / e, y /e

					row = floor((b + h - y) / h)
					col = floor((x - l) / w)

					if abs(col) >= abs(row) then
						num = abs(col)
						if col >= 0 then
							self.FlyoutDirection = "RIGHT"
						else
							num = num - 1
							self.FlyoutDirection = "LEFT"
						end
					else
						num = abs(row)
						if row >= 0 then
							self.FlyoutDirection = "DOWN"
						else
							num = num - 1
							self.FlyoutDirection = "UP"
						end
					end

					self:GenerateBranch(num)
				end
			end)
		end
	end

	local function OnEnter(self)
		if not InCombatLockdown() then
			if self.IHeader then
				self.IHeader.Visible = not _DBChar.LockBar
			end
			if self.ITail then
				self.ITail.Visible = not self.LockMode and not self.FreeMode
			end
		end
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function IActionButton()
		local obj = Super(_Prefix.._Index, IGAS.UIParent)
		_Index = _Index + 1

		obj:ConvertClass(IActionButton)

		obj.IFMovable = false
		obj.IFResizable = false
		obj.ShowGrid = true
		obj.ID = 1

		obj.MarginX = 2
		obj.MarginY = 2

		obj.OnEnter = obj.OnEnter + OnEnter
		obj.OnMouseDown = obj.OnMouseDown + OnMouseDown

		-- callback from RestrictedEnvironment, maybe add some mechanism solve this later
		IGAS:GetUI(obj).IActionHandler_UpdateExpansion = IActionHandler_UpdateExpansion

		IFNoCombatTaskHandler._RegisterNoCombatTask(SetupActionButton, obj)

		obj.UseBlizzardArt = true

		return obj
    end
endclass "IActionButton"

-----------------------------------------------
--- IHeader
-- @type class
-- @name IHeader
-----------------------------------------------
class "IHeader"
	inherit "Button"

	_ClickCheckTime = 0.2

	_Prefix = "IHeader"
	_Index = 1
	_BackDrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\ChatFrame\\CHATFRAMEBACKGROUND",
        tile = true, tileSize = 16, edgeSize = 1,
	}
	_CheckedColor = ColorType(1, 1, 1)
	_UnCheckedColor = ColorType(0, 0, 0)


	------------------------------------------------------
	-- Script
	------------------------------------------------------
	script "OnPositionChanged"

	------------------------------------------------------
	-- Method
	------------------------------------------------------

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	-- ActionButton
	property "ActionButton" {
		Get = function(self)
			return self.Parent
		end,
		Set = function(self, value)
			if value then
				self.Parent = value
				self:SetPoint("BOTTOMRIGHT", value, "TOPLEFT")
				self.Visible = true
				self.Checked = value.LockMode
			else
				self.Parent = nil
				self:ClearAllPoints()
				self.Visible = false
			end
		end,
		Type = Frame + nil,
	}
	-- Checked
	property "Checked" {
		Get = function(self)
			return self.CheckedTexture.Visible
		end,
		Set = function(self, value)
			self.CheckedTexture.Visible = value
		end,
		Type = System.Boolean,
	}

	------------------------------------------------------
	-- Script Handler
	------------------------------------------------------
	local function OnMouseDown(self, button)
		self.__MouseDown = GetTime()
		if button == "LeftButton" and not self.Checked and not InCombatLockdown() then
			self:ThreadCall(function(self)
				local parent = self.Parent
				local e = parent:GetEffectiveScale()
				local x, y

				Threading.Sleep(_ClickCheckTime)

				while IsMouseButtonDown("LeftButton") and not InCombatLockdown() do
					x, y = GetCursorPosition()
					x, y = x / e, y /e
					x = x + self.Width / 2
					y = y - self.Height / 2
					parent:ClearAllPoints()
					parent:SetPoint("TOPLEFT", IGAS.UIParent, "BOTTOMLEFT", x, y)

					Threading.Sleep(0.1)
				end

				return self:Fire("OnPositionChanged")
			end)
		end
	end

	local function OnMouseUp(self, button)
		if button == "LeftButton" then
			self.Parent:StopMovingOrSizing()
			self:Fire("OnPositionChanged")
		end
	end

	local function OnClick(self, button)
		if not self.Parent:IsClass(IActionButton) then return end
		if button == "RightButton" and not InCombatLockdown() then
			_Menu.Parent = self.Parent
			_Menu.Visible = true
		--[[elseif button == "LeftButton" then
			if (GetTime() - self.__MouseDown or 0) < _ClickCheckTime then
				self.Parent.LockMode = not self.Parent.LockMode
			end--]]
		end
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function IHeader()
		local header = Super(_Prefix.._Index, IGAS.UIParent)
		_Index = _Index + 1

		header.Parent = nil
		header.Name = "IHeader"
		header.Visible = false
		header.Width = 24
		header.Height = 24
		header.MouseEnabled = true
		header:RegisterForClicks("AnyUp")

		header:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
		header:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])

		local txtCheck = Texture("CheckedTexture", header)
		txtCheck.TexturePath = [[Interface\Buttons\UI-CheckBox-Check]]
		txtCheck:SetAllPoints()
		txtCheck.Visible = false

		--header.OnMouseUp = header.OnMouseUp + OnMouseUp
		header.OnMouseDown = header.OnMouseDown + OnMouseDown
		header.OnClick = header.OnClick + OnClick

		return header
    end
endclass "IHeader"

-----------------------------------------------
--- ITail
-- @type class
-- @name ITail
-----------------------------------------------
class "ITail"
	inherit "Button"

	_Prefix = "ITail"
	_Index = 1

	------------------------------------------------------
	-- Script
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	-- ActionButton
	property "ActionButton" {
		Get = function(self)
			return self.Parent
		end,
		Set = function(self, value)
			if value then
				self.Parent = value
				self:SetPoint("BOTTOMRIGHT", value, "BOTTOMRIGHT")
				self.Visible = not self.Parent.FreeMode and not self.Parent.LockMode
			else
				self.Parent = nil
				self:ClearAllPoints()
				self.Visible = false
			end
		end,
		Type = IActionButton + nil,
	}

	------------------------------------------------------
	-- Script Handler
	------------------------------------------------------
	local function OnMouseDown(self)
		if not self.Parent.LockMode and not InCombatLockdown() then
			self:ThreadCall(function(self)
				local header = self.Parent.Header
				local l, b, w, h = header:GetRect()
				local e = header:GetEffectiveScale()
				local x, y, row, col
				local last

				while IsMouseButtonDown("LeftButton") and not InCombatLockdown() do
					Threading.Sleep(0.1)

					x, y = GetCursorPosition()
					x, y = x / e, y /e

					row = ceil((b + h - y) / h)
					col = ceil((x - l) / w)

					last = header:GenerateBrother(row, col)
					if last then
						self.ActionButton = last
					end
				end
			end)
		end
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function ITail()
		local tail = Super(_Prefix.._Index, IGAS.UIParent)
		_Index = _Index + 1

		tail.Parent = nil
		tail.Name = "ITail"
		tail.Visible = false
		tail.Width = 16
		tail.Height = 16
		tail.MouseEnabled = true

		tail.NormalTexturePath = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]]
		tail.HighlightTexturePath = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]]
		tail.PushedTexturePath = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]]

		tail.OnMouseDown = tail.OnMouseDown + OnMouseDown

		return tail
    end
endclass "ITail"

------------------------------------------------------
-- Recycle
------------------------------------------------------
_Recycle_IButtons = Recycle(IActionButton)
_Recycle_IHeaders = Recycle(IHeader)
_Recycle_ITails = Recycle(ITail)

function _Recycle_IButtons:OnPop(btn)
	btn.ShowGrid = true
	btn:Show()
end

function _Recycle_IButtons:OnPush(btn)
	btn:ClearAllPoints()
	btn:SetAction(nil)
	btn.Brother = nil
	btn.Branch = nil
	btn.Header = nil
	btn.Root = nil
	btn.Expansion = false
	btn.ID = 1
	btn.ActionBar = nil
	btn.MainBar = false
	btn.QuestBar = false
	btn.PetBar = false
	btn.StanceBar = false
	btn.HideOutOfCombat = false
	btn.HideInPetBattle = false
	btn.HideInVehicle = false
	btn.AutoSwapRoot = false
	btn:Hide()
	btn:SetSize(36, 36)
	btn:ClearBindingKey()
end

function _Recycle_IHeaders:OnInit(btn)
	btn.OnPositionChanged = SaveHeadPosition
end

function _Recycle_IHeaders:OnPush(btn)
	btn.ActionButton = nil
end

function _Recycle_ITails:OnPop(btn)

end

function _Recycle_ITails:OnPush(btn)
	btn.ActionButton = nil
end
