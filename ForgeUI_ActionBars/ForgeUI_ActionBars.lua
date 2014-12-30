require "Window"
require "AbilityBook"
require "GameLib"
require "PlayerPathLib"
require "Tooltip"
require "Unit"
 
-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars Module Definition
-----------------------------------------------------------------------------------------------
local ForgeUI
local ForgeUI_ActionBars = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local knPathLASIndex = 10

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
	self.wndRecallBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_RecallBar", nil, self)
	self.wndPathBar = Apollo.LoadForm(self.xmlDoc, "ForgeUI_PathBar", nil, self)
	
	Apollo.RegisterEventHandler("AbilityBookChange", "RedrawActionBars", self)
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
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	else
		Apollo.RegisterEventHandler("CharacterCreated", 	"OnCharacterCreated", self)
	end
end

function ForgeUI_ActionBars:OnCharacterCreated()
	self:RedrawActionBars()
end

function ForgeUI_ActionBars:RedrawActionBars()
	self:RedrawRecalls()
	self:RedrawPath()
	self:RedrawMounts()
	self:RedrawPotions()
	self:RedrawStances()
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_InnateBar Functions
---------------------------------------------------------------------------------------------------
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
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellBtn", wndList, self)
			wndCurr:SetData({sType = "stance"})
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

function ForgeUI_ActionBars:RedrawStances()
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
	
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellBtn", wndPotionList, self)
		wndCurr:SetData({sType = "potion"})
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
	
	--self.wndPotionBar:Show(count > 0)
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

		local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellBtn", wndMountList, self)
		wndCurr:SetData({sType = "mount"})
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
	
	self.wndMountBar:Show(count > 0)
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_RecallBar Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ActionBars:OnRecallPopup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton ~= 1 then return end
	local wndPopup = wndHandler:FindChild("Popup")
	local wndList = wndPopup:FindChild("List")

	wndPopup:Show(not wndPopup:IsShown())
end

function ForgeUI_ActionBars:OnRecallEntry( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton == 1 then
		GameLib.SetDefaultRecallCommand(wndControl:FindChild("RecallActionBtn"):GetData())
		self.wndRecallBar:FindChild("ActionBarButton"):SetContentId(wndControl:FindChild("RecallActionBtn"):GetData())
	end
	self.wndRecallBar:FindChild("Popup"):Show(false, true)
end

function ForgeUI_ActionBars:RedrawRecalls()
	local wndPopup = self.wndRecallBar:FindChild("Popup")
	local wndList = self.wndRecallBar:FindChild("Popup")

	wndList:DestroyChildren()
	
	local nEntryHeight = 0
	local bHasBinds = false
	local bHasWarplot = false
	local guildCurr = nil
	
	-- todo: condense this 
	if GameLib.HasBindPoint() == true then
		--load recall
		local wndBind = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellActionBtn", wndList, self)
		wndBind:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.BindPoint)
		wndBind:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.BindPoint)
		
		bHasBinds = true
		nEntryHeight = nEntryHeight + 1
	end
	
	if HousingLib.IsResidenceOwner() == true then
		-- load house
		local wndHouse = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellActionBtn", wndList, self)
		wndHouse:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.House)
		wndHouse:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.House)
		
		bHasBinds = true
		nEntryHeight = nEntryHeight + 1		
	end

	-- Determine if this player is in a WarParty
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do
		if guildCurr:GetType() == GuildLib.GuildType_WarParty then
			bHasWarplot = true
			break
		end
	end
	
	if bHasWarplot == true then
		-- load warplot
		local wndWarplot = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellActionBtn", wndList, self)
		wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Warplot)
		wndWarplot:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.Warplot)
		
		bHasBinds = true
		nEntryHeight = nEntryHeight + 1	
	end
	
	local bIllium = false
	local bThayd = false
	
	for idx, tSpell in pairs(AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Misc) or {}) do
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportIlliumSpell():GetBaseSpellId() then
			bIllium = true
		end
		if tSpell.bIsActive and tSpell.nId == GameLib.GetTeleportThaydSpell():GetBaseSpellId() then
			bThayd = true
		end
	end
	
	if bIllium then
		-- load capital
		local wndWarplot = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellActionBtn", wndList, self)
		wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Illium)
		wndWarplot:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.Illium)
		
		bHasBinds = true
		nEntryHeight = nEntryHeight + 1
	end
	
	if bThayd then
		-- load capital
		local wndWarplot = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellActionBtn", wndList, self)
		wndWarplot:FindChild("RecallActionBtn"):SetContentId(GameLib.CodeEnumRecallCommand.Thayd)
		wndWarplot:FindChild("RecallActionBtn"):SetData(GameLib.CodeEnumRecallCommand.Thayd)		
		
		bHasBinds = true
		nEntryHeight = nEntryHeight + 1
	end
	
	local nLeft, nTop, nRight, nBottom = wndPopup:GetAnchorOffsets()
	wndPopup:SetAnchorOffsets(nLeft, -(nEntryHeight * 45), nRight, nBottom)
	
	wndList:ArrangeChildrenVert(0)
	
	self.wndRecallBar:Show(bHasBinds, true)
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_PathBar Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_ActionBars:OnPathPopup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if eMouseButton ~= 1 then return end
	local wndPopup = wndHandler:FindChild("Popup")
	local wndList = wndPopup:FindChild("List")
	
	wndList:ArrangeChildrenVert(0)
	wndPopup:Show(not wndPopup:IsShown())
end

function ForgeUI_ActionBars:RedrawPath()
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end

	local tAbilities = AbilityBook.GetAbilitiesList(Spell.CodeEnumSpellTag.Path)
	if not tAbilities then
		return	
	end

	local wndPopup = self.wndPathBar:FindChild("Popup")
	local wndList = self.wndPathBar:FindChild("List")
	
	wndList:DestroyChildren()
	
	local nCount = 0
	local nListHeight = 0
	for _, tAbility in pairs(tAbilities) do
		if tAbility.bIsActive then
			nCount = nCount + 1
			local spellObject = tAbility.tTiers[tAbility.nCurrentTier].splObject
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ForgeUI_SpellBtn", wndList, self)
			wndCurr:SetData({sType = "path"})
			wndCurr:FindChild("Icon"):SetSprite(spellObject:GetIcon())
			wndCurr:FindChild("Button"):SetData(tAbility.nId)
			
			if Tooltip and Tooltip.GetSpellTooltipForm then
				wndCurr:SetTooltipDoc(nil)
				Tooltip.GetSpellTooltipForm(self, wndCurr, spellObject)
			end
		end
	end
	
	self.wndPathBar:Show(nCount > 0)
	
	local nLeft, nTop, nRight, nBottom = wndPopup:GetAnchorOffsets()
	wndPopup:SetAnchorOffsets(nLeft, -(nCount * 45), nRight, nBottom)
	
	wndList:ArrangeChildrenVert(0)
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

function ForgeUI_ActionBars:OnSpellBtn( wndHandler, wndControl, eMouseButton )
	local sType = wndControl:GetParent():GetData().sType
	if sType == "stance" then
		self.wndStanceBar:FindChild("Popup"):Show(false)
		GameLib.SetCurrentClassInnateAbilityIndex(wndHandler:GetData())
		
		self.wndStanceBar:FindChild("Popup"):Show(false, true)
	elseif sType == "mount" then
		self.tSettings.nSelectedMount = wndControl:GetData():GetId()
	
		self.wndMountBar:FindChild("Popup"):Show(false)
		self:RedrawMounts()
		
		self.wndMountBar:FindChild("Popup"):Show(false, true)
	elseif sType == "potion" then
		self.tSettings.nSelectedPotion = wndControl:GetData():GetItemId()

		self.wndPotionBar:FindChild("Popup"):Show(false)
		self:RedrawPotions()
		
		self.wndPotionBar:FindChild("Popup"):Show(false, true)
	elseif sType == "path" then
		local tActionSet = ActionSetLib.GetCurrentActionSet()
		
		Event_FireGenericEvent("PathAbilityUpdated", wndControl:GetData())
		tActionSet[knPathLASIndex] = wndControl:GetData()
		ActionSetLib.RequestActionSetChanges(tActionSet)
		self:RedrawPath()
		
		self.wndPathBar:FindChild("Popup"):Show(false, true)
	end
end

function ForgeUI_ActionBars:ForgeAPI_AfterRestore()
	GameLib.SetDefaultRecallCommand(GameLib.GetDefaultRecallCommand())
	self.wndRecallBar:FindChild("ActionBarButton"):SetContentId(GameLib.GetDefaultRecallCommand())
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_ActionBars Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_ActionBarsInst = ForgeUI_ActionBars:new()
ForgeUI_ActionBarsInst:Init()
