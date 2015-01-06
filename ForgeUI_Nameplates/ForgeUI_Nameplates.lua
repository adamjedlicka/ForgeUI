require "Window"
 
local ForgeUI
local ForgeUI_Nameplates = {} 
 
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

local tDispositionId = {
	[0] = "Hostile",
	[1] = "Neutral",
	[2] = "Friendly",
	[3] = "Unknown",
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

     -- mandatory 
	self.api_version = 1
	self.version = "0.0.1"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_Nameplates"
	self.strDisplayName = "Nameplates"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		nMaxRange = 75,
		bOnlyImportantNPCs = true,
		crMooBar = "FF7E00FF",
		crCastBar = "FFFEB308",
		crShieldBar = "FF0699F3",
		crBarBgColor = "FF101010",
		bUseOcclusion = true,
		nHpBarHeight = 7,
		nShieldBarHeight = 4,
		bShowShieldBars = true,
		bShowRewardIcons = true,
		tPlayer = {
			bShow = false,
			bShowBars = false,
			bShowCast = false,
			bShowClassColors = true,
			nHideBarsOver = 100,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tTarget = {
			bShow = true,
			bShowBars = true,
			bShowCast = true,
			bShowMarker = true,
			crMarker = "FFFFFFFF"
		},
		tHostile = {
			bShow = true,
			bShowBars = false,
			bShowBarsInCombat = true,
			nHideBarsOver = 100,
			bShowCast = true,
			crName = "FFD9544D",
			crBar = "FFE50000"
		},
		tNeutral = {
			bShow = true,
			bShowBars = false,
			bShowBarsInCombat = true,
			nHideBarsOver = 100,
			bShowCast = false,
			crName = "FFFFF569",
			crBar = "FFF3D829"
		},
		tFriendly = {
			bShow = true,
			bShowBars = false,
			bShowBarsInCombat = false,
			nHideBarsOver = 100,
			bShowCast = false,
			crName = "FF76CD26",
			crBar = "FF15B01A"
		},
		tUnknown = {
			bShow = false,
			bShowBars = false,
			bShowCast = false,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tFriendlyPlayer = {
			bShow = true,
			bShowBars = true,
			bShowBarsInCombat = true,
			nHideBarsOver = 100,
			bShowCast = false,
			bShowClassColors = true,
			crName = "FFFFFFFF",
			crBar = "FF15B01A"
		},
		tPartyPlayer = {
			bShow = true,
			bShowBars = true,
			bShowBarsInCombat = true,
			nHideBarsOver = 100,
			bShowCast = false,
			bShowClassColors = true,
			crName = "FF43C8F3",
			crBar = "FF15B01A"
		},
		tHostilePlayer = {
			bShow = true,
			bShowBars = true,
			bShowBarsInCombat = true,
			nHideBarsOver = 100,
			bShowCast = true,
			bShowClassColors = true,
			crName = "FFD9544D",
			crBar = "E50000"
		},
		tFriendlyPet = {
			bShow = false,
			bShowBars = false,
			nHideBarsOver = 100,
			bShowCast = false,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tPlayerPet = {
			bShow = true,
			bShowBars = false,
			nHideBarsOver = 100,
			bShowCast = false,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tHostilePet = {
			bShow = false,
			bShowBars = false,
			nHideBarsOver = 100,
			bShowCast = false,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tCollectible = {
			bShow = false,
			crName = "FFFFFFFF",
		},
		tPinataLoot = {
			bShow = false,
			crName = "FFFFFFFF",
		},
		tMount = {
			bShow = false,
			crName = "FFFFFFFF",
		},
		tSimple = {
			bShow = false,
			crName = "FFFFFFFF",
		}
	}
	
	self.unitPlayer = nil
	self.tUnits = {}
	self.tNameplates = {}
	
	self.tUnitsInQueue = {}

    return o
end

function ForgeUI_Nameplates:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:OnLoad()
    self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_Nameplates.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
end

function ForgeUI_Nameplates:ForgeAPI_AfterRegistration()
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates EventHandler
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:OnFrame()
	self.unitPlayer = GameLib.GetPlayerUnit()
	
	self:AddNewUnits()
	self:UpdateNameplates()
end

function ForgeUI_Nameplates:OnUnitCreated(unit)
	self.tUnitsInQueue[unit:GetId()] = unit
end

function ForgeUI_Nameplates:OnUnitDestroyed(unit)
	self.tUnitsInQueue[unit:GetId()] = nil
	self.tUnits[unit:GetId()] = nil
	if self.tNameplates[unit:GetId()] ~= nil then
		self.tNameplates[unit:GetId()].wndNameplate:Destroy()
	end
	self.tNameplates[unit:GetId()] = nil
end

function ForgeUI_Nameplates:OnTargetUnitChanged(unit)
	for _, tNameplate in pairs(self.tNameplates) do
		tNameplate.bIsTarget = false
	end
	
	if unit == nil then return end
	
	local tNameplate = self.tNameplates[unit:GetId()]
	if tNameplate == nil then return end
	
	if GameLib.GetTargetUnit() == unit then
		tNameplate.bIsTarget = true
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Nameplate functions
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:UpdateNameplates()
	for idx, tNameplate in pairs(self.tNameplates) do
		if self:UpdateNameplateVisibility(tNameplate) then
			tNameplate.unitType = self:GetUnitType(tNameplate.unitOwner)
			self:UpdateName(tNameplate)
			self:UpdateHealth(tNameplate)
			self:UpdateCast(tNameplate)
			self:UpdateMarker(tNameplate)
			self:UpdateArmor(tNameplate)
		end
	end
end

-- update name
function ForgeUI_Nameplates:UpdateName(tNameplate)
	local name = tNameplate.wnd.name

	name:SetText(tNameplate.unitOwner:GetName())
	name:SetTextColor(self.tSettings["t" .. tNameplate.unitType].crName)
	
	local nNameWidth = Apollo.GetTextWidth("Nameplates", tNameplate.unitOwner:GetName() .. " ")
	name:SetAnchorOffsets(- (nNameWidth / 2), 0, (nNameWidth / 2), -15)
	
	if self.tSettings.bShowRewardIcons then
		local questIcon = tNameplate.wnd.quest
		local tRewardInfo = tNameplate.unitOwner:GetRewardInfo()
		local bIsReward = false
		
		if tRewardInfo ~= nil and #tRewardInfo > 0 then
			bIsReward = true
		end
		
		if questIcon:IsShown() ~= bIsReward then
			questIcon:Show(bIsReward, true)
		end
	end
end

-- update healthbar
function ForgeUI_Nameplates:UpdateHealth(tNameplate)
	if self.tSettings["t" ..tNameplate.unitType].bShowBars == nil then 
		tNameplate.wnd.bar:Show(false, true)	
		return
	end

	local unitOwner = tNameplate.unitOwner
	local progressBar = tNameplate.wnd.hpBar
	
	if self.tSettings["t" ..tNameplate.unitType].bShowBars
		or self.tSettings["t" ..tNameplate.unitType].bShowBarsInCombat and unitOwner:IsInCombat()
		or self.tSettings.tTarget.bShowBars and tNameplate.bIsTarget then
	
		progressBar:SetMax(unitOwner:GetMaxHealth())
		progressBar:SetProgress(unitOwner:GetHealth())
		
		if ((unitOwner:GetHealth() / unitOwner:GetMaxHealth()) * 100) > self.tSettings["t" .. tNameplate.unitType].nHideBarsOver then
			tNameplate.wnd.bar:Show(false, true)
		else
			local nTime = unitOwner:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
			if nTime > 0 then
				progressBar:SetBarColor(self.tSettings.crMooBar)
			else
				if unitOwner:GetType() == "Player" and self.tSettings["t" .. tNameplate.unitType].bShowClassColors then
					progressBar:SetBarColor("FF" .. ForgeUI.GetSettings().classColors[tClassEnums[unitOwner:GetClassId()]])
				else
					progressBar:SetBarColor(self.tSettings["t" .. tNameplate.unitType].crBar)
				end
			end
			tNameplate.wnd.bar:Show(true, true)
		end
	else
		tNameplate.wnd.bar:Show(false, true)
	end
	
	if  self.tSettings.bShowShieldBars then self:UpdateShield(tNameplate) end
end

-- update shieldbar
function ForgeUI_Nameplates:UpdateShield(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local bar = tNameplate.wnd.shield
	local progressBar = tNameplate.wnd.shieldBar
	
	local bShow = false
	local nMax = unitOwner:GetShieldCapacityMax()
	local nValue = unitOwner:GetShieldCapacity()
	
	if nValue ~= 0 then
		progressBar:SetMax(nMax)
		progressBar:SetProgress(nValue)
		
		bShow = true
	end
	
	if bar:IsShown() ~= bShow then
		bar:Show(bShow, true)
		self:UpdateStyle(tNameplate)
	end
end

-- update castbar
function ForgeUI_Nameplates:UpdateCast(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local progressBar = tNameplate.wnd.castBar
	
	if self.tSettings["t" ..tNameplate.unitType].bShowCast or self.tSettings.tTarget.bShowCast and tNameplate.bIsTarget then
		if unitOwner:ShouldShowCastBar() then
			local fDuration = unitOwner:GetCastDuration()
			local fElapsed = unitOwner:GetCastElapsed()	
			local strSpellName = unitOwner:GetCastName()
		
			tNameplate.wnd.castText:SetText(strSpellName)
			progressBar:SetMax(fDuration)
			progressBar:SetProgress(fDuration - fElapsed)
			
			tNameplate.wnd.cast:Show(true, true)
		else
			tNameplate.wnd.cast:Show(false, true)
		end
	else
		tNameplate.wnd.cast:Show(false, true)
	end
end

-- update marker
function ForgeUI_Nameplates:UpdateMarker(tNameplate)
	local wnd = tNameplate.wnd

	local bShow = tNameplate.bIsTarget and self.tSettings.tTarget.bShowMarker
	
	if wnd.marker:IsShown() ~= bShow
		then wnd.marker:Show(bShow, true)
	end
end

function ForgeUI_Nameplates:UpdateArmor(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local ia = tNameplate.wnd.ia
	local iaText = tNameplate.wnd.iaText
	
	nValue = unitOwner:GetInterruptArmorValue()
	nMax = unitOwner:GetInterruptArmorMax()
	if nMax == 0 or nValue == nil or unitOwner:IsDead() then
		ia:Show(false, true)
	else
		ia:Show(true, true)
		if nMax == -1 then
			ia:SetSprite("HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Infinite")
			iaText:SetText("")
		elseif nMax > 0 then
			ia:SetSprite("HUD_TargetFrame:spr_TargetFrame_InterruptArmor_Value")
			iaText:SetText(nValue)
		end
	end
end


-- visibility check
function ForgeUI_Nameplates:UpdateNameplateVisibility(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate
	
	tNameplate.bOnScreen = wndNameplate:IsOnScreen()
	tNameplate.bOccluded = wndNameplate:IsOccluded()
	
	local bVisible = tNameplate.bOnScreen
	if bVisible then bVisible = self.tSettings["t" .. tNameplate.unitType].bShow end
	if bVisible then bVisible = self:IsNameplateInRange(tNameplate) end
	if bVisible and self.tSettings.bOnlyImportantNPCs and tNameplate.unitType == "Friendly" then bVisible = tNameplate.bIsImportant end
	if bVisible and self.tSettings.bUseOcclusion then bVisible = not tNameplate.bOccluded end
	if bVisible then bVisible = not unitOwner:IsDead() end
	
	if not bVisible then bVisible = self.tSettings.tTarget.bShow and tNameplate.bIsTarget end
	
	if bVisible ~= tNameplate.bShow then
		wndNameplate:Show(bVisible, true)
		tNameplate.bShow = bVisible
	end
	
	return bVisible
end

function ForgeUI_Nameplates:UpdateStyle(tNameplate)
	local wnd = tNameplate.wnd
	
	wnd.hp:FindChild("Background"):SetBGColor(self.tSettings.crBarBgColor)
	wnd.shield:FindChild("Background"):SetBGColor(self.tSettings.crBarBgColor)
	wnd.shieldBar:SetBarColor(self.tSettings.crShieldBar)
	wnd.castBar:SetBarColor(self.tSettings.crCastBar)
	wnd.cast:FindChild("Background"):SetBGColor(self.tSettings.crBarBgColor)
	wnd.marker:SetBGColor(self.tSettings.tTarget.crMarker)
	
	local nLeft, nTop, nRight, nBottom = wnd.bar:GetAnchorOffsets()
	if tNameplate.wnd.shield:IsShown() then
		wnd.bar:SetAnchorOffsets(nLeft, nTop, nRight, nTop + self.tSettings.nHpBarHeight + self.tSettings.nShieldBarHeight - 1)
		wnd.hp:SetAnchorOffsets(0, 0, 0, self.tSettings.nHpBarHeight)
		wnd.shield:SetAnchorOffsets(0, - self.tSettings.nShieldBarHeight, 0, 0)
	else
		wnd.bar:SetAnchorOffsets(nLeft, nTop, nRight, nTop + self.tSettings.nHpBarHeight)
		wnd.hp:SetAnchorOffsets(0, 0, 0, self.tSettings.nHpBarHeight)
	end
end

function ForgeUI_Nameplates:IsNameplateInRange(tNameplate)
	local unitPlayer = self.unitPlayer
	local unitOwner = tNameplate.unitOwner

	if not unitOwner or not unitPlayer then
	    return false
	end

	local tPosTarget = unitOwner:GetPosition()
	local tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil or tPosPlayer == nil then
		return
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = (nDeltaX * nDeltaX) + (nDeltaY * nDeltaY) + (nDeltaZ * nDeltaZ)

	if tNameplate.bIsTarget then
		bInRange = nDistance < 40000
		return bInRange
	else
		bInRange = nDistance < (self.tSettings.nMaxRange * self.tSettings.nMaxRange) -- squaring for quick maths
		return bInRange
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Nameplate update functions
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:GetUnitType(unit)
	if unit == nil or not unit:IsValid() then return end

	local eDisposition = unit:GetDispositionTo(self.unitPlayer)
	
	if unit:IsThePlayer() then
		return "Player"
	elseif unit:GetType() == "Player" then
		if eDisposition == 0 then
			return "HostilePlayer"
		else
			if unit:IsInYourGroup() then
				return "PartyPlayer"
			else
				return "FriendlyPlayer"
			end
		end
	elseif unit:GetType() == "Collectible" then
		return "Collectible"
	elseif unit:GetType() == "PinataLoot" then
		return "PinataLoot"
	elseif unit:GetType() == "Pet" then
		local petOwner = unit:GetUnitOwner()
	
		if eDisposition == 0 then
			return "HostilePet"
		elseif petOwner ~= nil and petOwner:IsThePlayer() then
			return "PlayerPet"
		else
			return "FriendlyPet"
		end
	elseif unit:GetType() == "Mount" then
		return "Mount"
	elseif unit:GetHealth() == nil and not unit:IsDead() then
		return "Simple"
	else
		return tDispositionId[eDisposition]
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Unit functions
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:AddNewUnits()
	for idx, unit in pairs(self.tUnitsInQueue) do
		if unit == nil 
			or not unit:IsValid() 
			or self.tUnits[idx] ~= nil
		then
			self.tUnitsInQueue[idx] = nil
			return
		end
		
		self.tUnitsInQueue[idx] = nil
		
		self.tUnits[idx] = unit
		self:GenerateNewNameplate(unit)
	end
end

function ForgeUI_Nameplates:GenerateNewNameplate(unitNew)
	local wnd = Apollo.LoadForm(self.xmlDoc, "ForgeUI_Nameplate", "InWorldHudStratum", self)
	
	wnd:SetUnit(unitNew, 1)
	
	local tNameplate = {
		unitOwner 		= unitNew,
		idUnit 			= idUnit,
		unitType 		= self:GetUnitType(unitNew),
		wndNameplate	= tmpWnd,
		wndMeasure		= nil,
		bOnScreen 		= wnd:IsOnScreen(),
		bOccluded 		= wnd:IsOccluded(),
		bSpeechBubble 	= false,
		bIsTarget 		= false,
		bGibbed			= false,
		nVulnerableTime = 0,
		eDisposition	= unitNew:GetDispositionTo(self.unitPlayer),
		bIsImportant	= self:IsImportantNPC(unitNew),
		bShow			= false,
		wndNameplate 	= wnd,
		wnd = {
			name = wnd:FindChild("Name"),
			bar = wnd:FindChild("Bar"),
			hp = wnd:FindChild("HPBar"),
			hpBar = wnd:FindChild("HPBar"):FindChild("ProgressBar"),
			shield = wnd:FindChild("ShieldBar"),
			shieldBar = wnd:FindChild("ShieldBar"):FindChild("ProgressBar"),
			cast = wnd:FindChild("CastBar"),
			castBar = wnd:FindChild("CastBar"):FindChild("ProgressBar"),
			castText = wnd:FindChild("CastBar"):FindChild("Text"),
			marker = wnd:FindChild("Marker"),
			ia = wnd:FindChild("IA"),
			iaText = wnd:FindChild("IAText"),
			quest = wnd:FindChild("QuestIndicator")
		}
	}
	
	if self.tSettings["t" .. tNameplate.unitType].bShow then
		--if tNameplate.unitType == "Friendly" and not self:IsImportantNPC(unitNew) and self.tSettings.bOnlyImportantNPCs then
		--	wnd:Destroy()
		--	return
		--end
		
		tNameplate.wnd.shield:Show(self.tSettings.bShowShieldBars, true)
		
		self:UpdateStyle(tNameplate)
		
		self.tNameplates[unitNew:GetId()] = tNameplate
		
		return tNameplate
	else
		wnd:Destroy()
		return
	end
end

function ForgeUI_Nameplates:IsImportantNPC(unitOwner)
	local tActivation = unitOwner:GetActivationState()
	
	--Units without health
	if tActivation.Bank ~= nil then
		return true
	elseif tActivation.CREDDExchange then
		return true
	end

	--Flight paths
	if tActivation.FlightPathSettler ~= nil or tActivation.FlightPath ~= nil or tActivation.FlightPathNew then
		return true
	end
	
	--Quests
	if tActivation.QuestReward ~= nil then
		return true
	elseif tActivation.QuestNew ~= nil or tActivation.QuestNewMain ~= nil then
		return true
	elseif tActivation.QuestReceiving ~= nil then
		return true
	elseif tActivation.QuestNewDaily ~= nil then
		return true
	elseif tActivation.TalkTo ~= nil then
		return true
	end
	
	--Vendors
	if tActivation.CommodityMarketplace ~= nil then
		return true
	elseif tActivation.ItemAuctionhouse then
		return true
	elseif tActivation.Vendor then
		return true
	end
	
	--Trainers
	if tActivation.TradeskillTrainer then
		return true
	end
	
	-- Magic!
	if tActivation.Spell then
		return true
	end
end

function ForgeUI_Nameplates:OnNameplateClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl:GetName() == "Bar" or wndControl:GetName() == "Name" then
		GameLib.SetTargetUnit(wndControl:GetParent():GetUnit())
	elseif wndControl:GetName() == "HPBar" or wndControl:GetName() == "ShieldBar" then
		GameLib.SetTargetUnit(wndControl:GetParent():GetParent():GetUnit())
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_NameplatesInst = ForgeUI_Nameplates:new()
ForgeUI_NameplatesInst:Init()
