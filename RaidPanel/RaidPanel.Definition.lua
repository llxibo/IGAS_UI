IGAS:NewAddon "IGAS_UI.RaidPanel"

--==========================
-- Definition for RaidPanel
--==========================
_IGASUI_RAIDPANEL_GROUP = "IRaidPanel"
_IGASUI_SPELLHANDLER = IFSpellHandler._Group(_IGASUI_RAIDPANEL_GROUP)

class "iRaidUnitFrame"
	inherit "UnitFrame"
	extend "IFSpellHandler"

	local function setProperty(self, prop, value)
		self[prop] = value
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function ApplyConfig(self, config)
		if type(config) ~= "table" or #config == 0 then return end

		for prop, value in pairs(config) do
			if type(prop) == "string" then
				pcall(setProperty, self, prop, value)
			end
		end

		for _, name in ipairs(config) do
			local set = type(name) == "string" and Config.Elements[name] or name
			local obj

			-- Create element
			if set.Name then
				self:AddElement(set.Name, set.Type, set.Direction, set.Size, set.Unit)
				obj = self:GetElement(set.Name)
			else
				self:AddElement(set.Type, set.Direction, set.Size, set.Unit)
				obj = self:GetElement(set.Type)
			end

			-- Apply init
			if type(set.Init) == "function" then
				pcall(set.Init, obj)
			end

			-- Apply Size
			if set.Size then
				pcall(setProperty, obj, "Size", set.Size)
			end

			-- Apply Location
			if not set.Direction and set.Location then
				obj.Location = set.Location
			end

			-- Apply Property
			if set.Property then
				for p, v in pairs(set.Property) do
					pcall(setProperty, obj, p, v)
				end
			end
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "IFSpellHandlerGroup" {
		Set = false,
		Default = _IGASUI_RAIDPANEL_GROUP,
	}

	function iRaidUnitFrame(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.Panel.VSpacing = Config.UNITFRAME_VSPACING
		self.Panel.HSpacing = Config.UNITFRAME_HSPACING
		self.Panel.FrameLevel = 0
	end
endclass "iRaidUnitFrame"

class "iUnitPanel"
	inherit "UnitPanel"

	local function OnElementAdd(self, ele)
		ele:ApplyConfig(Config.Style[self.Style])
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "Style" { Type = String, Default = "Normal" }

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function iUnitPanel(self, ...)
    	Super(self, ...)

		self.ElementType = iRaidUnitFrame

		self.OnElementAdd = self.OnElementAdd + OnElementAdd

		self.VSpacing = Config.UNITPANEL_VSPACING
		self.HSpacing = Config.UNITPANEL_HSPACING
		self.MarginTop = Config.UNITPANEL_MARGINTOP
		self.MarginBottom = Config.UNITPANEL_MARGINBOTTOM
		self.MarginLeft = Config.UNITPANEL_MARGINLEFT
		self.MarginRight = Config.UNITPANEL_MARGINRIGHT
    end
endclass "iUnitPanel"

class "iPetUnitPanel"
	inherit "PetUnitPanel"

	local function OnElementAdd(self, ele)
		ele:ApplyConfig(Config.Style[self.Style])
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "Style" { Type = String, Default = "Pet" }

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function iPetUnitPanel(self, ...)
    	Super(self, ...)

		self.ElementType = iRaidUnitFrame

		self.OnElementAdd = self.OnElementAdd + OnElementAdd

		self.VSpacing = Config.UNITPANEL_VSPACING
		self.HSpacing = Config.UNITPANEL_HSPACING
		self.MarginTop = Config.UNITPANEL_MARGINTOP
		self.MarginBottom = Config.UNITPANEL_MARGINBOTTOM
		self.MarginLeft = Config.UNITPANEL_MARGINLEFT
		self.MarginRight = Config.UNITPANEL_MARGINRIGHT
    end
endclass "iPetUnitPanel"

class "iUnitWatchPanel"
	inherit "SecureFrame"
	extend "IFSecurePanel"

	MAX_RAID_MEMBERS = _G.MAX_RAID_MEMBERS
	NUM_RAID_GROUPS = _G.NUM_RAID_GROUPS
	MEMBERS_PER_RAID_GROUP = _G.MEMBERS_PER_RAID_GROUP

	local function OnElementAdd(self, ele)
		ele:ApplyConfig(Config.Style[self.Style])
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "Style" { Type = String, Default = "UnitWatch" }

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function iUnitWatchPanel(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.ElementType = iRaidUnitFrame

		self.OnElementAdd = self.OnElementAdd + OnElementAdd

		self.RowCount = MEMBERS_PER_RAID_GROUP
		self.ColumnCount = NUM_RAID_GROUPS
		self.ElementWidth = 80
		self.ElementHeight = 32

		self.Orientation = Orientation.HORIZONTAL
		self.AutoSize = true

		self.VSpacing = Config.UNITPANEL_VSPACING
		self.HSpacing = Config.UNITPANEL_HSPACING
		self.MarginTop = Config.UNITPANEL_MARGINTOP
		self.MarginBottom = Config.UNITPANEL_MARGINBOTTOM
		self.MarginLeft = Config.UNITPANEL_MARGINLEFT
		self.MarginRight = Config.UNITPANEL_MARGINRIGHT
    end
endclass "iUnitWatchPanel"

class "BindingButton"
	inherit "Mask"

	BOOKTYPE_SPELL = _G.BOOKTYPE_SPELL

	HELPFUL_COLOR = ColorType(0, 1, 0, 0.4)
	HARMFUL_COLOR = ColorType(1, 0, 0, 0.6)

	------------------------------------------------------
	-- Script
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	------------------------------------
	--- Set binding key to spell
	-- @name SetBindingKey
	-- @type function
	-- @param key
	-- @return nil
	------------------------------------
	function SetBindingKey(self, key)
		if _G.SpellBookFrame.bookType ~= BOOKTYPE_SPELL then
			return
		end

		local parent = IGAS:GetUI(self.Parent)
		local slot, slotType, slotID = SpellBook_GetSpellBookSlot(parent)
		local skillType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
		local isPassive = IsPassiveSpell(slot, BOOKTYPE_SPELL)

		if slotType == "FUTURESPELL" or slotType == "FLYOUT" or isPassive then
			return
		else
			_IGASUI_SPELLHANDLER.Spell(spellId, self.With, IsHarmfulSpell(slot, BOOKTYPE_SPELL)).Key = key
			return Masks:Each(RefreshBindingKey)
		end
	end

	------------------------------------
	--- Clear binding key to spell
	-- @name ClearBindingKey
	-- @type function
	-- @param ...
	-- @return nil
	------------------------------------
	function ClearBindingKey(self, oldkey)
		if _G.SpellBookFrame.bookType ~= BOOKTYPE_SPELL then
			return
		end

		local parent = IGAS:GetUI(self.Parent)
		local slot, slotType, slotID = SpellBook_GetSpellBookSlot(parent)
		local skillType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
		local isPassive = IsPassiveSpell(slot, BOOKTYPE_SPELL)

		if slotType == "FUTURESPELL" or slotType == "FLYOUT" or isPassive then
			return
		end

		if spellId then
			_IGASUI_SPELLHANDLER:Clear("Spell", spellId)

			return Masks:Each(RefreshBindingKey)
		end
	end

	------------------------------------
	--- Refresh binding key
	-- @name RefreshBindingKey
	-- @type function
	------------------------------------
	function RefreshBindingKey(self)
		self.BindKey = nil

		if _G.SpellBookFrame.bookType ~= BOOKTYPE_SPELL then
			self.Visible = false
			return
		end

		local parent = IGAS:GetUI(self.Parent)
		local slot, slotType, slotID = SpellBook_GetSpellBookSlot(parent)

		if not slot then
			self.Visible = false
			return
		end

		local skillType, spellId = GetSpellBookItemInfo(slot, BOOKTYPE_SPELL)
		local isPassive = IsPassiveSpell(slot, BOOKTYPE_SPELL)

		if slotType == "FUTURESPELL" or slotType == "FLYOUT" or isPassive then
			self.Visible = false
		else
			local isHarmful = IsHarmfulSpell(slot, BOOKTYPE_SPELL)

			self.Visible = true
			local set = _IGASUI_SPELLHANDLER.Spell(spellId)
			self.BindKey, self.With = set.Key, set.With

			if isHarmful then
				self.BackdropColor = HARMFUL_COLOR
			else
				self.BackdropColor = HELPFUL_COLOR
			end
		end

		if withPanel.Target == self then
			chkTarget.Checked = self.With == "target"
			chkFocus.Checked = self.With == "focus"
		end
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------

	------------------------------------------------------
	-- Script Handler
	------------------------------------------------------
	local function OnKeySet(self, key)
		self:SetBindingKey(key)
	end

	local function OnKeyClear(self, oldkey)
		self:ClearBindingKey(oldkey)
	end

	local function OnLeave(self)
		IGAS.GameTooltip:Hide()
	end

	local function OnEnter(self)
		withPanel.Target = self
		withPanel:ClearAllPoints()
		withPanel:SetPoint("TOPRIGHT", self, "TOPLEFT")
		chkTarget.Checked = self.With == "target"
		chkFocus.Checked = self.With == "focus"
		withPanel.Visible = true

		SpellButton_OnEnter(IGAS:GetUI(self.Parent))
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function BindingButton(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.AsKeyBind = true

		self.OnEnter = self.OnEnter + OnEnter
		self.OnLeave = self.OnLeave + OnLeave

		self.OnKeySet = self.OnKeySet + OnKeySet
		self.OnKeyClear = self.OnKeyClear + OnKeyClear
    end
endclass "BindingButton"
