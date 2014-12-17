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
	self.version = "0.0.1"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_CastBars"
	self.strDisplayName = "Unit frames"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		smoothBars = true,
		backgroundColor = "101010",
		castBarColor = "272727",
		durationBarColor = "FFCC00"
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
	local wnd = ForgeUI.AddItemButton(self, "Cast bars")
	
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
	else
		self.wndTargetCastBar:Show(false, true)
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
	
	if unit:ShouldShowCastBar() then
		fDuration = unit:GetCastDuration()
		fElapsed = unit:GetCastElapsed()	
		strSpellName = unit:GetCastName()
		
		wnd:FindChild("SpellName"):SetText(strSpellName)
		wnd:FindChild("CastBar"):SetMax(fDuration)
		wnd:FindChild("CastBar"):SetProgress(fElapsed)
		wnd:FindChild("CastTime"):SetText(string.format("%00.01f", (fDuration - fElapsed)/1000) .. "s")
		
		wnd:Show(true, true)
	elseif self.cast == nil then
		wnd:Show(false, true)
		wnd:FindChild("CastBar"):SetProgress(0)
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

function ForgeUI_CastBars:ForgeAPI_AfterRestore()
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerCastBar, "ForgeUI_CastBars_PlayerCastBar", self.wndMovables:FindChild("Movable_PlayerCastBar"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetCastBar, "ForgeUI_CastBars_TargetCastBar", self.wndMovables:FindChild("Movable_TargetCastBar"))

	self.wndPlayerCastBar:FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
	self.wndPlayerCastBar:FindChild("CastBar"):SetBarColor("FF" .. self.tSettings.castBarColor)
	self.wndPlayerCastBar:FindChild("TickBar"):SetBarColor("FF" .. self.tSettings.castBarColor)
	self.wndPlayerCastBar:FindChild("DurationBar"):SetBarColor("FF" .. self.tSettings.durationBarColor)
	
	self.wndTargetCastBar:FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
	self.wndTargetCastBar:FindChild("CastBar"):SetBarColor("FF" .. self.tSettings.castBarColor)
	
	if self.tSettings.smoothBars == true then
		Apollo.RegisterEventHandler("NextFrame", 	"OnNextFrame", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", 	"OnNextFrame", self)
	end
	Apollo.RegisterEventHandler("StartSpellThreshold", 	"OnStartSpellThreshold", self)
	Apollo.RegisterEventHandler("ClearSpellThreshold", 	"OnClearSpellThreshold", self)
	Apollo.RegisterEventHandler("UpdateSpellThreshold", "OnUpdateSpellThreshold", self)
end

---------------------------------------------------------------------------------------------------
-- Movables Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_CastBars:OnWindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndPlayerCastBar:SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerCastBar"):GetAnchorOffsets())
	self.wndTargetCastBar:SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetCastBar"):GetAnchorOffsets())
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_CastBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_CastBarsInst = ForgeUI_CastBars:new()
ForgeUI_CastBarsInst:Init()
