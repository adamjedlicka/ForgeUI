require "Window"
 
-----------------------------------------------------------------------------------------------
-- ForgeUI_UnitFrames Module Definition
-----------------------------------------------------------------------------------------------
local ForgeUI_UnitFrames = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

 
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
	}

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
	ForgeUI.AddItemListToButton(self, wnd, {
		{ strDisplayName = "General", strContainer = "Container" },
		{ strDisplayName = "Player frame", strContainer = "Container_PlayerFrame" }
	}) 
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
end

local ForgeUI_UnitFramesInst = ForgeUI_UnitFrames:new()
ForgeUI_UnitFramesInst:Init()
