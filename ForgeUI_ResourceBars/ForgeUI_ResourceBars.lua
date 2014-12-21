require "Window"
 
local ForgeUI_ResourceBars = {} 
 
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
function ForgeUI_ResourceBars:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- mandatory 
    self.api_version = 1
	self.version = "0.1.0"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_ResourceBars"
	self.strDisplayName = "Resource bars"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		smoothBars = false,
		borderColor = "000000",
		backgroundColor = "131313",
		backgroundBarColor = "101010",
		warrior = {
			resourceColor1 = "E53805",
			resourceColor2 = "EF0000",
			resourceColor3 = ""
		},
		stalker = {
			resourceColor1 = "D23EF4",
			resourceColor2 = "",
			resourceColor3 = ""
		},
		engineer = {
			resourceColor1 = "00AEFF",
			resourceColor2 = "FFB000",
			resourceColor3 = ""
		},
		esper = {
			resourceColor1 = "1591DB",
			resourceColor2 = "",
			resourceColor3 = ""
		},
		medic = {
			resourceColor1 = "98C723",
			resourceColor2 = "FFE757",
			resourceColor3 = ""
		},
		slinger = {
			resourceColor1 = "FFE757",
			resourceColor2 = "E53805",
			resourceColor3 = ""
		}
	}
	
	self.playerClass = nil
	self.playerMaxResource = nil

    return o
end

function ForgeUI_ResourceBars:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- ForgeUI_ResourceBars OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI_ResourceBars:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_ResourceBars.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ForgeUI_ResourceBars:ForgeAPI_AfterRegistration()
	self.wndMovables = Apollo.LoadForm(self.xmlDoc, "Movables", nil, self)
end

function ForgeUI_ResourceBars:ForgeAPI_AfterRestore()
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	else
		Apollo.RegisterEventHandler("CharacterCreated", 	"OnCharacterCreated", self)
	end
	
end

function ForgeUI_ResourceBars:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil then
		Print("ForgeUI ERROR: Wrong class")
		return
	end
	
	local eClassId = unitPlayer:GetClassId()
	if eClassId == GameLib.CodeEnumClass.Engineer then
		self.playerClass = "engineer"
		self:OnEngineerCreated(unitPlayer)
	elseif eClassId == GameLib.CodeEnumClass.Esper then
		self.playerClass = "esper"
		self:OnEsperCreated(unitPlayer)
	elseif eClassId == GameLib.CodeEnumClass.Medic then
		self.playerClass = "medic"
		self:OnMedicCreated(unitPlayer)
	elseif eClassId == GameLib.CodeEnumClass.Spellslinger then
		self.playerClass = "spellslinger"
		self:OnSlingerCreated(unitPlayer)
	elseif eClassId == GameLib.CodeEnumClass.Stalker then
		self.playerClass = "stalker"
		self:OnStalkerCreated(unitPlayer)
	elseif eClassId == GameLib.CodeEnumClass.Warrior then
		self.playerClass = "warrior"
		self:OnWarriorCreated(unitPlayer)	
	end
end

-----------------------------------------------------------------------------------------------
-- Engineer
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnEngineerCreated(unitPlayer)
	self.playerMaxResource = unitPlayer:GetMaxResource(1)

	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Engineer", "FixedHudStratumHigh", self)
	self.wndResource:FindChild("Border"):SetBGColor("FF" .. self.tSettings.borderColor)
	self.wndResource:FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
	self.wndResource:FindChild("ProgressBar"):SetMax(self.playerMaxResource)
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnEngineerUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnEngineerUpdate", self)
	end
	
	ForgeUI.RegisterWindowPosition(self, self.wndResource, "ForgeUI_ResourceBars_Resource", self.wndMovables:FindChild("Movable_Resource"))
end

function ForgeUI_ResourceBars:OnEngineerUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(1)
	if unitPlayer:IsInCombat() or nResource > 0 then
		self.wndResource:FindChild("ProgressBar"):SetProgress(nResource)
		self.wndResource:FindChild("Value"):SetText(nResource)
		
		if nResource < 30 or nResource > 70 then
			self.wndResource:FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.engineer.resourceColor1)
		else
			self.wndResource:FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.engineer.resourceColor2)
		end
		
		self.wndResource:Show(true, true)
	else
		self.wndResource:Show(false, true)
	end
end

-----------------------------------------------------------------------------------------------
-- Esper
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnEsperCreated(unitPlayer)
	self.playerMaxResource = unitPlayer:GetMaxResource(1)

	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Esper", "FixedHudStratumHigh", self)
	self.wndFocus = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Focus", "FixedHudStratumHigh", self)
	
	for i = 1, self.playerMaxResource do
		self.wndResource:FindChild("PSI" .. i):SetBGColor("FF" .. self.tSettings.borderColor)
		self.wndResource:FindChild("PSI" .. i):FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
		self.wndResource:FindChild("PSI" .. i):FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.esper.resourceColor1)
		self.wndResource:FindChild("PSI" .. i):FindChild("ProgressBar"):SetMax(1)
	end
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnEsperUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnEsperUpdate", self)
	end
	
	ForgeUI.RegisterWindowPosition(self, self.wndResource, "ForgeUI_ResourceBars_Resource", self.wndMovables:FindChild("Movable_Resource"))
	ForgeUI.RegisterWindowPosition(self, self.wndFocus, "ForgeUI_ResourceBars_Focus", self.wndMovables:FindChild("Movable_Focus"))
end

function ForgeUI_ResourceBars:OnEsperUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(1)
	
	if unitPlayer:IsInCombat() or nResource > 0 then
		for i = 1, self.playerMaxResource do
			if nResource >= i then
				self.wndResource:FindChild("PSI" .. i):FindChild("ProgressBar"):SetProgress(1)
			else
				self.wndResource:FindChild("PSI" .. i):FindChild("ProgressBar"):SetProgress(0)
			end
		end
		
		self.wndResource:Show(true, true)
	else
		self.wndResource:Show(false, true)
	end
	
	self:UpdateFocus(unitPlayer)
end

-----------------------------------------------------------------------------------------------
-- Medic
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnMedicCreated(unitPlayer)
	self.playerMaxResource = unitPlayer:GetMaxResource(1)

	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Medic", "FixedHudStratumHigh", self)
	self.wndFocus = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Focus", "FixedHudStratumHigh", self)
	
	for i = 1, self.playerMaxResource do
		self.wndResource:FindChild("ACU" .. i):SetBGColor("FF" .. self.tSettings.borderColor)
		self.wndResource:FindChild("ACU" .. i):FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
		self.wndResource:FindChild("ACU" .. i):FindChild("ProgressBar"):SetMax(3)
	end
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnMedicUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnMedicUpdate", self)
	end
	
	ForgeUI.RegisterWindowPosition(self, self.wndResource, "ForgeUI_ResourceBars_Resource", self.wndMovables:FindChild("Movable_Resource"))
	ForgeUI.RegisterWindowPosition(self, self.wndFocus, "ForgeUI_ResourceBars_Focus", self.wndMovables:FindChild("Movable_Focus"))
end

function ForgeUI_ResourceBars:OnMedicUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(1)
	
	if unitPlayer:IsInCombat() or nResource < self.playerMaxResource then
		for i = 1, self.playerMaxResource do
			if nResource >= i then
				self.wndResource:FindChild("ACU" .. i):FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.medic.resourceColor1)
				self.wndResource:FindChild("ACU" .. i):FindChild("ProgressBar"):SetProgress(3)
			else
				self.wndResource:FindChild("ACU" .. i):FindChild("ProgressBar"):SetProgress(0)
				if (nResource + 1) == i then
					local nAcu = 0
				
					for key, buff in pairs(unitPlayer:GetBuffs().arBeneficial) do
						if buff.splEffect:GetId() == 42569 then 
							nAcu = buff.nCount
						end
					end
					
					self.wndResource:FindChild("ACU" .. i):FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.medic.resourceColor2)
					self.wndResource:FindChild("ACU" .. i):FindChild("ProgressBar"):SetProgress(nAcu)
				end
			end
		end
		
		self.wndResource:Show(true, true)
	else
		self.wndResource:Show(false, true)
	end
	
	self:UpdateFocus(unitPlayer)
end

-----------------------------------------------------------------------------------------------
-- Slinger
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnSlingerCreated(unitPlayer)
	self.playerMaxResource = unitPlayer:GetMaxResource(4)

	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Slinger", "FixedHudStratumHigh", self)
	self.wndFocus = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Focus", "FixedHudStratumHigh", self)
	
	for i = 1, 4 do
		self.wndResource:FindChild("RUNE" .. i):SetBGColor("FF" .. self.tSettings.borderColor)
		self.wndResource:FindChild("RUNE" .. i):FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
		self.wndResource:FindChild("RUNE" .. i):FindChild("ProgressBar"):SetMax(25)
	end
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnSlingerUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnSlingerUpdate", self)
	end
	
	ForgeUI.RegisterWindowPosition(self, self.wndResource, "ForgeUI_ResourceBars_Resource", self.wndMovables:FindChild("Movable_Resource"))
	ForgeUI.RegisterWindowPosition(self, self.wndFocus, "ForgeUI_ResourceBars_Focus", self.wndMovables:FindChild("Movable_Focus"))
end

function ForgeUI_ResourceBars:OnSlingerUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(4)
	
	if unitPlayer:IsInCombat() or GameLib.IsSpellSurgeActive() or nResource < self.playerMaxResource then
		for i = 1, 4 do
			if nResource >= (i * 25) then
				self.wndResource:FindChild("RUNE" .. i):FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.slinger.resourceColor1)
				self.wndResource:FindChild("RUNE" .. i):FindChild("ProgressBar"):SetProgress(25)
			else
				self.wndResource:FindChild("RUNE" .. i):FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.slinger.resourceColor2)
				self.wndResource:FindChild("RUNE" .. i):FindChild("ProgressBar"):SetProgress(25 - ((i * 25) - nResource))
			end
		end
		
		self.wndResource:Show(true, true)
	else
		self.wndResource:Show(false, true)
	end
	
	if GameLib.IsSpellSurgeActive() then
		self.wndResource:FindChild("SpellSurge"):Show(true, true)
	else
		self.wndResource:FindChild("SpellSurge"):Show(false, true)
	end

	self:UpdateFocus(unitPlayer)
end

-----------------------------------------------------------------------------------------------
-- Stalker
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnStalkerCreated(unitPlayer)
	self.playerMaxResource = unitPlayer:GetMaxResource(1)

	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Stalker", "FixedHudStratumHigh", self)
	self.wndResource:FindChild("Border"):SetBGColor("FF" .. self.tSettings.borderColor)
	self.wndResource:FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
	self.wndResource:FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.stalker.resourceColor1)
	self.wndResource:FindChild("ProgressBar"):SetMax(100)
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnStalkerUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnStalkerUpdate", self)
	end
	
	ForgeUI.RegisterWindowPosition(self, self.wndResource, "ForgeUI_ResourceBars_Resource", self.wndMovables:FindChild("Movable_Resource"))
end

function ForgeUI_ResourceBars:OnStalkerUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(3)
	if unitPlayer:IsInCombat() or nResource < self.playerMaxResource then
		self.wndResource:FindChild("ProgressBar"):SetProgress(nResource)
		self.wndResource:FindChild("Value"):SetText(nResource)
		
		self.wndResource:Show(true, true)
	else
		self.wndResource:Show(false, true)
	end
end

-----------------------------------------------------------------------------------------------
-- Warrior
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnWarriorCreated(unitPlayer)
	self.playerMaxResource = unitPlayer:GetMaxResource(1)

	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Warrior", "FixedHudStratumHigh", self)
	self.wndResource:FindChild("Border"):SetBGColor("FF" .. self.tSettings.borderColor)
	self.wndResource:FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
	self.wndResource:FindChild("ProgressBar"):SetMax(self.playerMaxResource)
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnWarriorUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnWarriorUpdate", self)
	end
	
	ForgeUI.RegisterWindowPosition(self, self.wndResource, "ForgeUI_ResourceBars_Resource", self.wndMovables:FindChild("Movable_Resource"))
end

function ForgeUI_ResourceBars:OnWarriorUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(1)
	if unitPlayer:IsInCombat() or nResource > 0 then
		self.wndResource:FindChild("ProgressBar"):SetProgress(nResource)
		self.wndResource:FindChild("Value"):SetText(nResource)
		
		if nResource < 750 then
			self.wndResource:FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.warrior.resourceColor1)
		else
			self.wndResource:FindChild("ProgressBar"):SetBarColor("FF" .. self.tSettings.warrior.resourceColor2)
		end
		
		self.wndResource:Show(true, true)
	else
		self.wndResource:Show(false, true)
	end
end

-----------------------------------------------------------------------------------------------
-- focus
-----------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:UpdateFocus(unitPlayer)
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	if self.wndFocus == nil then return end
	
	local nMana = unitPlayer:GetMana()
	local nMaxMana = unitPlayer:GetMaxMana()
	
	if nMana < nMaxMana then
		self.wndFocus:FindChild("ProgressBar"):SetMax(nMaxMana)
		self.wndFocus:FindChild("ProgressBar"):SetProgress(nMana)
		self.wndFocus:FindChild("Value"):SetText(ForgeUI.Round(nMana, 0))
		
		self.wndFocus:Show(true, true)
	else
		self.wndFocus:Show(false, true)
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ResourceBars OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_ResourceBars:OnDocLoaded()
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
end

---------------------------------------------------------------------------------------------------
-- Movables Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ResourceBars:OnMovableMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndResource:SetAnchorOffsets(wndControl:GetAnchorOffsets())
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ResourceBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_ResourceBarsInst = ForgeUI_ResourceBars:new()
ForgeUI_ResourceBarsInst:Init()
