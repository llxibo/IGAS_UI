IGAS:NewAddon "IGAS_UI.RaidPanel"

--==========================
-- Layout for RaidPanel
--==========================

import "System.Widget"
import "System.Widget.Unit"

--==========================
-- Global
--==========================
AuraCountFont = Font("IGAS_AuraCountFont")
AuraCountFont:CopyFontObject("NumberFontNormal")

--==========================
-- Elements
--==========================
class "iHealthBar"
	inherit "HealthBarFrequent"
	extend "iStatusBarStyle""iBorder"
	extend "IFTarget"

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function SetTargetState(self, isTarget)
		if isTarget then
			self.Back.BackdropBorderColor = Media.ACTIVED_BORDER_COLOR
		else
			self.Back.BackdropBorderColor = Media.DEFAULT_BORDER_COLOR
		end
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function iHealthBar(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.UseDebuffColor = true

		if _DBChar[GetSpecialization() or 1].ElementUseClassColor then
			self.UseClassColor = true
		end
		self.FrameLevel = self.FrameLevel + 1
	end
endclass "iHealthBar"

class "iNameLabel"
	inherit "FontString"
	extend "IFUnitName" "IFFaction" "IFThreat"

	local function OnHide(self)
		self.ThreatMarkLeft.Visible = false
		self.ThreatMarkRight.Visible = false
	end

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function SetUnitName(self, name)
		self:SetText(name)
	end

	function UpdateFaction(self)
		self:SetTextColor(self:GetFactionColor())
	end

	function SetThreatLevel(self, lvl)
		if lvl >= 2 and not UnitCanAttack("player", self.Unit) then
			self.ThreatMarkLeft.Visible = true
			self.ThreatMarkRight.Visible = true
		else
			self.ThreatMarkLeft.Visible = false
			self.ThreatMarkRight.Visible = false
		end
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function iNameLabel(self, ...)
		Super(self, ...)

		self.UseClassColor = true
		self.UseSelectionColor = false
		self.UseTapColor = false
		self.DrawLayer = "BORDER"
		self.JustifyV = "MIDDLE"
		self.JustifyH = "CENTER"

		self:SetWordWrap(true)

		self.OnHide = self.OnHide + OnHide

		-- Threat mark
		local threatMarkLeft = FontString("ThreatMarkLeft", self.Parent)
		threatMarkLeft.Visible = false
		threatMarkLeft:SetPoint("RIGHT", self, "LEFT")
		threatMarkLeft:SetTextColor(1, 0, 0)
		threatMarkLeft.Text = ">>"
		self.ThreatMarkLeft = threatMarkLeft

		local threatMarkRight = FontString("ThreatMarkRight", self.Parent)
		threatMarkRight.Visible = false
		threatMarkRight:SetPoint("LEFT", self, "RIGHT")
		threatMarkRight:SetTextColor(1, 0, 0)
		threatMarkRight.Text = "<<"
		self.ThreatMarkRight = threatMarkRight
	end
endclass "iNameLabel"

class "iBuffPanel"
	inherit "AuraPanel"

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function UpdateAuras(self)
		local unit = self.Unit

		if unit then
			if UnitCanAttack("player", unit) then
				self.Filter = "HELPFUL"
			else
				self.Filter = "HELPFUL|PLAYER"
			end
		end

		return Super.UpdateAuras(self)
	end

	function CustomFilter(self, unit, index, filter)
		if filter == "HELPFUL" then return true end

		local name, rank, texture, count, dtype, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitAura(unit, index, filter)

		if name and caster == "player" and ((count > 0 and duration > 0) or ((_Buff_List[spellID] or _IGASUI_HELPFUL_SPELL[spellID] or _IGASUI_HELPFUL_SPELL[name]) and duration > 0 and duration < 31)) then
			return true
		end
	end

	------------------------------------------------------
	-- Event Handler
	------------------------------------------------------
	local function OnElementAdd(self, element)
		element.ShowTooltip = _DBChar[GetSpecialization() or 1].ShowDebuffTooltip
		element:GetChild("Count").FontObject = AuraCountFont
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function iBuffPanel(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.Filter = "HELPFUL|PLAYER"
		self.ColumnCount = 3
		self.RowCount = 2
		self.ElementWidth = 16
		self.ElementHeight = 16
		self.Orientation = Orientation.VERTICAL

		self.OnElementAdd = self.OnElementAdd + OnElementAdd
    end
endclass "iBuffPanel"

class "iDebuffPanel"
	inherit "AuraPanel"

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	function UpdateAuras(self)
		local unit = self.Unit

		if unit then
			if UnitCanAttack("player", unit) then
				self.Filter = "HARMFUL|PLAYER"
			else
				self.Filter = "HARMFUL"
			end
		end

		return Super.UpdateAuras(self)
	end

	function CustomFilter(self, unit, index, filter)
		local name, rank, texture, count, dtype, duration, expires, caster, isStealable, shouldConsolidate, spellID = UnitAura(unit, index, filter)

		if filter ~= "HARMFUL" then return caster == "player" end

		if _DebuffBlackList[spellID] then return false end

		return true
	end

	------------------------------------------------------
	-- Event Handler
	------------------------------------------------------
	local function OnMouseUp(self, button)
		if button == "RightButton" and _DBChar[GetSpecialization() or 1].DebuffRightMouseRemove and not UnitCanAttack("player", self.Parent.Unit) then
			local name, _, _, _, _, _, _, _, _, _, spellID = UnitAura(self.Parent.Unit, self.Index, self.Parent.Filter)

			if name then
				_DebuffBlackList[spellID] = true

				return self.Parent:Refresh()
			end
		end
	end

	local function OnElementAdd(self, element)
		element.ShowTooltip = _DBChar[GetSpecialization() or 1].ShowDebuffTooltip
		element.MouseEnabled = _DBChar[GetSpecialization() or 1].ShowDebuffTooltip or _DBChar[GetSpecialization() or 1].DebuffRightMouseRemove
		element.OnMouseUp = element.OnMouseUp + OnMouseUp
	end

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function iDebuffPanel(self, name, parent, ...)
		Super(self, name, parent, ...)

		self.Filter = "HARMFUL"
		self.ColumnCount = 3
		self.RowCount = 2
		self.ElementWidth = 16
		self.ElementHeight = 16
		self.Orientation = Orientation.HORIZONTAL
		self.TopToBottom = false
		self.LeftToRight = false

		self.OnElementAdd = self.OnElementAdd + OnElementAdd
    end
endclass "iDebuffPanel"

