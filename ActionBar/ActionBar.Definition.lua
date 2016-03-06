-----------------------------------------
-- Definition for Action Bar
-----------------------------------------

IGAS:NewAddon "IGAS_UI.ActionBar"

import "System"
import "System.Widget"
import "System.Widget.Action"

_IGASUI_ACTIONBAR_GROUP = "IActionButton"

------------------------------------------------------
-- Class
------------------------------------------------------
class "IActionButton"
	inherit "ActionButton"
	extend "IFMovable" "IFResizable"

	_MaxBrother = 12
	_TempActionBrother = {}
	_TempActionBranch = {}

	-- Manager Frame
	_ManagerFrame = SecureFrame("IGASUI_IActionButton_Manager", IGAS.UIParent, "SecureHandlerStateTemplate")
	_ManagerFrame.Visible = false

	-- Init manger frame's enviroment
	Task.NoCombatCall(function ()
		_ManagerFrame:Execute[[
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
								regBtn:RegisterAutoHide(Manager:GetAttribute("PopupDuration") or 0.25)
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

		_ManagerFrame:SetAttribute("_onstate-pet", [=[
			State["pet"] = newstate == "pet"
			Manager:Run(UpdatePetHeader)
		]=])
		_ManagerFrame:SetAttribute("_onstate-incombat", [=[
			State["incombat"] = newstate == "incombat"
			for btn in pairs(InCombatHeader) do
				Manager:RunFor(btn, StateCheck)
			end
		]=])
		_ManagerFrame:SetAttribute("_onstate-petbattle", [=[
			State["petbattle"] = newstate == "inpetcombat"
			for btn in pairs(NoPetCombatHeader) do
				Manager:RunFor(btn, StateCheck)
			end
		]=])
		_ManagerFrame:SetAttribute("_onstate-vehicle", [=[
			State["vehicle"] = newstate == "invehicle"
			for btn in pairs(NoVehicleHeader) do
				Manager:RunFor(btn, StateCheck)
			end
		]=])
		_ManagerFrame:RegisterStateDriver("pet", "[pet]pet;nopet;")
		_ManagerFrame:RegisterStateDriver("incombat", "[combat]incombat;nocombat;")
		_ManagerFrame:RegisterStateDriver("petbattle", "[petbattle]inpetcombat;nopetcombat;")
		_ManagerFrame:RegisterStateDriver("vehicle", "[vehicleui]invehicle;novehicle;")

		_ManagerFrame:Execute(("State['pet'] = '%s' == 'pet'"):format(SecureCmdOptionParse("[pet]pet;nopet;")))
		_ManagerFrame:Execute(("State['incombat'] = '%s' == 'incombat'"):format(SecureCmdOptionParse("[combat]incombat;nocombat;")))
		_ManagerFrame:Execute(("State['petbattle'] = '%s' == 'inpetcombat'"):format(SecureCmdOptionParse("[petbattle]inpetcombat;nopetcombat;")))
		_ManagerFrame:Execute(("State['vehicle'] = '%s' == 'invehicle'"):format(SecureCmdOptionParse("[vehicleui]invehicle;novehicle;")))
	end)

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
			self:SetAttribute("frameref-SwapTarget", root)
			return self:RunAttribute("SwapAction")
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
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			PetHeader[btn] = true
			Manager:Run(UpdatePetHeader)
		]]
	end

	local function UnregisterPetAction(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			PetHeader[btn] = nil
			if not btn:IsShown() then
				btn:Show()
			end
		]]
	end

	local function RegisterOutCombat(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			InCombatHeader[btn] = true
			Manager:RunFor(btn, StateCheck)
		]]
	end

	local function UnregisterOutCombat(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			InCombatHeader[btn] = nil
			Manager:RunFor(btn, StateCheck)
		]]
	end

	local function RegisterNoPetBattle(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			NoPetCombatHeader[btn] = true
			Manager:RunFor(btn, StateCheck)
		]]
	end

	local function UnregisterNoPetBattle(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			NoPetCombatHeader[btn] = nil
			Manager:RunFor(btn, StateCheck)
		]]
	end

	local function RegisterNoVehicle(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			NoVehicleHeader[btn] = true
			Manager:RunFor(btn, StateCheck)
		]]
	end

	local function UnregisterNoVehicle(self)
		_ManagerFrame:SetFrameRef("StateButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("StateButton")
			NoVehicleHeader[btn] = nil
			Manager:RunFor(btn, StateCheck)
		]]
	end

	local function RegisterAutoSwap(self)
		_ManagerFrame:SetFrameRef("AutoSwapButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("AutoSwapButton")
			AutoSwapHeader[btn] = true
		]]
	end

	local function UnregisterAutoSwap(self)
		_ManagerFrame:SetFrameRef("AutoSwapButton", self)
		_ManagerFrame:Execute[[
			local btn = Manager:GetFrameRef("AutoSwapButton")
			AutoSwapHeader[btn] = nil
		]]
	end

	local function RegisterBrother(brother, header)
		_ManagerFrame:SetFrameRef("BrotherButton", brother)
		_ManagerFrame:SetFrameRef("HeaderButton", header)
		_ManagerFrame:Execute[[
			local brother, header = Manager:GetFrameRef("BrotherButton"), Manager:GetFrameRef("HeaderButton")
			HeaderMap[brother] = header
		]]
	end

	local function RemoveBrother(brother)
		_ManagerFrame:SetFrameRef("BrotherButton", brother)
		_ManagerFrame:Execute[[
			local brother = Manager:GetFrameRef("BrotherButton")
			HeaderMap[brother] = nil
		]]
	end

	local function RegisterBranch(button, root)
		_ManagerFrame:SetFrameRef("BranchButton", button)
		_ManagerFrame:SetFrameRef("RootButton", root)
		_ManagerFrame:Execute[[
			local branch, root = Manager:GetFrameRef("BranchButton"), Manager:GetFrameRef("RootButton")
			BranchMap[branch] = root
			BranchHeader[root] = true
		]]
	end

	local function RemoveBranch(button)
		_ManagerFrame:SetFrameRef("BranchButton", button)
		_ManagerFrame:Execute[[
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
	end

	local function SetupActionButton(self)
		_ManagerFrame:WrapScript(self, "OnEnter", _IActionButton_WrapEnter)
		_ManagerFrame:WrapScript(self, "OnClick", _IActionButton_WrapClickPre, _IActionButton_WrapClickPost)
		_ManagerFrame:WrapScript(self, "OnAttributeChanged", _IActionButton_WrapAttribute)
	end

	local function UpdateExpansion(self, flag)
		_ManagerFrame:SetFrameRef("ExpansionButton", self)
		_ManagerFrame:Execute(_IActionButton_UpdateExpansion:format(tostring(flag)))
	end

	local function IActionHandler_UpdateExpansion(self, flag)
		IGAS:GetWrapper(self).__Expansion = flag and true or false
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function GenerateBrother(self, row, col, force)
		row = row or self.RowCount
		col = col or self.ColCount

		if row <= 1 then row = 1 end
		if col <= 1 then col = 1 end
		if row > ceil(_MaxBrother / col) then row = ceil(_MaxBrother / col) end

		if self.Header == self and not self.FreeMode then
			if force or self.RowCount ~= row or self.ColCount ~= col then
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

				self.RowCount, self.ColCount = row, col

				return brother
			end
		end
	end

	function GenerateBranch(self, num, force)
		num = num or self.BranchCount

		if self.Root == self and not InCombatLockdown() then
			if force or self.BranchCount ~= num then
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

				self.BranchCount = num
				self.ShowFlyOut = num > 0 and (not self.LockMode or not self.FreeMode)
				if num == 0 and self.AutoActionTask then
					self.AutoActionTask:RemoveRoot(self)
					self.AutoActionTask = nil
				end
			end
		end
	end

	function UpdateAction(self)
		if self.ActionType == "flyout" then
			if self.Root ~= self then
				return Task.NoCombatCall(function ()
					self:SetAction(nil)
				end)
			else
				Task.NoCombatCall(GenerateBranch, self, 0)
			end
		end
		if self.UseBlizzardArt then
			return Super.UpdateAction(self)
		end
	end

	------------------------------------------------------
	-- Static Property
	------------------------------------------------------
	__Static__() __Handler__(function (self, value)
		Task.NoCombatCall(function ()
			_ManagerFrame:SetAttribute("PopupDuration", value)
		end)
	end)
	property "PopupDuration" { Type = NumberNil, Default = 0.25 }

	------------------------------------------------------
	-- Interface Property
	------------------------------------------------------
	property "IFMovingGroup" { Set = false, Default = _IGASUI_ACTIONBAR_GROUP }
	property "IFResizingGroup" { Set = false, Default = _IGASUI_ACTIONBAR_GROUP }
	property "IFActionHandlerGroup" { Set = false, Default = _IGASUI_ACTIONBAR_GROUP }

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "RowCount" { Type = Number, Default = 1 }
	property "ColCount" { Type = Number, Default = 1 }
	property "BranchCount" { Type = Number }

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
		Type = Boolean,
	}

	property "Expansion" {
		Handler = function (self, value)
			return Task.NoCombatCall(UpdateExpansion, self, value)
		end,
		Field = "__Expansion",
		Type = Boolean,
	}

	property "Brother" {
		Handler = function (self, value)
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
		Type = IActionButton,
	}

	property "Branch" {
		Handler = function (self, value)
			if value then
				value.Root = self.Root
				value.Header = self.Header
				value.FreeMode = self.FreeMode
				value.Scale = self.Scale
				value.LockMode = self.LockMode
				value:SetSize(self:GetSize())
			end
		end,
		Type = IActionButton,
	}

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
		Type = IActionButton,
	}

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
		Type = IActionButton,
	}

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
		Type = NumberNil,
	}

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
		Type = Boolean,
	}

	property "PetBar" {
		Handler = function (self, value)
			if value and self.ReplaceBlzMainAction then return end

			if value then
				Task.NoCombatCall(function()
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
				Task.NoCombatCall(function()
					UnregisterPetAction(self)
					self:GenerateBrother(1, 1)
					self:SetAction(nil)
				end)
			end
		end,
		Type = Boolean,
	}

	property "StanceBar" {
		Handler = function (self, value)
			if value and self.ReplaceBlzMainAction then return end

			if value then
				Task.NoCombatCall(function()
					self:GenerateBrother(1, _G.NUM_STANCE_SLOTS)
					self:GenerateBranch(0)
				end)
			else
				Task.NoCombatCall(function()
					self:GenerateBrother(1, 1)
					self:GenerateBranch(0)
					self:SetAction(nil)
				end)
			end
		end,
		Type = Boolean,
	}

	property "HideOutOfCombat" {
		Handler = function (self, value)
			if value and self.ReplaceBlzMainAction then return end

			if value then
				Task.NoCombatCall(RegisterOutCombat, self)
			else
				Task.NoCombatCall(UnregisterOutCombat, self)
			end
		end,
		Type = Boolean,
	}

	property "HideInPetBattle" {
		Handler = function(self, value)
			if value and self.ReplaceBlzMainAction then return end

			if value then
				Task.NoCombatCall(RegisterNoPetBattle, self)
			else
				Task.NoCombatCall(UnregisterNoPetBattle, self)
			end
		end,
		Type = Boolean,
	}

	property "HideInVehicle" {
		Handler = function (self, value)
			if value and self.ReplaceBlzMainAction then return end

			if value then
				Task.NoCombatCall(RegisterNoVehicle, self)
			else
				Task.NoCombatCall(UnregisterNoVehicle, self)
			end
		end,
		Type = Boolean,
	}

	property "AutoSwapRoot" {
		Handler = function (self, value)
			if value then
				Task.NoCombatCall(RegisterAutoSwap, self)
			else
				Task.NoCombatCall(UnregisterAutoSwap, self)
			end

			if self.Brother then
				self.Brother.AutoSwapRoot = value
			end
		end,
		Type = Boolean,
	}

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
		Type = UIObject,
	}

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
		Type = Boolean,
	}

	property "LockMode" {
		Field = "__LockMode",
		Set = function(self, value)
			if not value and self.ReplaceBlzMainAction then return end
			self.__LockMode = value
			self.ShowGrid = self.AlwaysShowGrid or not value
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
		end,
		Type = Boolean,
	}

	property "AlwaysShowGrid" {
		Field = "__AlwaysShowGrid",
		Set = function(self, value)
			self.__AlwaysShowGrid = value
			self.ShowGrid = value or not self.LockMode
			if self.Brother then
				self.Brother.AlwaysShowGrid = value
			end
			if self.Branch then
				self.Branch.AlwaysShowGrid = value
			end
		end,
		Type = Boolean,
	}

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
		Type = Number,
	}

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
		Type = Number,
	}

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
				self.Branch.Scale = scale
			end
		end,
		Type = Number,
	}

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
					Task.NoCombatCall(function()
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
					Task.NoCombatCall(function()
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
		Type = Boolean,
	}

	------------------------------------------------------
	-- Script Handler
	------------------------------------------------------
	local function OnMouseDown(self)
		if not InCombatLockdown() and IsAltKeyDown() and not self.Branch then
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

					if not self.FlytoutID then
						self:GenerateBranch(num)
					end
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
    function IActionButton(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.IFMovable = false
		self.IFResizable = false
		self.ShowGrid = true
		self.ID = 1

		self.MarginX = 2
		self.MarginY = 2

		self.OnEnter = self.OnEnter + OnEnter
		self.OnMouseDown = self.OnMouseDown + OnMouseDown

		-- callback from RestrictedEnvironment, maybe add some mechanism solve this later
		IGAS:GetUI(self).IActionHandler_UpdateExpansion = IActionHandler_UpdateExpansion

		Task.NoCombatCall(SetupActionButton, self)

		self.UseBlizzardArt = true
    end
endclass "IActionButton"

class "IHeader"
	inherit "Button"

	_ClickCheckTime = 0.2

	_BackDrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\ChatFrame\\CHATFRAMEBACKGROUND",
        tile = true, tileSize = 16, edgeSize = 1,
	}
	_CheckedColor = ColorType(1, 1, 1)
	_UnCheckedColor = ColorType(0, 0, 0)


	------------------------------------------------------
	-- Event
	------------------------------------------------------
	event "OnPositionChanged"

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
		Type = Frame,
	}
	-- Checked
	property "Checked" {
		Get = function(self)
			return self.CheckedTexture.Visible
		end,
		Set = function(self, value)
			self.CheckedTexture.Visible = value
		end,
		Type = Boolean,
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
    function IHeader(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.Parent = nil
		self.Name = "IHeader"
		self.Visible = false
		self.Width = 24
		self.Height = 24
		self.MouseEnabled = true
		self:RegisterForClicks("AnyUp")

		self:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
		self:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])

		local txtCheck = Texture("CheckedTexture", self)
		txtCheck.TexturePath = [[Interface\Buttons\UI-CheckBox-Check]]
		txtCheck:SetAllPoints()
		txtCheck.Visible = false

		--self.OnMouseUp = self.OnMouseUp + OnMouseUp
		self.OnMouseDown = self.OnMouseDown + OnMouseDown
		self.OnClick = self.OnClick + OnClick
    end
endclass "IHeader"

class "ITail"
	inherit "Button"

	------------------------------------------------------
	-- Property
	------------------------------------------------------
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
		Type = IActionButton,
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
    function ITail(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.Parent = nil
		self.Name = "ITail"
		self.Visible = false
		self.Width = 16
		self.Height = 16
		self.MouseEnabled = true

		self.NormalTexturePath = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]]
		self.HighlightTexturePath = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]]
		self.PushedTexturePath = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]]

		self.OnMouseDown = self.OnMouseDown + OnMouseDown
    end
endclass "ITail"

class "AutoPopupMask"
	inherit "Button"

	_FrameBackdrop = {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 8,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function SetParent(self, parent)
		Super.SetParent(self, parent)
		if parent then
			self:ClearAllPoints()
			self:SetPoint("BOTTOMLEFT")
			self.Width = parent.Width
			self.Height = parent.Height
		else
			self:ClearAllPoints()
		end
	end

	------------------------------------------------------
	-- Event Handler
	------------------------------------------------------
	local function OnShow(self)
		if not self.Parent then
			self.Visible = false
			return
		end
		self.Width = self.Parent.Width
		self.Height = self.Parent.Height
	end

	local function OnClick(self, button)
		autoGenerateForm.RootActionButton = self.Parent

		local pd = PopupDialog("IGAS_GUI_MSGBOX", WorldFrame)
		if pd.Visible then pd:GetChild("OkayBtn"):Click() end

		autoGenerateForm.Visible = true
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function AutoPopupMask(self, name, parent, ...)
    	Super(self, name, parent, ...)

		self.Visible = false

		self:SetPoint("BOTTOMLEFT")

		self.TopLevel = true
		self.FrameStrata = "TOOLTIP"
		self.MouseEnabled = true
		self:RegisterForClicks("AnyUp")

		self.Backdrop = _FrameBackdrop
		self.BackdropColor = ColorType(1, 1, 1, 1)

		self.OnShow = self.OnShow + OnShow
		self.OnClick = self.OnClick + OnClick
	end
endclass "AutoPopupMask"

class "AutoActionTask"
	enum "AutoActionTaskType" {
		"List",
		"Spell",
		"Item",
		"Toy",
		"BattlePet",
		"Mount",
		"EquipSet",
	}

	local yield = coroutine.yield

	local function getList(self)
		local filter = self.Filter
		for _, item in ipairs(self.List) do
			local ty, target = item:match("^%w+_(.*)$")
			target = tonumber(target) or target
			if not filter or filter(ty, target) then
				yield(ty, target)
			end
		end
	end

	local function getSpell(self)
		local filter = self.Filter
		local index = 1
		local _, id = GetSpellBookItemInfo(index, "spell")

		while id do
			if not filter or filter(id, index) then
				yield("spell", id)
			end
			index = index + 1
			_, id = GetSpellBookItemInfo(index, "spell")
		end
	end

	local function getItem(self)
		local filter = self.Filter
		for bag = 0, _G.NUM_BAG_FRAMES do
			for slot = 1, GetContainerNumSlots(bag) do
				local link = GetContainerItemLink(bag, slot)
				link = tonumber(link and link:match("item:(%d+)"))
				if link and GetItemSpell(link) and (not filter or filter(link, bag, slot)) then yield("item", link) end
			end
		end
	end

	local function getToy(self)
		local filter = self.Filter
		local onlyFavourite = self.OnlyFavourite
		for i = 1, C_ToyBox.GetNumToys() do
			local index = C_ToyBox.GetToyFromIndex(i)

			if index > 0 then
				local item = C_ToyBox.GetToyInfo(index)
				if PlayerHasToy(item) then
					if not onlyFavourite or C_ToyBox.GetIsFavorite(item) then
						if not filter or filter(item, index) then
							yield("item", item)
						end
					end
				end
			end
		end
	end

	local function getBattlePet(self)
		local filter = self.Filter
		local onlyFavourite = self.OnlyFavourite
		for index = 1, C_PetJournal.GetNumPets() do
			local petID, speciesID, isOwned, _, _, favorite = C_PetJournal.GetPetInfoByIndex(index)
			if isOwned and (not onlyFavourite or favorite) then
				if not filter or filter(petID, index) then
					yield("battlepet", petID)
				end
			end
		end
	end

	local function getMount(self)
		local filter = self.Filter
		local onlyFavourite = self.OnlyFavourite
		for index = 1, C_MountJournal.GetNumMounts() do
			local creatureName, creatureID, _, _, summonable, _, isFavorite, _, _, _, owned = C_MountJournal.GetMountInfo(index)
			if owned and summonable then
				if not onlyFavourite or isFavorite then
					if not filter or filter(creatureID, index) then
						yield("mount", creatureID)
					end
				end
			end
		end
	end

	local function getEquipSet(self)
		local filter = self.Filter
		local index = 1
		local name = GetEquipmentSetInfo(index)
		while name do
			if not filter or filter(name, index) then
				yield("equipmentset", name)
			end
			index = index + 1
			name = GetEquipmentSetInfo(index)
		end
	end

	local function task(self, root, iter, ...)
		local mark = self.TaskMark
		local runOnce = select("#", ...) == 0

		while mark == self.TaskMark do
			if InCombatLockdown() then Task.Event("PLAYER_REGEN_ENABLED") end
			if mark ~= self.TaskMark then break end
			if not root.Branch then break end

			local btn = root
			local cnt = 0
			local autoGen = self.AutoGenerate and not root.FreeMode
			local maxAction = self.MaxAction or 99

			for ty, target, detail in Threading.Iterator(iter), self do
				if cnt < maxAction then
					if cnt > 0 then
						if not btn.Branch then
							if autoGen then
								root:GenerateBranch(cnt)
								btn = btn.Branch
								btn:SetAction(ty, target, detail)
								cnt = cnt + 1
							end
						else
							btn = btn.Branch
							btn:SetAction(ty, target, detail)
							cnt = cnt + 1
						end
					else
						btn:SetAction(ty, target, detail)
						cnt = cnt + 1
					end
				end
			end

			root:GenerateBranch(cnt > 1 and cnt - 1 or 1)
			if cnt <= 1 then root.Branch:SetAction(nil) end
			if cnt <= 0 then root:SetAction(nil) end

			if runOnce then break end

			Task.Wait(...)
		end

		Log(4, "Stop task %s for %s", self.Type, root:GetName())
	end

	function AddRoot(self, root)
		self.Roots = self.Roots or {}
		self.Roots[root] = true
	end

	function RemoveRoot(self, root)
		if self.Roots and self.Roots[root] then
			self.Roots[root] = nil
			self:RestartTask()
		end
	end

	function RestartTask(self)
		self:StopTask()
		for root in pairs(self.Roots) do
			self:StartTask(root)
		end
	end

	function StartTask(self, root)
		self.TaskMark = (self.TaskMark or 0)

		if self.Type == AutoActionTaskType.List then
			return Task.ThreadCall(task, self, getList)
		elseif AutoActionTaskType.Spell then
			return Task.ThreadCall(task, self, getSpell, "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED", "SKILL_LINES_CHANGED", "PLAYER_GUILD_UPDATE", "PLAYER_SPECIALIZATION_CHANGED")
		elseif AutoActionTaskType.Item then
			return Task.ThreadCall(task, self, getItem, "BAG_NEW_ITEMS_UPDATED", "BAG_UPDATE")
		elseif AutoActionTaskType.Toy then
			return Task.ThreadCall(task, self, getToy, "TOYS_UPDATED")
		elseif AutoActionTaskType.BattlePet then
			return Task.ThreadCall(task, self, getBattlePet, "PET_JOURNAL_LIST_UPDATE", "PET_JOURNAL_PET_DELETED")
		elseif AutoActionTaskType.Mount then
			return Task.ThreadCall(task, self, getMount, "COMPANION_LEARNED", "COMPANION_UNLEARNED", "MOUNT_JOURNAL_USABILITY_CHANGED")
		elseif AutoActionTaskType.EquipSet then
			return Task.ThreadCall(task, self, getEquipSet, "EQUIPMENT_SETS_CHANGED")
		end
	end

	function StopTask(self) self.TaskMark = (self.TaskMark or 0) + 1 end

	property "Name" { Type = String }
	property "Type" { Type = AutoActionTaskType }
	property "OnlyFavourite" { Type = Boolean }
	property "AutoGenerate" { Type = Boolean }
	property "MaxAction" { Type = NaturalNumber }
	property "Filter" { Type = Function }
	__Handler__(function(self, code)
		if code then
			if code:match("^%s*function") then
				code = "return " .. code:gsub("^%s*function%s*[^%(]*", "function")
				self.Filter = assert(loadstring(code))()
			else
				self.Filter = loadstring(code)
			end
		else
			self.Filter = nil
		end
	end)
	property "FilterCode" { Type = String }
	property "List" { Type = Table }

	_AutoActionTask = {}

	function AutoActionTask(self, name)
		self.Name = name
		_AutoActionTask[name] = self
	end

	function __exist(name)
		return _AutoActionTask[name]
	end
endclass "AutoActionTask"

------------------------------------------------------
-- Recycle
------------------------------------------------------
_Recycle_IButtons = Recycle(IActionButton, "IActionButton%d", UIParent)
_Recycle_IHeaders = Recycle(IHeader, "IHeader%d", UIParent)
_Recycle_ITails = Recycle(ITail, "ITail%d", UIParent)
_Recycle_AutoPopupMask = Recycle(AutoPopupMask, "AutoPopupMask%d", UIParent)

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
end

function _Recycle_IHeaders:OnPush(btn)
	btn.ActionButton = nil
end

function _Recycle_ITails:OnPop(btn)

end

function _Recycle_ITails:OnPush(btn)
	btn.ActionButton = nil
end

function _Recycle_AutoPopupMask:OnPush(mask)
	mask.Parent = nil
	mask.Visible = false
end