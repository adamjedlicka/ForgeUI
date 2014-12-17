require "Window"
 
local ForgeUI = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
VERSION = "0.0.4f"
AUTHOR = "WintyBadass"
API_VERSION = 1

-- errors
ERR_ADDON_REGISTERED = 0
ERR_ADDON_NOT_REGISTERED = 1
ERR_WRONG_API = 2

-----------------------------------------------------------------------------------------------
-- Variables
-----------------------------------------------------------------------------------------------
local tAddons = {} 
local bCanRegisterAddons = false
local tAddonsToRegister = {}

local wndItemList = nil
local wndActiveItem = nil
local wndItemContainer = nil
local wndItemContainer2 = nil

local tItemList_Items = {}
local tRegisteredWindows = {} -- saving windows for repositioning them later

-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
local resetDefaults = false

local tSettings_addons = {}
local tSettings_windowsPositions = {}
local tSettings = {
	apiVersion = API_VERSION,
	masterColor = "xkcdFireEngineRed",
	classColors = {
		engineer = "EFAB48",
		esper = "1591DB",
		medic = "FFE757",
		spellslinger = "98C723",
		stalker = "D23EF4",
		warrior = "F54F4F"
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
	self.wndMain:FindChild("Version"):FindChild("Text"):SetText(VERSION)
	self.wndMain:FindChild("Author"):FindChild("Text"):SetText(AUTHOR)
	self.wndMain:Show(false, true)
	
	wndItemList = Apollo.LoadForm(self.xmlDoc, "ForgeUI_ListHolder", self.wndMain:FindChild("ForgeUI_Form_ItemList"), self)
	wndItemContainer = self.wndMain:FindChild("ForgeUI_ContainerHolder")
	wndItemContainer2 = self.wndMain:FindChild("ForgeUI_ContainerHolder2")

	Apollo.RegisterSlashCommand("forgeui", "OnForgeUIOn", self)
	
	local tmpWnd = ForgeUI.AddItemButton(self, "Home", "ForgeUI_Home")
	wndActiveItem = tmpWnd
	self:SetActiveItem(tmpWnd)
	
	ForgeUI.AddItemButton(self, "General settings", "ForgeUI_General")
	
	ForgeUI.RegisterWindowPosition(self, self.wndMain, "ForgeUI_Core")
	
	bCanRegisterAddons = true
	
	for _, tAddon in pairs(tAddonsToRegister) do -- loading not registered addons
		ForgeUI.RegisterAddon(tAddon)
	end
	
	self:Initialize()
end

function ForgeUI:Initialize()
	ForgeUI.ColorBoxChanged(self.wndContainers.ForgeUI_General:FindChild("ClassColor_Engineer"):FindChild("EditBox"), tSettings.classColors.engineer, "engineer")
	ForgeUI.ColorBoxChanged(self.wndContainers.ForgeUI_General:FindChild("ClassColor_Esper"):FindChild("EditBox"), tSettings.classColors.esper, "esper")
	ForgeUI.ColorBoxChanged(self.wndContainers.ForgeUI_General:FindChild("ClassColor_Spellslinger"):FindChild("EditBox"), tSettings.classColors.spellslinger, "spellslinger")
	ForgeUI.ColorBoxChanged(self.wndContainers.ForgeUI_General:FindChild("ClassColor_Stalker"):FindChild("EditBox"), tSettings.classColors.stalker, "stalker")
	ForgeUI.ColorBoxChanged(self.wndContainers.ForgeUI_General:FindChild("ClassColor_Medic"):FindChild("EditBox"), tSettings.classColors.medic, "medic")
	ForgeUI.ColorBoxChanged(self.wndContainers.ForgeUI_General:FindChild("ClassColor_Warrior"):FindChild("EditBox"), tSettings.classColors.warrior, "warrior")
end

-----------------------------------------------------------------------------------------------
-- ForgeUI API
-----------------------------------------------------------------------------------------------
function ForgeUI.RegisterAddon(tAddon)
	if tAddons[tAddon.strAddonName] ~= nil then return ERR_ADDON_REGISTERED end
	if tAddon.api_version ~= API_VERSION then return ERR_WRONG_API end
	
	if bCanRegisterAddons then
		tAddons[tAddon.strAddonName] = tAddon
		
		if tAddon.ForgeAPI_AfterRegistration ~= nil then
			tAddon:ForgeAPI_AfterRegistration() -- Forge API AfterRegistration
		end
		
		tAddon.tSettings = ForgeUI.CopyTable(tAddon.tSettings, tSettings_addons[tAddon.strAddonName])
		
		if tAddon.ForgeAPI_AfterRestore ~= nil then
			tAddon:ForgeAPI_AfterRestore() -- Forge API AfterRestore
		end
	else
		tAddonsToRegister[tAddon.strAddonName] = tAddon
	end
end

function ForgeUI.AddItemButton(tAddon, strDisplayName, strWndContainer, tOptions)
	local wndButton = Apollo.LoadForm(ForgeUIInst.xmlDoc, "ForgeUI_Item", wndItemList, ForgeUIInst):FindChild("ForgeUI_Item_Button")
	wndButton:GetParent():FindChild("ForgeUI_Item_Text"):SetText(strDisplayName)
	
	local tData = {}
	if strWndContainer ~= nil then
		tAddon.wndContainers[strWndContainer] = Apollo.LoadForm(tAddon.xmlDoc, strWndContainer, wndItemContainer, tAddon)
		tAddon.wndContainers[strWndContainer]:Show(false)
		tData.itemContainer = tAddon.wndContainers[strWndContainer]
	end
	
	tData.itemList = wndItemList
	
	wndButton:SetData(tData)
	
	return wndButton
end

function ForgeUI.AddItemListToButton(tAddon, wndButton, tItems)
	local wndList = Apollo.LoadForm(ForgeUIInst.xmlDoc, "ForgeUI_ListHolder", ForgeUIInst.wndMain:FindChild("ForgeUI_Form_ItemList"), ForgeUIInst)
	wndList:Show(false)
	local wndBackButton = Apollo.LoadForm(ForgeUIInst.xmlDoc, "ForgeUI_Item", wndList, ForgeUIInst):FindChild("ForgeUI_Item_Button")
	wndBackButton:GetParent():FindChild("ForgeUI_Item_Text"):SetText("BACK")
	
	for i, tItem in pairs(tItems) do
		local wndBtn = Apollo.LoadForm(ForgeUIInst.xmlDoc, "ForgeUI_Item", wndList, ForgeUIInst):FindChild("ForgeUI_Item_Button")
		wndBtn:GetParent():FindChild("ForgeUI_Item_Text"):SetText(tItem.strDisplayName)
		tAddon.wndContainers[tItem.strContainer] = Apollo.LoadForm(tAddon.xmlDoc, tItem.strContainer, wndItemContainer, tAddon)
		tAddon.wndContainers[tItem.strContainer]:Show(false)
		wndBtn:SetData({
			itemContainer = tAddon.wndContainers[tItem.strContainer],
			itemList = nil
		}) 
	end
	
	wndBackButton:SetData({
		itemList = wndButton:GetData().itemList
	})
	
	wndButton:SetData({
		itemContainer = wndButton:GetData().itemContainer,
		itemList = wndList
	})
	
	wndList:ArrangeChildrenVert()
end

function ForgeUI.RegisterWindowPosition(tAddon, wnd, strName, wndMovable)
	tRegisteredWindows[strName] = wnd

	if tSettings_windowsPositions[strName] ~= nil then
		wnd:SetAnchorOffsets(
			tSettings_windowsPositions[strName].left,
			tSettings_windowsPositions[strName].top,
			tSettings_windowsPositions[strName].right,
			tSettings_windowsPositions[strName].bottom
		)
	else
		local nLeft, nTop, nRight, nBottom = wnd:GetAnchorOffsets()
		tSettings_windowsPositions[strName] = {
			left = nLeft,
			top = nTop,
			right = nRight,
			bottom = nBottom
		}
	end
	if wndMovable ~= nil then
		wndMovable:SetAnchorOffsets(wnd:GetAnchorOffsets())
		wndMovable:SetAnchorPoints(wnd:GetAnchorPoints())
	end
end

function ForgeUI.GetSettings(arg)
	if arg ~= nil then
		return tSettings[arg]
	else
		return tSettings
	end
end

function ForgeUI.SetSettings(str)
	tSettings.classColors.warrior = str
end

function ForgeUI.ColorBoxChanged(wndControl, settings, data)
	if settings ~= nil then
		wndControl:SetText(settings)
		wndControl:SetTextColor("ff" .. settings)
	end
	
	if data ~= nil then
		wndControl:SetData(data)
	end
	
	local colorString = wndControl:GetText()
		
	if string.len(colorString) > 6 then
		wndControl:SetText(string.sub(colorString, 0, 6))
	elseif string.len(colorString) == 6 then
		wndControl:SetTextColor("ff" .. colorString)
	end
	
	return wndControl
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
	
	for addonName, addon in pairs(tAddons) do -- addon settings
		if addon.ForgeAPI_BeforeSave ~= nil then
			addon:ForgeAPI_BeforeSave() -- Forge API BeforeSave
		end
		tAdd[addonName] = ForgeUI.CopyTable(tAdd[addonName], addon.tSettings)
	end
	
	for id, wnd in pairs(tSettings_windowsPositions) do -- registered windows
		local nLeft, nTop, nRight, nBottom = tRegisteredWindows[id]:GetAnchorOffsets()
		tSettings_windowsPositions[id] = {
			left = nLeft,
			top = nTop,
			right = nRight,
			bottom = nBottom
		}
	end

	return {
		settings = tSett,
		addons = tAdd,
		windowsPositions = tSettings_windowsPositions,
	}
end

function ForgeUI:OnRestore(eType, tData)
	if tData.settings == nil then return end
	tSettings = ForgeUI.CopyTable(tSettings, tData.settings)
	tSettings_windowsPositions = ForgeUI.CopyTable(tSettings_windowsPositions, tData.windowsPositions)
	
	if tData.addons == nil then return end
	for name, data in pairs(tData.addons) do
		tSettings_addons[name] = data
	end
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

---------------------------------------------------------------------------------------------------
-- ForgeUI_Form Functions
---------------------------------------------------------------------------------------------------
function ForgeUI:SetActiveItem(wndControl)
	wndItemContainer2:Show(false)
	if wndControl:GetData().itemContainer ~= nil then
		wndActiveItem:GetParent():FindChild("ForgeUI_Item_Text"):SetTextColor("white")
		wndActiveItem = wndControl
		wndControl:GetParent():FindChild("ForgeUI_Item_Text"):SetTextColor("xkcdFireEngineRed")
		wndItemContainer2 = wndControl:GetData().itemContainer
		wndItemContainer2:Show(true)
	else
		wndItemList:Show(false)
		wndItemList = wndControl:GetData().itemList
		wndItemList:Show(true)	
	end
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

function ForgeUI:ResetDefaults()
	resetDefaults = true
	RequestReloadUI()
end

function ForgeUI:OnDefaultsButtonPressed( wndHandler, wndControl, eMouseButton )
	ForgeUI.CreateConfirmWindow(self, self.ResetDefaults)
end

function ForgeUI:EditBoxChanged( wndHandler, wndControl, strText )
	local tmpWnd = ForgeUI.ColorBoxChanged(wndControl)
	tSettings.classColors[tmpWnd:GetData()] = tmpWnd:GetText()
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_Item Functions
---------------------------------------------------------------------------------------------------
function ForgeUI:ItemListPressed( wndHandler, wndControl, eMouseButton )
	self:SetActiveItem(wndControl)
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_ConfirmWindow Functions
---------------------------------------------------------------------------------------------------
function ForgeUI:ForgeUI_ConfirmWindow( wndHandler, wndControl, eMouseButton )
	if(wndControl:GetName() == "YesButton") then
		wndControl:GetData()()
		
	elseif(wndControl:GetName() == "NoButton") then
	
	end
	wndControl:GetParent():Destroy()
end

function ForgeUI.CreateConfirmWindow(self, fCallback)
	local wndConfirmWindow = Apollo.LoadForm(ForgeUIInst.xmlDoc, "ForgeUI_ConfirmWindow", nil, ForgeUIInst)
	wndConfirmWindow:FindChild("YesButton"):SetData(fCallback)
end

---------------------------------------------------------------------------------------------------
-- Libraries
---------------------------------------------------------------------------------------------------
function ForgeUI.ReturnTestStr()
	return "OK"
end

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

function ForgeUI.ShortNum(num)
	local tmp = tostring(num)
    if not num then
        return 0
    elseif num >= 1000000 then
        ret = string.sub(tmp, 1, string.len(tmp) - 6) .. "." .. string.sub(tmp, string.len(tmp) - 5, string.len(tmp) - 5) .. "M"
    elseif num >= 1000 then
        ret = string.sub(tmp, 1, string.len(tmp) - 3) .. "." .. string.sub(tmp, string.len(tmp) - 2, string.len(tmp) - 2) .. "k"    else
        ret = num -- hundreds
    end
    return ret
end

function ForgeUI.FormatDuration(tim)
	if tim == nil then return end 
	if (tim>86400) then
		return ("%.0fd"):format(tim/86400)
	elseif (tim>3600) then
		return ("%.0fh"):format(tim/3600)
	elseif (tim>60) then
		return ("%.0fm"):format(tim/60)
	elseif (tim>5) then
		return ("%.0fs"):format(tim)
	elseif (tim>0) then
		return ("%.1fs"):format(tim)
	elseif (tim==0) then
		return ""
	end
end

function ForgeUI.Round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function ForgeUI.ConvertAlpha(value)	
	return string.format("%02X", math.floor(value * 255 + 0.5))
end

ForgeUIInst:Init() 
