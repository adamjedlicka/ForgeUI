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

tEngineerStances = {
	[0] = "",
	[1] = Apollo.GetString("EngineerResource_Aggro"),
	[2] = Apollo.GetString("EngineerResource_Defend"),
	[3] = Apollo.GetString("EngineerResource_Passive"),
	[4] = Apollo.GetString("EngineerResource_Assist"),
	[5] = Apollo.GetString("EngineerResource_Stay"),
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
	self.version = "0.1.0"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_UnitFrames"
	self.strDisplayName = "Unit frames"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		backgroundColor = "131313",
		backgroundBarColor = "101010",
		hpBarColor = "272727",
		hpTextColor = "75CC26",
		shieldBarColor = "0699F3",
		absorbBarColor = "FFC600"
	}
	
	self.playerClass = nil
	self.tWndPets = {}

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
	--local wnd = ForgeUI.AddItemButton(self, "Unit frames")
	--ForgeUI.AddItemListToButton(self, wnd, {
	--	{ strDisplayName = "General", strContainer = "Container" },
	--	{ strDisplayName = "Player frame", strContainer = "Container_PlayerFrame" },
	--	{ strDisplayName = "Target frame", strContainer = "Container_TargetFrame" }
	--}) 
	
	self.wndPlayerFrame = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PlayerFrame", "FixedHudStratumLow", self)
	self.wndPlayerBuffFrame = Apollo.LoadForm(self.xmlDoc, "PlayerBuffContainerWindow", "FixedHudStratumHigh", self)
	self.wndPlayerDebuffFrame = Apollo.LoadForm(self.xmlDoc, "PlayerDebuffContainerWindow", "FixedHudStratumHigh", self)
	
	self.wndTargetFrame = Apollo.LoadForm(self.xmlDoc, "ForgeUI_TargetFrame", "FixedHudStratumLow", self)
	self.wndTargetBuffFrame = Apollo.LoadForm(self.xmlDoc, "TargetBuffContainerWindow", "FixedHudStratumHigh", self)
	self.wndTargetDebuffFrame = Apollo.LoadForm(self.xmlDoc, "TargetDebuffContainerWindow", "FixedHudStratumHigh", self)
	
	self.wndToTFrame = Apollo.LoadForm(self.xmlDoc, "ForgeUI_ToTFrame", "FixedHudStratumLow", self)
	self.wndFocusFrame = Apollo.LoadForm(self.xmlDoc, "ForgeUI_FocusFrame", "FixedHudStratumLow", self)
	
	self.wndHazardBreath = Apollo.LoadForm(self.xmlDoc, "ForgeUI_HazardBreath", "FixedHudStratumLow", self)
	self.wndHazardHeat = Apollo.LoadForm(self.xmlDoc, "ForgeUI_HazardHeat", "FixedHudStratumLow", self)
	self.wndHazardToxic = Apollo.LoadForm(self.xmlDoc, "ForgeUI_HazardToxic", "FixedHudStratumLow", self)
	
	self.wndMovables = Apollo.LoadForm(self.xmlDoc, "Movables", nil, self)
	
	self.tWndPets[0] = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PetFrame", "FixedHudStratumLow", self)
	self.tWndPets[1] = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PetFrame", "FixedHudStratumLow", self)
	self.tWndPets[1]:SetAnchorOffsets(95, 100, 225, 120)
end

-----------------------------------------------------------------------------------------------
-- On next frame
-----------------------------------------------------------------------------------------------

function ForgeUI_UnitFrames:OnNextFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	self:UpdatePlayerFrame(unitPlayer)
	self:UpdateHazards(unitPlayer)
	
	if self.playerClass == "engineer" then
		self:UpdatePetFrames(unitPlayer)
	end
end

-- Player Frame
function ForgeUI_UnitFrames:UpdatePlayerFrame(unit)
	if unit:IsInCombat() then
		self.wndPlayerFrame:FindChild("Indicator"):Show(true)
	else
		self.wndPlayerFrame:FindChild("Indicator"):Show(false)
	end
	
	self.wndPlayerFrame:FindChild("Name"):SetText(unit:GetName())
	self.wndPlayerFrame:FindChild("Name"):SetTextColor("FF" .. ForgeUI.GetSettings().classColors[self.playerClass])
	
	self:UpdateHPBar(unit, self.wndPlayerFrame)
	self:UpdateShieldBar(unit, self.wndPlayerFrame)
	self:UpdateAbsorbBar(unit, self.wndPlayerFrame)
	self:UpdateInterruptArmor(unit, self.wndPlayerFrame)
	
	self.wndPlayerFrame:SetData(unit)
	
	self.wndPlayerBuffFrame:SetUnit(unit)
	self.wndPlayerDebuffFrame:SetUnit(unit)
		
	self:UpdateTargetFrame(unit)
	self:UpdateFocusFrame(unit)
end

-- Target Frame
function ForgeUI_UnitFrames:UpdateTargetFrame(unitSource)
	local unit = unitSource:GetTarget()

	if unit == nil then 
		self.wndTargetFrame:Show(false, true)
		self.wndToTFrame:Show(false, true)
		self.wndTargetBuffFrame:SetUnit(nil)
		self.wndTargetDebuffFrame:SetUnit(nil)
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
	self:UpdateInterruptArmor(unit, self.wndTargetFrame)
	
	self.wndTargetBuffFrame:SetUnit(unit)
	self.wndTargetDebuffFrame:SetUnit(unit)
	self.wndTargetFrame:SetData(unit)
	self.wndTargetBuffFrame:Show(true, true)
	self.wndTargetDebuffFrame:Show(true, true)
	self.wndTargetFrame:Show(true, true)
	
	self:UpdateToTFrame(unit)
end

-- ToT Frame
function ForgeUI_UnitFrames:UpdateToTFrame(unitSource)
	local unit = unitSource:GetTarget()
	
	if unit == nil then 
		self.wndToTFrame:Show(false)
		return
	end
	
	self.wndToTFrame:FindChild("Name"):SetText(unit:GetName())
	if unit:GetClassId() ~= 23 then
		self.wndToTFrame:FindChild("Name"):SetTextColor("ff" .. ForgeUI.GetSettings().classColors[tClassEnums[unit:GetClassId()]])
	else
		self.wndToTFrame:FindChild("Name"):SetTextColor(unit:GetNameplateColor())
	end
	
	self:UpdateHPBar(unit, self.wndToTFrame)
	self.wndToTFrame:SetData(unit)
	self.wndToTFrame:Show(true)
end

-- Focus Frame
function ForgeUI_UnitFrames:UpdateFocusFrame(unitSource)
	local unit = unitSource:GetAlternateTarget()
	
	if unit == nil then 
		self.wndFocusFrame:Show(false)
		return
	end
	
	self.wndFocusFrame:FindChild("Name"):SetText(unit:GetName())
	if unit:GetClassId() ~= 23 then
		self.wndFocusFrame:FindChild("Name"):SetTextColor("ff" .. ForgeUI.GetSettings().classColors[tClassEnums[unit:GetClassId()]])
	else
		self.wndFocusFrame:FindChild("Name"):SetTextColor(unit:GetNameplateColor())
	end
	
	self:UpdateHPBar(unit, self.wndFocusFrame)
	self.wndFocusFrame:SetData(unit)
	self.wndFocusFrame:Show(true)
end

-- Pet Frames
function ForgeUI_UnitFrames:UpdatePetFrames(unitPlayer)
	tPets = GameLib.GetPlayerPets()
	
	if #tPets == 0 then
		self.wndPetControl:Show(false, true)
	end
	
	for _, petFrame in pairs(self.tWndPets) do
		petFrame:Show(false, true)
	end
	
	for i, pet in pairs(tPets) do
		local petFrame = self.tWndPets[i - 1]
		
		petFrame:FindChild("Name"):SetText(pet:GetName())
		self:UpdateHPBar(pet, petFrame)	
		self:UpdateShieldBar(pet, petFrame)
		
		petFrame:SetData(pet)
		petFrame:Show(true, true)
	end
	--Print(#tPets)
end

-- hp bar
function ForgeUI_UnitFrames:UpdateHPBar(unit, wnd)
	if unit:GetHealth() ~= nil then
		wnd:FindChild("Background"):Show(true)
		wnd:FindChild("HP_ProgressBar"):SetMax(unit:GetMaxHealth())
		wnd:FindChild("HP_ProgressBar"):SetProgress(unit:GetHealth())
		if wnd:FindChild("HP_TextValue") ~= nil then
			wnd:FindChild("HP_TextValue"):SetText(ForgeUI.ShortNum(unit:GetHealth()))
			wnd:FindChild("HP_TextPercent"):SetText(ForgeUI.Round((unit:GetHealth() / unit:GetMaxHealth()) * 100, 1) .. "%")
		end
	else
		wnd:FindChild("Background"):Show(false)
		wnd:FindChild("HP_ProgressBar"):SetProgress(0)
		if wnd:FindChild("HP_TextValue") ~= nil then
			wnd:FindChild("HP_TextValue"):SetText("")
			wnd:FindChild("HP_TextPercent"):SetText("")
		end
	end
end

-- shield bar
function ForgeUI_UnitFrames:UpdateShieldBar(unit, wnd)
	if unit:GetHealth() ~= nil then
		if unit:GetShieldCapacity() == 0 or unit:IsDead() then
			wnd:FindChild("ShieldBar"):Show(false)
		else
			wnd:FindChild("ShieldBar"):Show(true)
			wnd:FindChild("Shield_ProgressBar"):SetMax(unit:GetShieldCapacityMax())
			wnd:FindChild("Shield_ProgressBar"):SetProgress(unit:GetShieldCapacity())
			wnd:FindChild("Shield_TextValue"):SetText(ForgeUI.ShortNum(unit:GetShieldCapacity()))
		end
	else
		wnd:FindChild("ShieldBar"):Show(false)
	end
end

-- absorb bar
function ForgeUI_UnitFrames:UpdateAbsorbBar(unit, wnd)
	if unit:GetHealth() ~= nil then
		if unit:GetAbsorptionValue() == 0 or unit:IsDead() then
			wnd:FindChild("AbsorbBar"):Show(false)
		else
			wnd:FindChild("AbsorbBar"):Show(true)
			wnd:FindChild("Absorb_ProgressBar"):SetMax(unit:GetAbsorptionMax())
			wnd:FindChild("Absorb_ProgressBar"):SetProgress(unit:GetAbsorptionValue())
			wnd:FindChild("Absorb_TextValue"):SetText(ForgeUI.ShortNum(unit:GetAbsorptionValue()))
		end
	else
		wnd:FindChild("AbsorbBar"):Show(false)
	end
end

-- interrupt armor
function ForgeUI_UnitFrames:UpdateInterruptArmor(unit, wnd)
	--sprites: HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Value HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Infinite
	nValue = unit:GetInterruptArmorValue()
	nMax = unit:GetInterruptArmorMax()
	if nMax == 0 or nValue == nil or unit:IsDead() then
		wnd:FindChild("InterruptArmor"):Show(false, true)
	else
		wnd:FindChild("InterruptArmor"):Show(true, true)
		if nMax == -1 then
			wnd:FindChild("InterruptArmor"):SetSprite("HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Infinite")
			wnd:FindChild("InterruptArmor_Value"):SetText("")
		elseif nMax > 0 then
			wnd:FindChild("InterruptArmor"):SetSprite("HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Value")
			wnd:FindChild("InterruptArmor_Value"):SetText(nValue)
		end
	end
end

-- uodate hazard bars
function ForgeUI_UnitFrames:UpdateHazards(unit)
	self.wndHazardHeat:Show(false)
	self.wndHazardToxic:Show(false)

	for idx, tActiveHazard in ipairs(HazardsLib.GetHazardActiveList()) do
		if tActiveHazard.eHazardType == HazardsLib.HazardType_Radiation then
			self.wndHazardToxic:Show(true)
			self.wndHazardToxic:FindChild("ProgressBar"):SetMax(tActiveHazard.fMaxValue)
			self.wndHazardToxic:FindChild("ProgressBar"):SetProgress(tActiveHazard.fMeterValue)
			self.wndHazardHeat:FindChild("Text"):SetText("Radiation - " .. ForgeUI.Round((tActiveHazard.fMeterValue / tActiveHazard.fMaxValue * 100), 0))
		end
		if tActiveHazard.eHazardType == HazardsLib.HazardType_Temperature then
			self.wndHazardHeat:Show(true)
			self.wndHazardHeat:FindChild("ProgressBar"):SetMax(tActiveHazard.fMaxValue)
			self.wndHazardHeat:FindChild("ProgressBar"):SetProgress(tActiveHazard.fMeterValue)
			self.wndHazardHeat:FindChild("Text"):SetText("Heat - " .. ForgeUI.Round((tActiveHazard.fMeterValue / tActiveHazard.fMaxValue * 100), 0))
		end
	end
end

function ForgeUI_UnitFrames:OnBreathChanged(nBreath)
	if nBreath == 100 then
		self.wndHazardBreath:Show(false)
	else
		self.wndHazardBreath:Show(true)
		self.wndHazardBreath:FindChild("ProgressBar"):SetMax(100)
		self.wndHazardBreath:FindChild("ProgressBar"):SetProgress(nBreath)
	end
end

-----------------------------------------------------------------------------------------------
-- On character created
-----------------------------------------------------------------------------------------------

function ForgeUI_UnitFrames:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		Print("ForgeUI ERROR: Wrong class")
		return
	end
	
	local eClassId = unitPlayer:GetClassId()
	if eClassId == GameLib.CodeEnumClass.Engineer then
		self.playerClass = "engineer"
		
		self.wndPetControl = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PetControl", "FixedHudStratumLow", self)
		self.wndPetControl:FindChild("Text"):SetText(tEngineerStances[Pet_GetStance(0)])
		self.wndPetControl:Show(true, true)
		
		ForgeUI.RegisterWindowPosition(self, self.wndPetControl, "ForgeUI_UnitFrames_PetControl", self.wndMovables:FindChild("Movable_PetControl"))
		
		Apollo.RegisterEventHandler("PetStanceChanged", 			"OnPetStanceChanged", self)
		Apollo.RegisterEventHandler("PetSpawned",					"OnPetSpawned", self)
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
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", 	"OnNextFrame", self)
	Apollo.RegisterEventHandler("BreathChanged",			"OnBreathChanged", self)
end

function ForgeUI_UnitFrames:ForgeAPI_AfterRestore()
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerFrame, "ForgeUI_UnitFrames_PlayerFrame", self.wndMovables:FindChild("Movable_PlayerFrame"))
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerFrame:FindChild("ShieldBar"), "ForgeUI_UnitFrames_PlayerFrame_ShieldBar", self.wndMovables:FindChild("Movable_PlayerFrame_ShieldBar"))
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerFrame:FindChild("AbsorbBar"), "ForgeUI_UnitFrames_PlayerFrame_AbsorbBar", self.wndMovables:FindChild("Movable_PlayerFrame_AbsorbBar"))
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerFrame:FindChild("InterruptArmor"), "ForgeUI_UnitFrames_PlayerFrame_IA", self.wndMovables:FindChild("Movable_PlayerFrame_IA"))
	
	ForgeUI.RegisterWindowPosition(self, self.wndTargetFrame, "ForgeUI_UnitFrames_TargetFrame", self.wndMovables:FindChild("Movable_TargetFrame"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetFrame:FindChild("ShieldBar"), "ForgeUI_UnitFrames_TargetFrame_ShieldBar", self.wndMovables:FindChild("Movable_TargetFrame_ShieldBar"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetFrame:FindChild("AbsorbBar"), "ForgeUI_UnitFrames_TargetFrame_AbsorbBar", self.wndMovables:FindChild("Movable_TargetFrame_AbsorbBar"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetFrame:FindChild("InterruptArmor"), "ForgeUI_UnitFrames_TargetFrame_IA", self.wndMovables:FindChild("Movable_TargetFrame_IA"))
	
	ForgeUI.RegisterWindowPosition(self, self.wndFocusFrame, "ForgeUI_UnitFrames_FocusFrame", self.wndMovables:FindChild("Movable_FocusFrame"))
	
	ForgeUI.RegisterWindowPosition(self, self.wndToTFrame, "ForgeUI_UnitFrames_ToTFrame", self.wndMovables:FindChild("Movable_ToTFrame"))
	
	ForgeUI.RegisterWindowPosition(self, self.wndHazardBreath, "ForgeUI_UnitFrames_Hazard_Breath", self.wndMovables:FindChild("Movable_Hazard_Breath"))
	ForgeUI.RegisterWindowPosition(self, self.wndHazardHeat, "ForgeUI_UnitFrames_Hazard_Heat", self.wndMovables:FindChild("Movable_Hazard_Heat"))
	ForgeUI.RegisterWindowPosition(self, self.wndHazardToxic, "ForgeUI_UnitFrames_Hazard_Toxic", self.wndMovables:FindChild("Movable_Hazard_Toxic"))
	
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerBuffFrame, "ForgeUI_UnitFrames_PlayerBuffs", self.wndMovables:FindChild("Movable_PlayerBuffs"))
	ForgeUI.RegisterWindowPosition(self, self.wndPlayerDebuffFrame, "ForgeUI_UnitFrames_PlayerDebuffs", self.wndMovables:FindChild("Movable_PlayerDebuffs"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetBuffFrame, "ForgeUI_UnitFrames_TargetBuffs", self.wndMovables:FindChild("Movable_TargetBuffs"))
	ForgeUI.RegisterWindowPosition(self, self.wndTargetDebuffFrame, "ForgeUI_UnitFrames_TargetDebuffs", self.wndMovables:FindChild("Movable_TargetDebuffs"))

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
	
	self.wndToTFrame:FindChild("Background"):SetBGColor("ff" .. self.tSettings.backgroundBarColor)
	self.wndToTFrame:FindChild("HP_ProgressBar"):SetBarColor("ff" .. self.tSettings.hpBarColor)
	
	self.wndFocusFrame:FindChild("Background"):SetBGColor("ff" .. self.tSettings.backgroundBarColor)
	self.wndFocusFrame:FindChild("HP_ProgressBar"):SetBarColor("ff" .. self.tSettings.hpBarColor)
	self.wndFocusFrame:FindChild("HP_TextValue"):SetTextColor("ff" .. self.tSettings.hpTextColor)
	self.wndFocusFrame:FindChild("HP_TextPercent"):SetTextColor("ff" .. self.tSettings.hpTextColor)
	
	-- pets
	for i, petFrame in pairs(self.tWndPets) do
		petFrame:FindChild("Background"):SetBGColor("ff" .. self.tSettings.backgroundBarColor)
		petFrame:FindChild("HP_ProgressBar"):SetBarColor("ff" .. self.tSettings.hpBarColor)
		petFrame:FindChild("Shield_TextValue"):SetTextColor("ff" .. self.tSettings.shieldBarColor)
		petFrame:FindChild("HP_TextValue"):SetTextColor("ff" .. self.tSettings.hpTextColor)
	end
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

function ForgeUI_UnitFrames:OnGenerateBuffTooltip(wndHandler, wndControl, tType, splBuff)
	if wndHandler == wndControl or Tooltip == nil then
		return
	end
	Tooltip.GetBuffTooltipForm(self, wndControl, splBuff, {bFutureSpell = false})
end

---------------------------------------------------------------------------------------------------
-- Movables Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_UnitFrames:OnMovableMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndPlayerFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerFrame"):GetAnchorOffsets())
	self.wndPlayerFrame:FindChild("ShieldBar"):SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerFrame_ShieldBar"):GetAnchorOffsets())
	self.wndPlayerFrame:FindChild("AbsorbBar"):SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerFrame_AbsorbBar"):GetAnchorOffsets())
	self.wndPlayerFrame:FindChild("InterruptArmor"):SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerFrame_IA"):GetAnchorOffsets())
	
	self.wndTargetFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetFrame"):GetAnchorOffsets())
	self.wndTargetFrame:FindChild("ShieldBar"):SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetFrame_ShieldBar"):GetAnchorOffsets())
	self.wndTargetFrame:FindChild("AbsorbBar"):SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetFrame_AbsorbBar"):GetAnchorOffsets())
	self.wndTargetFrame:FindChild("InterruptArmor"):SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetFrame_IA"):GetAnchorOffsets())
	
	self.wndFocusFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_FocusFrame"):GetAnchorOffsets())
	
	self.wndToTFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_ToTFrame"):GetAnchorOffsets())
	
	self.wndPlayerBuffFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerBuffs"):GetAnchorOffsets())
	self.wndPlayerDebuffFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_PlayerDebuffs"):GetAnchorOffsets())
	self.wndTargetBuffFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetBuffs"):GetAnchorOffsets())
	self.wndTargetDebuffFrame:SetAnchorOffsets(self.wndMovables:FindChild("Movable_TargetDebuffs"):GetAnchorOffsets())
	
	self.wndHazardBreath:SetAnchorOffsets(self.wndMovables:FindChild("Movable_Hazard_Breath"):GetAnchorOffsets())
	self.wndHazardToxic:SetAnchorOffsets(self.wndMovables:FindChild("Movable_Hazard_Toxic"):GetAnchorOffsets())
	self.wndHazardHeat:SetAnchorOffsets(self.wndMovables:FindChild("Movable_Hazard_Heat"):GetAnchorOffsets())
	
	if self.wndPetControl ~= nil then
		self.wndPetControl:SetAnchorOffsets(self.wndMovables:FindChild("Movable_PetControl"):GetAnchorOffsets())
	end
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_PetControl Functions
---------------------------------------------------------------------------------------------------
function ForgeUI_UnitFrames:PetBar_OnMouseEnter( wndHandler, wndControl, x, y )
	local text = wndControl:GetParent():GetParent():GetParent():FindChild("Text")
	text:SetTextColor("FFFFFFFF")
	text:SetText(wndHandler:GetName())
end

function ForgeUI_UnitFrames:PetBar_OnMouseExit( wndHandler, wndControl, x, y )
	local text = wndControl:GetParent():GetParent():GetParent():FindChild("Text")
	text:SetText(tEngineerStances[Pet_GetStance(0)])
end

function ForgeUI_UnitFrames:PetBar_OnButtonSignal( wndHandler, wndControl, eMouseButton )
	if wndControl:GetName() == "Assist" then
		Pet_SetStance(0, 4)
	elseif wndControl:GetName() == "Passive" then
		Pet_SetStance(0, 3)
	elseif wndControl:GetName() == "Defend" then
		Pet_SetStance(0, 2)
	elseif wndControl:GetName() == "Aggro" then
		Pet_SetStance(0, 1)
	end
end

function ForgeUI_UnitFrames:OnPetStanceChanged(petId)
	self.wndPetControl:FindChild("Text"):SetText(tEngineerStances[Pet_GetStance(0)])
end

function ForgeUI_UnitFrames:OnPetSpawned(petId)
	self.wndPetControl:FindChild("Text"):SetText(tEngineerStances[Pet_GetStance(0)])
	self.wndPetControl:Show(true, true)
end

local ForgeUI_UnitFramesInst = ForgeUI_UnitFrames:new()
ForgeUI_UnitFramesInst:Init()

