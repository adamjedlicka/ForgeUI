require "Window"
 
local ForgeUI
local ForgeUI_MiniMap = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ForgeUI_MiniMap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	self.tUnitsInQueue = {}

	Apollo.RegisterEventHandler("UnitCreated", 		"OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", 	"OnUnitDestroyed", self)

    -- mandatory 
    self.api_version = 1
	self.version = "0.1.0"
	self.author = "WintyBadass"
	self.strAddonName = "ForgeUI_MiniMap"
	self.strDisplayName = "MiniMap"
	
	self.wndContainers = {}
	
	-- optional
	self.tSettings = {
		nZoomLevel = 1,
		tMarkers = {
			FriendlyPlayer = { bShown = true, strIcon = "ClientSprites:MiniMapFriendDiamond", crObject = "FF006CFF" },
			HostilePlayer = { bShown = true, strIcon = "ClientSprites:MiniMapFriendDiamond", crObject = "FFFF0000" },
			Hostile = { bShown = true, crObject = "FFFF0000" },
			Neutral = { bShown = true, crObject = "FFFFCC00" }
		}
	}
	
	self.tUnits = {
		tPlayers = {},
		tNonPlayers = {}
	}

	return o
end

function ForgeUI_MiniMap:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ForgeUI"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ForgeUI_MiniMap OnLoad
-----------------------------------------------------------------------------------------------
function ForgeUI_MiniMap:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ForgeUI_MiniMap.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ForgeUI_MiniMap:OnGenerateTooltip(wndHandler, wndControl, eType, nX, nY)
	if eType ~= Tooltip.TooltipGenerateType_Map then
		wndControl:SetTooltipDoc(nil)
		return
	end
	
	local xml = XmlDoc.new()
	xml:StartTooltip(Tooltip.TooltipWidth)
	
	local nCount = 0
	local tMapObjects = self.wndMiniMap:GetObjectsAtPoint(nX, nY)
	for ids, mapObject in pairs(tMapObjects) do
		nCount = nCount + 1
		xml:AddLine(mapObject.unit:GetName(), crWhite, "CRB_InterfaceMedium")
	end
	
	if nCount > 0 then
		wndControl:SetTooltipDoc(xml)
	else
		wndControl:SetTooltipDoc(nil)
	end
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_MiniMap OnDocLoaded
-----------------------------------------------------------------------------------------------
function ForgeUI_MiniMap:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end
	
	if ForgeUI == nil then -- forgeui loaded
		ForgeUI = Apollo.GetAddon("ForgeUI")
	end
	
	ForgeUI.RegisterAddon(self)
	
	Apollo.RegisterTimerHandler("TimeUpdateTimer", 	"OnUpdateTimer", self)
end

function ForgeUI_MiniMap:ForgeAPI_AfterRegistration()
	Apollo.LoadSprites("SquareMapTextures_NoCompass.xml")

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "ForgeUI_MiniMap", "FixedHudStratumLow", self)
	self.wndMiniMap = self.wndMain:FindChild("MiniMapWindow")
	
	self.wndMovables = Apollo.LoadForm(self.xmlDoc, "ForgeUI_Movables", nil, self)
	
	self:HandleNewUnits()
end

function ForgeUI_MiniMap:OnUpdateTimer()
	self:HandleNewUnits()

	self:UpdateZoneName()

	local l_time = GameLib.GetLocalTime()
	self.wndMain:FindChild("Clock"):SetText(string.format("%02d:%02d", l_time.nHour, l_time.nMinute))
end

function ForgeUI_MiniMap:OnUnitCreated(unit)
	if unit == nil or not unit:IsValid() or unit == GameLib.GetPlayerUnit() then return end

	self.tUnitsInQueue[unit:GetId()] = unit
end

function ForgeUI_MiniMap:OnUnitDestroyed(unit)
	if unit == nil or not unit:IsValid() then return end
	
	if unit:GetType() == "Player" then
		self.tUnits.tPlayers[unit:GetId()] = nil
	elseif unit:GetType() == "NonPlayer" then
		self.tUnits.tNonPlayers[unit:GetId()] = nil
	end
end

function ForgeUI_MiniMap:HandleNewUnits()
	for idx, unit in pairs(self.tUnitsInQueue) do
		self.tUnitsInQueue[idx] = nil
		if unit == nil or not unit:IsValid() then return end
	
		if unit:GetType() == "Player" then
			self.tUnits.tPlayers[unit:GetId()] = unit
			
			local tInfo = self:GetDefaultMarker(unit)
			
			local eDispotition = unit:GetDispositionTo(GameLib.GetPlayerUnit())
			if eDispotition == Unit.CodeEnumDisposition.Hostile then
				local tMarker = self.tSettings.tMarkers.HostilePlayer
				if tMarker.bShown == false then return end
				
				if tMarker.strIcon then
					tInfo.strIcon = tMarker.strIcon 
				end
				if tMarker.strIconEdge then
					tInfo.strIconEdge = tMarker.strIconEdge 
				end
				if tMarker.crObject then
					tInfo.crObject = tMarker.crObject
				end
				if tMarker.crEdge then
					tInfo.crEdge = tMarker.crEdge 
				end
				
			elseif eDispotition == Unit.CodeEnumDisposition.Friendly then
				local tMarker = self.tSettings.tMarkers.FriendlyPlayer
				if tMarker.bShown == false then return end
				
				if tMarker.strIcon then
					tInfo.strIcon = tMarker.strIcon 
				end
				if tMarker.strIconEdge then
					tInfo.strIconEdge = tMarker.strIconEdge 
				end
				if tMarker.crObject then
					tInfo.crObject = tMarker.crObject
				end
				if tMarker.crEdge then
					tInfo.crEdge = tMarker.crEdge 
				end	
			end
			
			self.wndMiniMap:AddUnit(unit, nil, tInfo, {}, false)
		elseif unit:GetType() == "NonPlayer" then
			self.tUnits.tPlayers[unit:GetId()] = unit
		
			local tTypes = unit:GetMiniMapMarkers()
			for idx, type in pairs(tTypes) do
				if self.tSettings.tMarkers[type] and self.tSettings.tMarkers[type].bShown == true then
			
					local tInfo = self:GetDefaultMarker(unit)
				
					tMarker = self.tSettings.tMarkers[type]
					if tMarker.strIcon then
						tInfo.strIcon = tMarker.strIcon 
					end
					if tMarker.strIconEdge then
						tInfo.strIconEdge = tMarker.strIconEdge 
					end
					if tMarker.crObject then
						tInfo.crObject = tMarker.crObject
					end
					if tMarker.crEdge then
						tInfo.crEdge = tMarker.crEdge 
					end
					
					self.wndMiniMap:AddUnit(unit, tMarker.objectType, tInfo, {}, false)
				end
			end
		end
	end
end

function ForgeUI_MiniMap:GetDefaultMarker(unit)
	local tInfo = {
		strIcon = "ClientSprites:MiniMapMarkerTiny",
		strIconEdge = "",
		crObject = "FFFFFFFF",
		crEdge = "FFFFFFFF",
		bAboveOverlay = false
	}
	
	return tInfo
end

function ForgeUI_MiniMap:UpdateZoneName()
	local strZoneName = GetCurrentZoneName()
	
	local tInstanceSettingsInfo = GameLib.GetInstanceSettings()

	local strDifficulty = nil
	if tInstanceSettingsInfo.eWorldDifficulty == GroupLib.Difficulty.Veteran then
		strDifficulty = ktInstanceSettingTypeStrings.Veteran
	end

	local strScaled = nil
	if tInstanceSettingsInfo.bWorldForcesLevelScaling == true then
		strScaled = ktInstanceSettingTypeStrings.Rallied
	end

	local strAdjustedZoneName = strZoneName
	if strDifficulty and strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. "-" .. strScaled .. ")"
	elseif strDifficulty then
		strAdjustedZoneName = strZoneName .. " (" .. strDifficulty .. ")"
	elseif strScaled then
		strAdjustedZoneName = strZoneName .. " (" .. strScaled .. ")"
	end

	self.wndMain:FindChild("ZoneName"):SetText(strAdjustedZoneName or "Unknown")
end

-- restore / save

function ForgeUI_MiniMap:ForgeAPI_AfterRestore()
	ForgeUI.RegisterWindowPosition(self, self.wndMain, "ForgeUI_MiniMap", self.wndMovables:FindChild("Movable_MiniMap"))

	self.wndMiniMap:SetZoomLevel(self.tSettings.nZoomLevel)
	
	-- build minimap window
	local l_time = GameLib.GetLocalTime()
	self.wndMain:FindChild("Clock"):SetText(string.format("%02d:%02d", l_time.nHour, l_time.nMinute))
	self:UpdateZoneName()
end

function ForgeUI_MiniMap:ForgeAPI_BeforeSave()
	self.tSettings.nZoomLevel = self.wndMiniMap:GetZoomLevel()
end

---------------------------------------------------------------------------------------------------
-- ForgeUI_Movables Functions
---------------------------------------------------------------------------------------------------

function ForgeUI_MiniMap:OnMovableMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndMain:SetAnchorOffsets(self.wndMovables:FindChild("Movable_MiniMap"):GetAnchorOffsets())
end

-----------------------------------------------------------------------------------------------
-- ForgeUI_MiniMap Instance
-----------------------------------------------------------------------------------------------
local ForgeUI_MiniMapInst = ForgeUI_MiniMap:new()
ForgeUI_MiniMapInst:Init()
