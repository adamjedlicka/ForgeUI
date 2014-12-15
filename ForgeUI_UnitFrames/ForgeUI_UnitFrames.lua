require "Window"
 
-----------------------------------------------------------------------------------------------
-- ForgeUI_UnitFrames Module Definition
-----------------------------------------------------------------------------------------------
local ForgeUI = nil
local ForgeUI_UnitFrames = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

tClassEnums = {
	[GameLib.CodeEnumClass.Warrior]      	= "warrior",
	[GameLib.CodeEnumClass.Engineer]     	= "engineer",
	[GameLib.CodeEnumClass.Esper]        	= "esper",
	[GameLib.CodeEnumClass.Medic]        	= "medic",
	[GameLib.CodeEnumClass.Stalker]      	= "stalker",
	[GameLib.CodeEnumClass.Spellslinger]	= "spellslinger"
} 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ForgeUI_UnitFrames:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- mandatory 
    self.api_version = 1
	self.version = "0.0.1"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_UnitFrames"
	self.strDisplayName = "Unit frames"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		backgroundBarColor = "131313",
		hpBarColor = "272727",
		hpTextColor = "75cc26",
		shieldBarColor = "0699f3",
		absorbBarColor = "ffc600"
	}
	
	self.unitPlayer = nil
	self.playerClass = nil

    return o
end

function ForgeUI_UnitFrames:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ForgeUI_UnitFrames OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI_UnitFrames:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_UnitFrames.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ForgeUI_UnitFrames:ForgeAPI_AfterRegistration()
	local wnd = ForgeUI.AddItemButton(self, "Unit frames")
	--ForgeUI.AddItemListToButton(self, wnd, {
	--	{ strDisplayName = "General", strContainer = "Container" },
	--	{ strDisplayName = "Player frame", strContainer = "Container_PlayerFrame" },
	--	{ strDisplayName = "Target frame", strContainer = "Container_TargetFrame" }
	--}) 
	
	self.wndPlayerFrame = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PlayerFrame", nil, self)
	self.wndTargetFrame = Apollo.LoadForm(self.xmlDoc, "ForgeUI_TargetFrame", nil, self)
end

-----------------------------------------------------------------------------------------------
-- On next frame
-----------------------------------------------------------------------------------------------

function ForgeUI_UnitFrames:OnNextFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	self:UpdatePlayerFrame(unitPlayer)
	
	self:UpdateTargetFrame(unitPlayer)
	
end

function ForgeUI_UnitFrames:UpdatePlayerFrame(unit)
	self:UpdateHPBar(unit, self.wndPlayerFrame)
	self:UpdateShieldBar(unit, self.wndPlayerFrame)
	self:UpdateAbsorbBar(unit, self.wndPlayerFrame)
	
	self.wndPlayerFrame:SetData(unit)
	
	if unit:IsInCombat() then
		self.wndPlayerFrame:FindChild("Indicator"):Show(true)
	else
		self.wndPlayerFrame:FindChild("Indicator"):Show(false)
	end
end

function ForgeUI_UnitFrames:UpdateTargetFrame(unitSource)
	local unit = unitSource:GetTarget()

	if unit == nil then 
		self.wndTargetFrame:Show(false)
		return
	end

	self.wndTargetFrame:FindChild("Name"):SetText(unit:GetName())
	if unit:GetClassId() ~= 23 then
		self.wndTargetFrame:FindChild("Name"):SetTextColor("ff" .. ForgeUI.GetSettings().classColors[tClassEnums[unit:GetClassId()]])
	else
		self.wndTargetFrame:FindChild("Name"):SetTextColor(unit:GetNameplateColor())
	end
	
	self:UpdateHPBar(unit, self.wndTargetFrame)
	self:UpdateShieldBar(unit, self.wndTargetFrame)
	self:UpdateAbsorbBar(unit, self.wndTargetFrame)
	
	self.wndTargetFrame:SetData(unit)
	
	self.wndTargetFrame:Show(true)
end

function ForgeUI_UnitFrames:UpdateHPBar(unit, wnd)
	wnd:FindChild("HP_ProgressBar"):SetMax(unit:GetMaxHealth())
	wnd:FindChild("HP_ProgressBar"):SetProgress(unit:GetHealth())
	wnd:FindChild("HP_TextValue"):SetText(ForgeUI.ShortNum(unit:GetHealth()))
	wnd:FindChild("HP_TextPercent"):SetText(math.floor((unit:GetHealth() / unit:GetMaxHealth()) * 100  + 0.5) .. "%")
end

function ForgeUI_UnitFrames:UpdateShieldBar(unit, wnd)
	if unit:GetShieldCapacity() == 0 then
		wnd:FindChild("ShieldBar"):Show(false)
	else
		wnd:FindChild("ShieldBar"):Show(true)
		wnd:FindChild("Shield_ProgressBar"):SetMax(unit:GetShieldCapacityMax())
		wnd:FindChild("Shield_ProgressBar"):SetProgress(unit:GetShieldCapacity())
		wnd:FindChild("Shield_TextValue"):SetText(ForgeUI.ShortNum(unit:GetShieldCapacity()))
	end
end

function ForgeUI_UnitFrames:UpdateAbsorbBar(unit, wnd)
	if unit:GetAbsorptionValue() == 0 then
		wnd:FindChild("AbsorbBar"):Show(false)
	else
		wnd:FindChild("AbsorbBar"):Show(true)
		wnd:FindChild("Absorb_ProgressBar"):SetMax(unit:GetAbsorptionMax())
		wnd:FindChild("Absorb_ProgressBar"):SetProgress(unit:GetAbsorptionValue())
		wnd:FindChild("Absorb_TextValue"):SetText(ForgeUI.ShortNum(unit:GetAbsorptionValue()))
	end
end

-----------------------------------------------------------------------------------------------
-- On character created
-----------------------------------------------------------------------------------------------

function ForgeUI_UnitFrames:OnCharacterCreated()
	self.unitPlayer = GameLib.GetPlayerUnit()
	if self.unitPlayer == nil then
		Print("ForgeUI ERROR: Wrong class")
		return
	end
	
	local eClassId = self.unitPlayer:GetClassId()
	if eClassId == GameLib.CodeEnumClass.Engineer then
		self.playerClass = "engineer"
	elseif eClassId == GameLib.CodeEnumClass.Esper then
		self.playerClass = "esper"
	elseif eClassId == GameLib.CodeEnumClass.Medic then
		self.playerClass = "medic"
	elseif eClassId == GameLib.CodeEnumClass.Spellslinger then
		self.playerClass = "spellslinger"
	elseif eClassId == GameLib.CodeEnumClass.Stalker then
		self.playerClass = "stalker"
	elseif eClassId == GameLib.CodeEnumClass.Warrior then
		self.playerClass = "warrior"
	end
	
	Print(self.playerClass)
	
	self.wndPlayerFrame:FindChild("Name"):SetText(self.unitPlayer:GetName())
	self.wndPlayerFrame:FindChild("Name"):SetTextColor("FF" .. ForgeUI.GetSettings().classColors[self.playerClass])
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnNextFrame", self) 
end

function ForgeUI_UnitFrames:ForgeAPI_AfterRestore()
	self.wndPlayerFrame:FindChild("Background"):SetBGColor("ff" .. self.tSettings.backgroundBarColor)
	self.wndPlayerFrame:FindChild("HP_ProgressBar"):SetBarColor("ff" .. self.tSettings.hpBarColor)
	self.wndPlayerFrame:FindChild("Shield_ProgressBar"):SetBarColor("ff" .. self.tSettings.shieldBarColor)
	self.wndPlayerFrame:FindChild("Absorb_ProgressBar"):SetBarColor("ff" .. self.tSettings.absorbBarColor)	
	self.wndPlayerFrame:FindChild("HP_TextValue"):SetTextColor("ff" .. self.tSettings.hpTextColor)
	self.wndPlayerFrame:FindChild("HP_TextPercent"):SetTextColor("ff" .. self.tSettings.hpTextColor)
	
	self.wndTargetFrame:FindChild("Background"):SetBGColor("ff" .. self.tSettings.backgroundBarColor)
	self.wndTargetFrame:FindChild("HP_ProgressBar"):SetBarColor("ff" .. self.tSettings.hpBarColor)
	self.wndTargetFrame:FindChild("Shield_ProgressBar"):SetBarColor("ff" .. self.tSettings.shieldBarColor)
	self.wndTargetFrame:FindChild("Absorb_ProgressBar"):SetBarColor("ff" .. self.tSettings.absorbBarColor)	
	self.wndTargetFrame:FindChild("HP_TextValue"):SetTextColor("ff" .. self.tSettings.hpTextColor)
	self.wndTargetFrame:FindChild("HP_TextPercent"):SetTextColor("ff" .. self.tSettings.hpTextColor)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_UnitFrames OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_UnitFrames:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return false end
	 
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	else
		Apollo.RegisterEventHandler("CharacterCreated", 	"OnCharacterCreated", self)
	end 
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_PlayerFrame Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_UnitFrames:OnMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local unit = wndHandler:GetData()
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and unit ~= nil then
		GameLib.SetTargetUnit(unit)
		return false
	end
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and unit ~= nil then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", nil, unit:GetName(), unit)
		return true
	end
	
	return false
end

local ForgeUI_UnitFramesInst = ForgeUI_UnitFrames:new()
ForgeUI_UnitFramesInst:Init()
