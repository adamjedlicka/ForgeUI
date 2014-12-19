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
		}
	}
	
	self.playerClass = nil

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
		self:OnWarriorCreated()
	end
end

function ForgeUI_ResourceBars:OnWarriorCreated()
	self.wndResource = Apollo.LoadForm(self.xmlDoc, "ResourceBar_Warrior", "FixedHudStratumHigh", self)
	self.wndResource:FindChild("Border"):SetBGColor("FF" .. self.tSettings.borderColor)
	self.wndResource:FindChild("Background"):SetBGColor("FF" .. self.tSettings.backgroundColor)
	self.wndResource:FindChild("ProgressBar"):SetMax(1000)
	
	if self.tSettings.smoothBars then
		Apollo.RegisterEventHandler("NextFrame", "OnWarriorUpdate", self)
	else
		Apollo.RegisterEventHandler("VarChange_FrameCount", "OnWarriorUpdate", self)
	end
end

function ForgeUI_ResourceBars:OnWarriorUpdate()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	
	local nResource = unitPlayer:GetResource(1)
	if unitPlayer:IsInCombat() and nResource > 0 then
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
-- ForgeUI_ResourceBars OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_ResourceBars:OnDocLoaded()
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ResourceBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_ResourceBarsInst = ForgeUI_ResourceBars:new()
ForgeUI_ResourceBarsInst:Init()
