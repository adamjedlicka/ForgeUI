require "Window"
 
-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars Module Definition
-----------------------------------------------------------------------------------------------
local ForgeUI
local ForgeUI_ActionBars = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ForgeUI_ActionBars:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- mandatory 
    self.api_version = 1
	self.version = "0.1.0"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_ActionBars"
	self.strDisplayName = "Action bars"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {

	}

    return o
end

function ForgeUI_ActionBars:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI_ActionBars:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_ActionBars.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ForgeUI_ActionBars:ForgeAPI_AfterRegistration()
	self.wndActionBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_ActionBar", "InWorldHudStratum", self)
	self.wndStanceBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_StanceBar", "InWorldHudStratum", self)
	self.wndGadgetBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_GadgetBar", "InWorldHudStratum", self)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_ActionBars:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)

---------------------------------------------------------------------------------------------------
-- ForgeUI_InnateBar Functions
---------------------------------------------------------------------------------------------------
end
function ForgeUI_ActionBars:OnStancePopup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local wndPopup = wndHandler:FindChild("Popup")
	local wndList = wndPopup:FindChild("List")

	wndList:DestroyChildren()
	
	local nCountSkippingTwo = 0
	for idx, spellObject in pairs(GameLib.GetClassInnateAbilitySpells().tSpells) do
		if idx % 2 == 1 then
			nCountSkippingTwo = nCountSkippingTwo + 1
			local strKeyBinding = GameLib.GetKeyBinding("SetStance"..nCountSkippingTwo) -- hardcoded formatting
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_StanceBtn", wndList, self)
			wndCurr:FindChild("Icon"):SetSprite(spellObject:GetIcon())
			wndCurr:FindChild("Button"):SetData(nCountSkippingTwo)

			if Tooltip and Tooltip.GetSpellTooltipForm then
				wndCurr:SetTooltipDoc(nil)
				Tooltip.GetSpellTooltipForm(self, wndCurr, spellObject)
			end
		end
	end
	
	local nLeft, nTop, nRight, nBottom = wndPopup:GetAnchorOffsets()
	wndPopup:SetAnchorOffsets(nLeft, -(nCountSkippingTwo * 45), nRight, nBottom)
	
	wndList:ArrangeChildrenVert(0)
	
	if eMouseButton == 1 then
		wndPopup:Show(not wndPopup:IsShown())
	end
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_StanceBtn Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ActionBars:OnStanceBtn( wndHandler, wndControl, eMouseButton )
	self.wndStanceBar:FindChild("Popup"):Show(false)
	GameLib.SetCurrentClassInnateAbilityIndex(wndHandler:GetData())
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_ActionBarsInst = ForgeUI_ActionBars:new()
ForgeUI_ActionBarsInst:Init()
