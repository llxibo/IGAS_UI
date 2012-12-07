-----------------------------------------
-- Definition for RaidPanel
-----------------------------------------

IGAS:NewAddon "IGAS_UI.RaidPanel"

import "System.Widget"
import "System.Widget.Unit"

_IGASUI_RAIDPANEL_GROUP = "IRaidPanel"
_IGASUI_SPELLHANDLER = IFSpellHandler._Group(_IGASUI_RAIDPANEL_GROUP)

-----------------------------------------------
--- iRaidUnitFrame
-- @type class
-- @name iRaidUnitFrame
-----------------------------------------------
class "iRaidUnitFrame"
	inherit "UnitFrame"
	extend "IFSpellHandler"

	_IGASUI_RAIDPANEL_GROUP = _IGASUI_RAIDPANEL_GROUP

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	property "IFSpellHandlerGroup" {
		Get = function(self)
			return _IGASUI_RAIDPANEL_GROUP
		end,
	}
endclass "iRaidUnitFrame"

-----------------------------------------------
--- BindingButton
-- @type class
-- @name BindingButton
-----------------------------------------------
class "BindingButton"
	inherit "Mask"

	BOOKTYPE_SPELL = _G.BOOKTYPE_SPELL

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
			_IGASUI_SPELLHANDLER.Spell(spellId, self.With).Key = key
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
		if oldkey then
			_IGASUI_SPELLHANDLER:Clear(oldkey)
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
			self.Visible = true
			local set = _IGASUI_SPELLHANDLER.Spell(spellId)
			self.BindKey, self.With = set.Key, set.With
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
    function BindingButton(name, parent)
		local mask = Super(name, parent)

		mask.AsKeyBind = true

		mask.OnEnter = mask.OnEnter + OnEnter
		mask.OnLeave = mask.OnLeave + OnLeave

		mask.OnKeySet = mask.OnKeySet + OnKeySet
		mask.OnKeyClear = mask.OnKeyClear + OnKeyClear

		return mask
    end
endclass "BindingButton"