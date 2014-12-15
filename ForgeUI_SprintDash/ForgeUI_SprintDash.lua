require "Window"
 
local ForgeUI_SprintDash = {} 

local sprintResource = 0
local dashResource = 7

function ForgeUI_SprintDash:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- mandatory 
    self.api_version = 1
	self.version = "0.0.1"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_SprintDash"
	self.strDisplayName = "Sprint / dash meter"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		sprintColor = "cccccc",
		dashColor = "00aaff",
		dashColor2 = "0055aa"
	}

    return o
end

function ForgeUI_SprintDash:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

function ForgeUI_SprintDash:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_SprintDash.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ForgeUI_SprintDash:OnDocLoaded()
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnNextFrame", self)
end

-------------------------------------------------------------------------------
-- ForgeAPI
-------------------------------------------------------------------------------
function ForgeUI_SprintDash:ForgeAPI_AfterRegistration()
	ForgeUI.AddItemButton(self, "Sprint / dash meter", "Container", nil)

	self.wndSprintMeter = Apollo.LoadForm(self.xmlDoc, "SprintMeter", "InWorldHudStratum", self)
	self.wndDashMeter = Apollo.LoadForm(self.xmlDoc, "DashMeter", "InWorldHudStratum", self)
	self.wndDashMeter:FindChild("DashMeter_B"):SetSprite("ForgeUI_Sprite:ForgeUI_Border")
	
	-- movables
	self.wndMovables = Apollo.LoadForm(self.xmlDoc, "Movables", nil, self)
end

function ForgeUI_SprintDash:ForgeAPI_AfterRestore()
	ForgeUI.RegisterWindowPosition(self, self.wndSprintMeter, "ForgeUI_SprintDash_Sprint", self.wndMovables:FindChild("Movable_SprintMeter"))
	
	ForgeUI.RegisterWindowPosition(self, self.wndDashMeter, "ForgeUI_SprintDash_Dash", self.wndMovables:FindChild("Movable_DashMeter"))

	self.wndContainers.Container:FindChild("SprintMeter_Color"):SetTextColor(ApolloColor.new("ff" .. self.tSettings.sprintColor))
	self.wndContainers.Container:FindChild("SprintMeter_Color"):SetText(self.tSettings.sprintColor)
	self.wndContainers.Container:FindChild("DashMeter_Color"):SetTextColor(ApolloColor.new("ff" .. self.tSettings.dashColor))
	self.wndContainers.Container:FindChild("DashMeter_Color"):SetText(self.tSettings.dashColor)
	self.wndContainers.Container:FindChild("DashMeter_Color2"):SetTextColor(ApolloColor.new("ff" .. self.tSettings.dashColor2))
	self.wndContainers.Container:FindChild("DashMeter_Color2"):SetText(self.tSettings.dashColor2)
end

function ForgeUI_SprintDash:ForgeAPI_BeforeSave()

end

function ForgeUI_SprintDash:ForgeAPI_OnUnlockElements()
	self.wndMovables:Show(true)
	self.wndSprintMeter:Show(false)
end

function ForgeUI_SprintDash:ForgeAPI_OnLockElements()
	self.wndMovables:Show(false)
	self.wndSprintMeter:Show(true)
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------
function ForgeUI_SprintDash:OnNextFrame()
	local unitPlayer = GameLib.GetPlayerUnit()	
    if unitPlayer == nil then return end
	
	-- sprint meter
	local nSprintCurr = unitPlayer:GetResource(sprintResource)
	local nSprintMax = unitPlayer:GetMaxResource(sprintResource)
	local bSprintFull = nSprintCurr == nSprintMax or unitPlayer:IsDead()

	if not bSprintFull then
		self.wndSprintMeter:FindChild("Bar"):SetMax(unitPlayer:GetMaxResource(sprintResource))
		self.wndSprintMeter:FindChild("Bar"):SetProgress(unitPlayer:GetResource(sprintResource))
		self.wndSprintMeter:FindChild("Bar"):SetBarColor(ApolloColor.new("ff" .. self.tSettings.sprintColor))
	end
	
	self.wndSprintMeter:Show(not bSprintFull, true)
	
	-- dash meter
	local nDashCurr = unitPlayer:GetResource(dashResource)
	local nDashMax = unitPlayer:GetMaxResource(dashResource)
	local bDashFull = nDashCurr == nDashMax or unitPlayer:IsDead()
	
	if not bDashFull then
		if nDashCurr < 100 then
			self.wndDashMeter:FindChild("Bar_A"):SetMax(unitPlayer:GetMaxResource(dashResource) / 2)
			self.wndDashMeter:FindChild("Bar_A"):SetProgress(unitPlayer:GetResource(dashResource))
			self.wndDashMeter:FindChild("Bar_A"):SetBarColor(ApolloColor.new("ff" .. self.tSettings.dashColor2))
			
			self.wndDashMeter:FindChild("Bar_B"):SetProgress(0)
		else
			self.wndDashMeter:FindChild("Bar_B"):SetMax(unitPlayer:GetMaxResource(dashResource) / 2)
			self.wndDashMeter:FindChild("Bar_B"):SetProgress(unitPlayer:GetResource(dashResource) - (unitPlayer:GetMaxResource(dashResource) / 2))
			self.wndDashMeter:FindChild("Bar_B"):SetBarColor(ApolloColor.new("ff" .. self.tSettings.dashColor2))
			
			self.wndDashMeter:FindChild("Bar_A"):SetMax(unitPlayer:GetMaxResource(dashResource) / 2)
			self.wndDashMeter:FindChild("Bar_A"):SetProgress(unitPlayer:GetMaxResource(dashResource) / 2)
			self.wndDashMeter:FindChild("Bar_A"):SetBarColor(ApolloColor.new("ff" .. self.tSettings.dashColor))
		end		
	end
	
	self.wndDashMeter:Show(not bDashFull, true)
end

---------------------------------------------------------------------------------------------------
-- Movables Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_SprintDash:OnMovableMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndSprintMeter:MoveToLocation(self.wndMovables:FindChild("Movable_SprintMeter"):GetLocation())
	self.wndDashMeter:MoveToLocation(self.wndMovables:FindChild("Movable_DashMeter"):GetLocation())
end

---------------------------------------------------------------------------------------------------
-- Container Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_SprintDash:ColorBoxReturn( wndHandler, wndControl, strText )
	wndControl:SetTextColor(ApolloColor.new("ff" .. wndControl:GetText()))
	if(wndControl:GetName() == "SprintMeter_Color") then
		self.tSettings.sprintColor = wndControl:GetText()
	end if(wndControl:GetName() == "DashMeter_Color") then
		self.tSettings.dashColor = wndControl:GetText()
	end if(wndControl:GetName() == "DashMeter_Color2") then
		self.tSettings.dashColor2 = wndControl:GetText()
	end
end

local ForgeUI_SprintDashInst = ForgeUI_SprintDash:new()
ForgeUI_SprintDashInst:Init()










