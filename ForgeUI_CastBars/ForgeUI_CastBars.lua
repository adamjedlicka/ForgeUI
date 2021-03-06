require "Window"
 
-----------------------------------------------------------------------------------------------
-- ForgeUI_CastBars Module Definition
-----------------------------------------------------------------------------------------------
local ForgeUI_CastBars = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ForgeUI_CastBars:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- mandatory 
    self.api_version = 1
	self.version = "0.1.0"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_CastBars"
	self.strDisplayName = "Unit frames"
	
	self.wndContainers = {}
	
	-- optional
	self.settings_version = 1
	self.tSettings = {
		bSmoothBars = true,
		bCenterPlayerText = false,
		bCenterTargetText = false,
		crBorder = "FF000000",
		crBackground = "FF101010",
		crCastBar = "FF272727",
		crMooBar = "FFBC00BB",
		crDuration = "FFFFCC00",
		crText = "FFFFFFFF"
	}
	
	self.cast = nil

    return o
end

function ForgeUI_CastBars:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function ForgeUI_CastBars:ForgeAPI_AfterRegistration()
	local wnd = ForgeUI.AddItemButton(self, "Cast bars", "Container")
	
	self.wndPlayerCastBar = Apollo.LoadForm(self.xmlDoc, "PlayerCastBar", "FixedHudStratum", self)
	self.wndPlayerCastBar:Show(false, true)
	self.wndTargetCastBar = Apollo.LoadForm(self.xmlDoc, "TargetCastBar", "FixedHudStratum", self)
	self.wndTargetCastBar:Show(false, true)
	
	self.wndMovables = Apollo.LoadForm(self.xmlDoc, "Movables", nil, self) 
end

function ForgeUI_CastBars:OnNextFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end

	self:UpdateCastBar(unitPlayer, self.wndPlayerCastBar)
	
	local unitTarget = unitPlayer:GetTarget()
	if unitTarget ~= nil and unitTarget:IsValid() then
		self:UpdateCastBar(unitTarget, self.wndTargetCastBar)
		self:UpdateMoOBar(unitTarget, self.wndTargetCastBar)
		self:UpdateInterruptArmor(unitTarget, self.wndTargetCastBar)
	else	
		if self.wndTargetCastBar:IsShown() then
			self.wndTargetCastBar:Show(false, true)
		end
	end
	
	if self.cast ~= nil then
		local fTimeLeft = 1-GameLib.GetSpellThresholdTimePrcntDone(self.cast.id)
		self.wndPlayerCastBar:FindChild("DurationBar"):SetProgress(fTimeLeft)
	else
		self.wndPlayerCastBar:FindChild("DurationBar"):SetProgress(0)
	end
end

function ForgeUI_CastBars:OnStartSpellThreshold(idSpell, nMaxThresholds, eCastMethod)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local splObject = GameLib.GetSpell(idSpell)
	
	if self.cast == nil then
		self.cast = {}
		self.cast.id = idSpell
		self.cast.strSpellName = splObject:GetName()
		self.cast.nThreshold = 1
		self.cast.nMaxThreshold = nMaxThresholds
		
		self.wndPlayerCastBar:FindChild("SpellName"):SetText(self.cast.strSpellName)
		self.wndPlayerCastBar:FindChild("TickBar"):SetMax(nMaxThresholds)
		self.wndPlayerCastBar:FindChild("TickBar"):SetProgress(self.cast.nMaxThreshold - self.cast.nThreshold)
		self.wndPlayerCastBar:FindChild("CastTime"):SetText(self.cast.nThreshold)
		
		self.wndPlayerCastBar:Show(true, true)
	end
end

function ForgeUI_CastBars:OnUpdateSpellThreshold(idSpell, nNewThreshold)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local splObject = GameLib.GetSpell(idSpell)
	local strSpellName = splObject:GetName()
	
	self.cast.nThreshold = nNewThreshold
	
	self.wndPlayerCastBar:FindChild("SpellName"):SetText(strSpellName)
	self.wndPlayerCastBar:FindChild("TickBar"):SetProgress(self.cast.nMaxThreshold - nNewThreshold)
	
	self.wndPlayerCastBar:FindChild("TickBar"):SetProgress(self.cast.nMaxThreshold - nNewThreshold)
	
	self.wndPlayerCastBar:FindChild("CastTime"):SetText(nNewThreshold)
end

function ForgeUI_CastBars:OnClearSpellThreshold(idSpell)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	self.wndPlayerCastBar:Show(false, true)
	self.wndPlayerCastBar:FindChild("TickBar"):SetProgress(0)
	
	self.cast = nil
end

function ForgeUI_CastBars:UpdateCastBar(unit, wnd)
	if unit == nil or wnd == nil or unit:IsDead() then return end
	
	local fDuration
	local fElapsed
	local strSpellName
	local bShowCast = false
	local bShowTick = false
	
	if unit:ShouldShowCastBar() then
		bShowCast = true
		
		fDuration = unit:GetCastDuration()
		fElapsed = unit:GetCastElapsed()	
		strSpellName = unit:GetCastName()
		
		wnd:FindChild("SpellName"):SetText(strSpellName)
		wnd:FindChild("CastBar"):SetMax(fDuration)
		wnd:FindChild("CastBar"):SetProgress(fElapsed)
		wnd:FindChild("CastTime"):SetText(string.format("%00.01f", (fDuration - fElapsed)/1000) .. "s")
	elseif wnd:GetName() ==  "PlayerCastBar" and self.cast ~= nil then
		wnd:FindChild("SpellName"):SetText(self.cast.strSpellName)
		wnd:FindChild("CastTime"):SetText(self.cast.nThreshold)
		
		local fTimeLeft = 1-GameLib.GetSpellThresholdTimePrcntDone(self.cast.id)
		self.wndPlayerCastBar:FindChild("DurationBar"):SetProgress(fTimeLeft)
		
		bShowTick = true
	end
	
	if bShowCast or bShowTick  ~= wnd:IsShown() then
		wnd:Show(bShowCast or bShowTick, true)
	end
	
	if bShowCast ~= wnd:FindChild("Cast"):IsShown() then
		wnd:FindChild("Cast"):Show(bShowCast, true)
	end
	
	if bShowTick ~= wnd:FindChild("Tick"):IsShown() then
		wnd:FindChild("Tick"):Show(bShowTick, true)
	end
end

local maxTime = 0
function ForgeUI_CastBars:UpdateMoOBar(unit, wnd)
	if unit == nil or wnd == nil or unit:IsDead() then return end
	
	local time = unit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
	local pl = GameLib.GetPlayerUnit()
	
	if time > 0 then
		maxTime = time > maxTime and time or maxTime
	
		wnd:FindChild("MoOBar"):SetMax(maxTime)
		wnd:FindChild("MoOBar"):SetProgress(time)
		
		wnd:FindChild("SpellName"):SetText("MoO")
		wnd:FindChild("CastTime"):SetText(ForgeUI.Round(time, 1))
		
		if not wnd:IsShown() then
			wnd:Show(true, true)
		end
	else
		wnd:FindChild("MoOBar"):SetProgress(0)
		maxTime = 0
	end
end

function ForgeUI_CastBars:UpdateInterruptArmor(unit, wnd)
	local bShow = false
	nValue = unit:GetInterruptArmorValue()
	nMax = unit:GetInterruptArmorMax()
	if nMax == 0 or nValue == nil or unit:IsDead() then
	else
		bShow = true
		if nMax == -1 then
			wnd:FindChild("InterruptArmor"):SetSprite("ForgeUI_IAinf")
			wnd:FindChild("InterruptArmor_Value"):SetText("")
		elseif nMax > 0 then
			wnd:FindChild("InterruptArmor"):SetSprite("ForgeUI_IA")
			wnd:FindChild("InterruptArmor_Value"):SetText(nValue)
		end
	end
	
	if bShow ~= wnd:FindChild("InterruptArmor"):IsShown() then
		wnd:FindChild("InterruptArmor"):Show(bShow, true)
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_CastBars OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI_CastBars:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_CastBars.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_CastBars OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_CastBars:OnDocLoaded()
	if self.xmlDoc == nil or self.xmlDoc:IsLoaded() == false then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
end

function ForgeUI_CastBars:UpdateStyles()
	self.wndPlayerCastBar:FindChild("Border"):SetBGColor(self.tSettings.crBorder)
	self.wndPlayerCastBar:FindChild("Background"):SetBGColor(self.tSettings.crBackground)
	self.wndPlayerCastBar:FindChild("CastBar"):SetBarColor(self.tSettings.crCastBar)
	self.wndPlayerCastBar:FindChild("TickBar"):SetBarColor(self.tSettings.crCastBar)
	self.wndPlayerCastBar:FindChild("DurationBar"):SetBarColor(self.tSettings.crDuration)
	self.wndPlayerCastBar:FindChild("CastTime"):SetTextColor(self.tSettings.crText)
	self.wndPlayerCastBar:FindChild("SpellName"):SetTextColor(self.tSettings.crText)
	
	self.wndTargetCastBar:FindChild("Border"):SetBGColor(self.tSettings.crBorder)
	self.wndTargetCastBar:FindChild("Background"):SetBGColor(self.tSettings.crBackground)
	self.wndTargetCastBar:FindChild("CastBar"):SetBarColor(self.tSettings.crCastBar)
	self.wndTargetCastBar:FindChild("MoOBar"):SetBarColor(self.tSettings.crMooBar)
	self.wndTargetCastBar:FindChild("CastTime"):SetTextColor(self.tSettings.crText)
	self.wndTargetCastBar:FindChild("SpellName"):SetTextColor(self.tSettings.crText)
	
	if self.tSettings.bCenterTargetText then
		self.wndTargetCastBar:FindChild("SpellName"):SetAnchorOffsets(10, 0, 0, 0)
		self.wndTargetCastBar:FindChild("SpellName"):SetAnchorPoints(0, 0, 1, 1)
		
		self.wndTargetCastBar:FindChild("CastTime"):SetAnchorOffsets(0, 0, -10, 0)
		self.wndTargetCastBar:FindChild("CastTime"):SetAnchorPoints(0, 0, 1, 1)
	else
		self.wndTargetCastBar:FindChild("SpellName"):SetAnchorOffsets(10, -10, 0, 15)
		self.wndTargetCastBar:FindChild("SpellName"):SetAnchorPoints(0, 0, 1, 0)
		
		self.wndTargetCastBar:FindChild("CastTime"):SetAnchorOffsets(0, -10, -10, 15)
		self.wndTargetCastBar:FindChild("CastTime"):SetAnchorPoints(0, 0, 1, 0)
	end
	
	if self.tSettings.bCenterPlayerText then
		self.wndPlayerCastBar:FindChild("SpellName"):SetAnchorOffsets(10, 0, 0, 0)
		self.wndPlayerCastBar:FindChild("SpellName"):SetAnchorPoints(0, 0, 1, 1)
		
		self.wndPlayerCastBar:FindChild("CastTime"):SetAnchorOffsets(0, 0, -10, 0)
		self.wndPlayerCastBar:FindChild("CastTime"):SetAnchorPoints(0, 0, 1, 1)
	else
		self.wndPlayerCastBar:FindChild("SpellName"):SetAnchorOffsets(10, -10, 0, 15)
		self.wndPlayerCastBar:FindChild("SpellName"):SetAnchorPoints(0, 0, 1, 0)
		
		self.wndPlayerCastBar:FindChild("CastTime"):SetAnchorOffsets(0, -10, -10, 15)
		self.wndPlayerCastBar:FindChild("CastTime"):SetAnchorPoints(0, 0, 1, 0)
	end
end

function ForgeUI_CastBars:ForgeAPI_AfterRestore()
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerCastBar, "ForgeUI_CastBars_PlayerCastBar", self.wndMovables:FindChild("Movable_PlayerCastBar"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetCastBar, "ForgeUI_CastBars_TargetCastBar", self.wndMovables:FindChild("Movable_TargetCastBar"))
	
	if self.tSettings.bSmoothBars == true then
		Apollo.RegisterEventHandler("NextFrame", 	"OnNextFrame", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", 	"OnNextFrame", self)
	end
	Apollo.RegisterEventHandler("StartSpellThreshold", 	"OnStartSpellThreshold", self)
	Apollo.RegisterEventHandler("ClearSpellThreshold", 	"OnClearSpellThreshold", self)
	Apollo.RegisterEventHandler("UpdateSpellThreshold", "OnUpdateSpellThreshold", self)
	
	self:UpdateStyles()
end

---------------------------------------------------------------------------------------------------
-- Movables Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_CastBars:OnWindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndPlayerCastBar:SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerCastBar"):GetAnchorOffsets())
	self.wndTargetCastBar:SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetCastBar"):GetAnchorOffsets())
end

---------------------------------------------------------------------------------------------------
-- Container Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_CastBars:ForgeAPI_LoadOptions()
	local wndContainer = self.wndContainers.Container
	
	wndContainer:FindChild("bSmoothBars"):SetCheck(self.tSettings.bSmoothBars)
	wndContainer:FindChild("bCenterPlayerText"):SetCheck(self.tSettings.bCenterPlayerText)
	wndContainer:FindChild("bCenterTargetText"):SetCheck(self.tSettings.bCenterTargetText)
	
	ForgeUI.ColorBoxChange(self, wndContainer:FindChild("crBorder"), self.tSettings, "crBorder", true)
	ForgeUI.ColorBoxChange(self, wndContainer:FindChild("crBackground"), self.tSettings, "crBackground", true)
	ForgeUI.ColorBoxChange(self, wndContainer:FindChild("crCastBar"), self.tSettings, "crCastBar", true)
	ForgeUI.ColorBoxChange(self, wndContainer:FindChild("crMooBar"), self.tSettings, "crMooBar", true)
	ForgeUI.ColorBoxChange(self, wndContainer:FindChild("crDuration"), self.tSettings, "crDuration", true)
	ForgeUI.ColorBoxChange(self, wndContainer:FindChild("crText"), self.tSettings, "crText", true)
end

function ForgeUI_CastBars:OnOptionsChanged( wndHandler, wndControl )
	local strType = wndControl:GetParent():GetName()
	
	if strType == "CheckBox" then
		self.tSettings[wndControl:GetName()] = wndControl:IsChecked()
	end
	
	if strType == "ColorBox" then
		ForgeUI.ColorBoxChange(self, wndControl, self.tSettings, wndControl:GetName())
	end
	
	self:UpdateStyles()
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_CastBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_CastBarsInst = ForgeUI_CastBars:new()
ForgeUI_CastBarsInst:Init()
