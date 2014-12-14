require "Window"
 
local ForgeUI = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
API_VERSION = 1

-- errors
ERR_ADDON_REGISTERED = 0
ERR_ADDON_NOT_REGISTERED = 1
ERR_WRONG_API = 2

-----------------------------------------------------------------------------------------------
-- Variables
-----------------------------------------------------------------------------------------------
local tAddons = {} 

local wndItemList = nil
local wndActiveItem = nil
local wndItemContainer = nil
local wndItemContainer2 = nil

local tItemList_Items = {}

-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
local resetDefaults = false

local tSettings_addons = {}
local tSettings = {
	apiVersion = API_VERSION,
	masterColor = "xkcdFireEngineRed",
	wndMain = {
		left = 400,
		top = 180,
		right = 720,
		bottom = 480
	}
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ForgeUI:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
	self.wndContainers = {}	

    return o
end

local ForgeUIInst = ForgeUI:new()

function ForgeUI:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "ForgeUI"
	local tDependencies = {

	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end
	Apollo.LoadSprites("ForgeUI_Sprite.xml", "Forge")
	
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ForgeUI_Form", nil, self)
	self.wndMain:Show(false, true)
	
	wndItemList = self.wndMain:FindChild("ForgeUI_ListHolder")
	wndItemContainer = self.wndMain:FindChild("ForgeUI_ContainerHolder")
	wndItemContainer2 = self.wndMain:FindChild("ForgeUI_ContainerHolder2")

	Apollo.RegisterSlashCommand("forgeui", "OnForgeUIOn", self)
	
	local tmpWnd = ForgeUI.AddItemButton(self, "Home", "ForgeUI_Home", nil)
	wndActiveItem = tmpWnd:FindChild("ForgeUI_Item_Button")
	self:SetActiveItem(tmpWnd:FindChild("ForgeUI_Item_Button"))
	
	ForgeUI.AddItemButton(self, "General settings", "ForgeUI_General", nil)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI API
-----------------------------------------------------------------------------------------------
function ForgeUI.RegisterAddon(tAddon)
	if tAddons[tAddon.strAddonName] ~= nil then return ERR_ADDON_REGISTERED end
	if tAddon.api_version ~= API_VERSION then return ERR_WRONG_API end
	
	tAddons[tAddon.strAddonName] = tAddon
	
	if tAddon.ForgeAPI_AfterRegistration ~= nil then
		tAddon:ForgeAPI_AfterRegistration() -- Forge API AfterRegistration
	end
	
	tAddon.tSettings = ForgeUI.CopyTable(tAddon.tSettings, tSettings_addons[tAddon.strAddonName])
	
	if tAddon.ForgeAPI_AfterRestore ~= nil then
		tAddon:ForgeAPI_AfterRestore() -- Forge API AfterRestore
	end
end

function ForgeUI.AddItemButton(tAddon, strDisplayName, strWndContainer, tItems)
	local wnd = Apollo.LoadForm(ForgeUIInst.xmlDoc, "ForgeUI_Item", wndItemList, ForgeUIInst)
	wnd:FindChild("ForgeUI_Item_Text"):SetText(strDisplayName)
	
	local tData = {}
	if strWndContainer ~= nil then
		tAddon.wndContainers[strWndContainer] = Apollo.LoadForm(tAddon.xmlDoc, strWndContainer, wndItemContainer, tAddon)
		tAddon.wndContainers[strWndContainer]:Show(false)
		tData.wndContainer = tAddon.wndContainers[strWndContainer]
	end
	
	if tItems ~= nil then
		tData.tItems = tItems
	end
	wnd:FindChild("ForgeUI_Item_Button"):SetData(tData)
	
	return wnd 
end

-----------------------------------------------------------------------------------------------
-- ForgeUI Functions
-----------------------------------------------------------------------------------------------
function ForgeUI:OnConfigure()
	self:OnForgeUIOn()
end

function ForgeUI:OnForgeUIOn()
	wndItemList:ArrangeChildrenVert()
	self.wndMain:Invoke()
end

function ForgeUI:OnFOrgeUIOff( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close()
end

function ForgeUI:OnUnlockElements()
	for name, addon in pairs(tAddons) do
		if addon.ForgeAPI_OnUnlockElements ~= nil then
			addon:ForgeAPI_OnUnlockElements() -- Forge API OnUnlockElements
		end
	end
end

function ForgeUI:OnLockElements()
	for _, addon in pairs(tAddons) do
		if addon.ForgeAPI_OnLockElements ~= nil then
			addon:ForgeAPI_OnLockElements() -- Forge API OnLockElements
		end
	end
end

-----------------------------------------------------------------------------------------------
-- OnSave / OnRestore
-----------------------------------------------------------------------------------------------
function ForgeUI:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end

	if resetDefaults == true then
		return {}
	end
	
	local tSett = {}
	local tAdd = {}

	tSett = ForgeUI.CopyTable(tSett, tSettings)
	
	for addonName, addon in pairs(tAddons) do
		if addon.ForgeAPI_BeforeSave ~= nil then
			addon:ForgeAPI_BeforeSave() -- Forge API BeforeSave
		end
		tAdd[addonName] = ForgeUI.CopyTable(tAdd[addonName], addon.tSettings)
	end

	return {
		settings = tSett,
		addons = tAdd
	}
end

function ForgeUI:OnRestore(eType, tData)
	tSettings = ForgeUI.CopyTable(tSettings, tData.settings)
	
	if tData.addons == nil then return end
	for name, data in pairs(tData.addons) do
		tSettings_addons[name] = data
	end
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_Form Functions
---------------------------------------------------------------------------------------------------
function ForgeUI:SetActiveItem(wndControl)
	wndActiveItem:GetParent():FindChild("ForgeUI_Item_Text"):SetTextColor("white")
	wndActiveItem = wndControl
	wndControl:GetParent():FindChild("ForgeUI_Item_Text"):SetTextColor("xkcdFireEngineRed")
	wndItemContainer2:Show(false)
	wndItemContainer2 = wndControl:GetData().wndContainer
	wndItemContainer2:Show(true)
end

function ForgeUI:TestFunction( wndHandler, wndControl, eMouseButton )
	for _, addon in pairs(tAddons) do
		if addon.ForgeAPI_TestFunction ~= nil then
			addon:ForgeAPI_TestFunction()		
		end
	end
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_General Functions
---------------------------------------------------------------------------------------------------
function ForgeUI:OnUnlockButtonPressed( wndHandler, wndControl, eMouseButton )
	if wndControl:GetData() == nil or wndControl:GetData().locked == true then
		wndControl:SetData({locked = false})
		wndControl:SetText("Lock elements")
		self:OnUnlockElements()
	else
		wndControl:SetData({locked = true})
		wndControl:SetText("Unock elements")
		self:OnLockElements()
	end	
end

function ForgeUI:OnSaveButtonPressed( wndHandler, wndControl, eMouseButton )
	RequestReloadUI()
end

function ForgeUI:OnDefaultsButtonPressed( wndHandler, wndControl, eMouseButton )
	resetDefaults = true
	RequestReloadUI()
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_Item Functions
---------------------------------------------------------------------------------------------------
function ForgeUI:ItemListPressed( wndHandler, wndControl, eMouseButton )
	self:SetActiveItem(wndControl)
end

---------------------------------------------------------------------------------------------------
-- Libraries
---------------------------------------------------------------------------------------------------
function ForgeUI.CopyTable(tNew, tOld)
	if tOld == nil then return end
	if tNew == nil then
		tNew = {}
	end
	
	for k, v in pairs(tOld) do
		if type(v) == "table" then
			tNew[k] = ForgeUI.CopyTable(tNew[k], v)
		else
			tNew[k] = v
		end
	end
	return tNew
end

ForgeUIInst:Init() 
