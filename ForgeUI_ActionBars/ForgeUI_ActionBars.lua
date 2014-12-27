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
		nSelectedMount = 0,
		nSelectedPotion = 0
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
	self.wndActionBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_ActionBar", nil, self)
	self.wndStanceBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_StanceBar", nil, self)
	self.wndGadgetBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_GadgetBar", nil, self)
	self.wndPotionBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PotionBar", nil, self)
	self.wndMountBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_MountBar", nil, self)
	--self.wndRecallBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_RecallBar", nil, self)
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
	if eMouseButton ~= 1 then return end
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
	wndPopup:Show(not wndPopup:IsShown())
end

function ForgeUI_ActionBars:OnStanceBtn( wndHandler, wndControl, eMouseButton )
	self.wndStanceBar:FindChild("Popup"):Show(false)
	GameLib.SetCurrentClassInnateAbilityIndex(wndHandler:GetData())
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_PotionBar Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ActionBars:OnPotionPopup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton ~= 1 then return end
	
	local wndPotionPopout = self.wndPotionBar:FindChild("Popup")
	local wndPotionList = wndPotionPopout:FindChild("List")
	
	self:RedrawPotions()
	
	wndPotionPopout:Show(not wndPotionPopout:IsShown())
end

function ForgeUI_ActionBars:RedrawPotions()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	local wndPotionPopout = self.wndPotionBar:FindChild("Popup")
	local wndPotionList = wndPotionPopout:FindChild("List")
	wndPotionList:DestroyChildren()
	
	local tItemList = unitPlayer and unitPlayer:IsValid() and unitPlayer:GetInventoryItems() or {}
	local tSelectedPotion = nil;
	local tFirstPotion = nil
	local tPotions = { }
	
	for idx, tItemData in pairs(tItemList) do
		if tItemData and tItemData.itemInBag and tItemData.itemInBag:GetItemCategory() == 48 then--and tItemData.itemInBag:GetConsumable() == "Consumable" then
			local itemPotion = tItemData.itemInBag

			if tFirstPotion == nil then
				tFirstPotion = itemPotion
			end

			if itemPotion:GetItemId() == self.tSettings.nSelectedPotion then
				tSelectedPotion = itemPotion
			end
			
			local idItem = itemPotion:GetItemId()

			if tPotions[idItem] == nil then
				tPotions[idItem] = 
				{
					itemObject = itemPotion,
					nCount = itemPotion:GetStackCount(),
				}
			else
				tPotions[idItem].nCount = tPotions[idItem].nCount + itemPotion:GetStackCount()
			end
		end
	end
	
	local count = 0
	for idx, tData  in pairs(tPotions) do
		count = count + 1
	
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PotionBtn", wndPotionList, self)
		wndCurr:FindChild("Icon"):SetSprite(tData.itemObject:GetIcon())
		--if (tData.nCount > 1) then wndCurr:FindChild("Count"):SetText(tData.nCount) end
		wndCurr:FindChild("Button"):SetData(tData.itemObject)

		wndCurr:SetTooltipDoc(nil)
		Tooltip.GetItemTooltipForm(self, wndCurr, tData.itemObject, {})
	end

	if tSelectedPotion == nil and tFirstPotion ~= nil then
		tSelectedPotion = tFirstPotion
	end

	if tSelectedPotion ~= nil then
		GameLib.SetShortcutPotion(tSelectedPotion:GetItemId())
	end

	local nLeft, nTop, nRight, nBottom = wndPotionPopout:GetAnchorOffsets()
	wndPotionPopout:SetAnchorOffsets(nLeft, -(count * 45), nRight, nBottom)
	
	wndPotionList:ArrangeChildrenVert()
end

function ForgeUI_ActionBars:OnPotionBtn( wndHandler, wndControl, eMouseButton )
	self.tSettings.nSelectedPotion = wndControl:GetData():GetItemId()

	self.wndPotionBar:FindChild("Popup"):Show(false)
	self:RedrawPotions()
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_MountBar Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ActionBars:OnMountPopup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton ~= 1 then return end
	
	local wndMountPopout = self.wndMountBar:FindChild("Popup")
	local wndMountList = wndMountPopout:FindChild("List")
	
	self:RedrawMounts()
	
	wndMountPopout:Show(not wndMountPopout:IsShown())
end

function ForgeUI_ActionBars:RedrawMounts()
	local wndMountPopout = self.wndMountBar:FindChild("Popup")
	local wndMountList = wndMountPopout:FindChild("List")
	wndMountList:DestroyChildren()

	local tMountList = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Mount) or {}
	local tSelectedSpellObj = nil

	local count = 0
	for idx, tMountData  in pairs(tMountList) do
		count = count + 1
		
		local tSpellObject = tMountData.tTiers[1].splObject

		if tSpellObject:GetId() == self.tSettings.nSelectedMount then
			tSelectedSpellObj = tSpellObject
		end

		local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_MountBtn", wndMountList, self)
		wndCurr:FindChild("Icon"):SetSprite(tSpellObject:GetIcon())
		wndCurr:FindChild("Button"):SetData(tSpellObject)

		if Tooltip and Tooltip.GetSpellTooltipForm then
			wndCurr:SetTooltipDoc(nil)
			Tooltip.GetSpellTooltipForm(self, wndCurr, tSpellObject, {})
		end
	end

	if tSelectedSpellObj == nil and #tMountList > 0 then
		tSelectedSpellObj = tMountList[1].tTiers[1].splObject
	end

	if tSelectedSpellObj ~= nil then
		GameLib.SetShortcutMount(tSelectedSpellObj:GetId())
	end

	local nLeft, nTop, nRight, nBottom = wndMountPopout:GetAnchorOffsets()
	wndMountPopout:SetAnchorOffsets(nLeft, -(count * 45), nRight, nBottom)
	
	wndMountList:ArrangeChildrenVert()
end


function ForgeUI_ActionBars:OnMountBtn( wndHandler, wndControl, eMouseButton )
	self.tSettings.nSelectedMount = wndControl:GetData():GetId()

	self.wndMountBar:FindChild("Popup"):Show(false)
	self:RedrawMounts()
end

function ForgeUI_ActionBars:OnGenerateTooltip(wndControl, wndHandler, eType, arg1, arg2)
	local xml = nil
	if eType == Tooltip.TooltipGenerateType_ItemInstance then -- Doesn't need to compare to item equipped
		Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
	elseif eType == Tooltip.TooltipGenerateType_ItemData then -- Doesn't need to compare to item equipped
		Tooltip.GetItemTooltipForm(self, wndControl, arg1, {})
	elseif eType == Tooltip.TooltipGenerateType_GameCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Macro then
		xml = XmlDoc.new()
		xml:AddLine(arg1)
		wndControl:SetTooltipDoc(xml)
	elseif eType == Tooltip.TooltipGenerateType_Spell then
		if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
			Tooltip.GetSpellTooltipForm(self, wndControl, arg1)
		end
	elseif eType == Tooltip.TooltipGenerateType_PetCommand then
		xml = XmlDoc.new()
		xml:AddLine(arg2)
		wndControl:SetTooltipDoc(xml)
	end
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_RecallBar Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ActionBars:OnRecallPopup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
end

function ForgeUI_ActionBars:OnRecallBtn( wndHandler, wndControl, eMouseButton )
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_ActionBarsInst = ForgeUI_ActionBars:new()
ForgeUI_ActionBarsInst:Init()
