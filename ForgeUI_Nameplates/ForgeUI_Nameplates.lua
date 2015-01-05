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
		bUseOcclusion = true,
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
			bShowMarker = true
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
			bShowCast = false,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tPlayerPet = {
			bShow = true,
			bShowBars = true,
			bShowCast = false,
			crName = "FFFFFFFF",
			crBar = "FFFFFFFF"
		},
		tHostilePet = {
			bShow = false,
			bShowBars = false,
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
	
	--if self.unitPlayer:GetTarget() ~= nil then
	--	for k, v in pairs(self.unitPlayer:GetTarget():GetActivationState()) do
	--		Print(k)
	--	end
	--end
	
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

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Nameplate functions
-----------------------------------------------------------------------------------------------
function ForgeUI_Nameplates:UpdateNameplates()
	for idx, tNameplate in pairs(self.tNameplates) do
		if tNameplate.unitOwner:IsDead() then
			self:OnUnitDestroyed(tNameplate.unitOwner)
			return
		end
		
		--if tNameplate.unitOwner == self.unitPlayer:GetTarget() then
		--	tNameplate.wnd.marker:Show(self.tSettings.tTarget.bShowMarker)
		--	tNameplate.bIsTarget = true
		--else
		--	tNameplate.wnd.marker:Show(false)
		--	tNameplate.bIsTarget = false
		--end
	
		tNameplate.unitType = self:GetUnitType(tNameplate.unitOwner)
		self:UpdateName(tNameplate)
		self:UpdateHealth(tNameplate)
		self:UpdateCast(tNameplate)
	
		self:UpdateNameplateVisibility(tNameplate)
	end
end

function ForgeUI_Nameplates:UpdateName(tNameplate)
	tNameplate.wnd.name:SetText(tNameplate.unitOwner:GetName())
	tNameplate.wnd.name:SetTextColor(self.tSettings["t" .. tNameplate.unitType].crName)
end

function ForgeUI_Nameplates:UpdateHealth(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local progressBar = tNameplate.wnd.hpBar
	
	if self.tSettings["t" ..tNameplate.unitType].bShowBars or self.tSettings["t" ..tNameplate.unitType].bShowBarsInCombat and unitOwner:IsInCombat() then
	
		progressBar:SetMax(unitOwner:GetMaxHealth())
		progressBar:SetProgress(unitOwner:GetHealth())
		
		if ((unitOwner:GetHealth() / unitOwner:GetMaxHealth()) * 100) > self.tSettings["t" .. tNameplate.unitType].nHideBarsOver then
			tNameplate.wnd.hp:Show(false)
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
			tNameplate.wnd.hp:Show(true)
		end
	else
		tNameplate.wnd.hp:Show(false)
	end
end

function ForgeUI_Nameplates:UpdateCast(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local progressBar = tNameplate.wnd.castBar
	
	if self.tSettings["t" ..tNameplate.unitType].bShowCast then
		if unitOwner:IsCasting() then
			local fDuration = unitOwner:GetCastDuration()
			local fElapsed = unitOwner:GetCastElapsed()	
			local strSpellName = unitOwner:GetCastName()
		
			tNameplate.wnd.castText:SetText(strSpellName)
			progressBar:SetMax(fDuration)
			progressBar:SetProgress(fDuration - fElapsed)
			
			tNameplate.wnd.cast:Show(true)
		else
			tNameplate.wnd.cast:Show(false)
		end
	else
		tNameplate.wnd.cast:Show(false)
	end
end

function ForgeUI_Nameplates:UpdateNameplateVisibility(tNameplate)
	local unitOwner = tNameplate.unitOwner
	local wndNameplate = tNameplate.wndNameplate
	
	tNameplate.bOnScreen = wndNameplate:IsOnScreen()
	tNameplate.bOccluded = wndNameplate:IsOccluded()
	tNameplate.eDisposition = unitOwner:GetDispositionTo(self.unitPlayer)
	
	local bVisible = tNameplate.bOnScreen
	if bVisible then bVisible = self.tSettings["t" .. tNameplate.unitType].bShow end
	if bVisible then bVisible = self:IsNameplateInRange(tNameplate) end
	if bVisible and self.tSettings.bOnlyImportantNPCs and tNameplate.unitType == "Friendly" then bVisible = tNameplate.bIsImportant end
	if bVisible and self.tSettings.bUseOcclusion then bVisible = not tNameplate.bOccluded end
	
	if bVisible ~= tNameplate.bShow then
		wndNameplate:Show(bVisible)
		tNameplate.bShow = bVisible
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
		bInRange = nDistance < knTargetRange
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
			hp = wnd:FindChild("HPBar"),
			hpBar = wnd:FindChild("HPBar"):FindChild("ProgressBar"),
			cast = wnd:FindChild("CastBar"),
			castBar = wnd:FindChild("CastBar"):FindChild("ProgressBar"),
			castText = wnd:FindChild("CastBar"):FindChild("Text"),
			marker = wnd:FindChild("Marker")
		}
	}
	
	if self.tSettings["t" .. tNameplate.unitType].bShow then
		tNameplate.wnd.castBar:SetBarColor(self.tSettings.crCastBar)
	
		self.tNameplates[unitNew:GetId()] = tNameplate
	end
	
	return tNameplate
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
	GameLib.SetTargetUnit(wndHandler:GetParent():GetUnit())
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_Nameplates Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_NameplatesInst = ForgeUI_Nameplates:new()
ForgeUI_NameplatesInst:Init()
