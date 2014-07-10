-----------------------------------------------------------------------------------------------
-- Client Lua Script for BGChron
-- by orbv - Bloodsworn - Dominion
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"

-----------------------------------------------------------------------------------------------
-- BGChron Module Definition
-----------------------------------------------------------------------------------------------
local BGChron = { 
	db, 
	bgchrondb, 
	currentMatch
} 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local ktSupportedTypes = {
	[MatchingGame.RatingType.Arena2v2]          = true,
	[MatchingGame.RatingType.Arena3v3]          = true,
	[MatchingGame.RatingType.Arena5v5]          = true,
	[MatchingGame.RatingType.RatedBattleground] = true 
}

local tArenaFilters = {
  All    = 0,
  Twos   = 2,
  Threes = 3,
  Fives  = 5
}

local ktRatingTypeToMatchType = 
{ 
	[MatchingGame.RatingType.Arena2v2]          = MatchingGame.MatchType.Arena, 
	[MatchingGame.RatingType.Arena3v3]          = MatchingGame.MatchType.Arena, 
	[MatchingGame.RatingType.Arena5v5]          = MatchingGame.MatchType.Arena, 
	[MatchingGame.RatingType.RatedBattleground] = MatchingGame.MatchType.RatedBattleground, 
	--[MatchingGame.RatingType.Warplot]           = MatchingGame.MatchType.Warplot
}

local ktMatchTypes =
{
	[MatchingGame.MatchType.Battleground]      = "Battleground",
	[MatchingGame.MatchType.Arena]             = "Rated Arena",
	--[MatchingGame.MatchType.Warplot]           = "Warplot",
	[MatchingGame.MatchType.RatedBattleground] = "Rated Battleground",
	[MatchingGame.MatchType.OpenArena]         = "Arena"
}

local ktPvPEvents =
{
  [PublicEvent.PublicEventType_PVP_Arena]                     = true,
  [PublicEvent.PublicEventType_PVP_Warplot]                   = true,
  [PublicEvent.PublicEventType_PVP_Battleground_Vortex]       = true,
  [PublicEvent.PublicEventType_PVP_Battleground_Cannon]       = true,
  [PublicEvent.PublicEventType_PVP_Battleground_Sabotage]     = true,
  [PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]  = true,
}

local eResultTypes = {
	Win     = 0,
	Loss    = 1,
	Forfeit = 2
}

local ktMatchTypeToGridName = {
  [MatchingGame.MatchType.Battleground]      = "BGGrid",
  [MatchingGame.MatchType.Arena]             = "RArenaGrid",
  [MatchingGame.MatchType.RatedBattleground] = "RBGGrid",
  [MatchingGame.MatchType.OpenArena]         = "ArenaGrid"
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BGChron:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 
	return o
end

function BGChron:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)

  -- DEBUG: Used for intro message
  self.bIntroShown = false

	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self)
end


-----------------------------------------------------------------------------------------------
-- BGChron OnLoad
-----------------------------------------------------------------------------------------------
function BGChron:OnLoad()
  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("BGChron.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)

  if self.db.char.BGChron == nil then
  	self.db.char.BGChron = {}
  end

  self.bgchrondb = self.db.char.BGChron
end

-----------------------------------------------------------------------------------------------
-- BGChron OnDocLoaded
-----------------------------------------------------------------------------------------------
function BGChron:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "BGChronForm", nil, self)
    self.wndMatchForm = Apollo.LoadForm(self.xmlDoc, "BGChronMatchForm", nil, self)
		if self.wndMain == nil or self.wndMatchForm == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndMain:Show(false, true)
    self.wndMatchForm:Show(false)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("bgchronclear",     	  "OnBGChronClear", self)
		Apollo.RegisterSlashCommand("bgchron",              "OnBGChronOn", self)
		Apollo.RegisterEventHandler("MatchingJoinQueue",	  "OnPVPMatchQueued", self)
		Apollo.RegisterEventHandler("MatchEntered",         "OnPVPMatchEntered", self)
		Apollo.RegisterEventHandler("MatchExited",          "OnPVPMatchExited", self)
		Apollo.RegisterEventHandler("PvpRatingUpdated",     "OnPVPRatingUpdated", self)
		Apollo.RegisterEventHandler("PVPMatchFinished",     "OnPVPMatchFinished", self)	
    Apollo.RegisterEventHandler("PublicEventStart",     "OnPublicEventStart", self)
    Apollo.RegisterEventHandler("PublicEventEnd",       "OnPublicEventEnd", self)

		---------------------------
		-- Form Items
    ---------------------------

    -- Match Type Filter
		self.wndFilterList       = self.wndMain:FindChild("FilterToggleList")
		self.wndFilterListToggle = self.wndMain:FindChild("FilterToggle")
		
		self.wndFilterListToggle:AttachWindow(self.wndFilterList)

    --  Arena Filter
    self.wndArenaFilterList       = self.wndMain:FindChild("ArenaFilterToggleList")
    self.wndArenaFilterListToggle = self.wndMain:FindChild("ArenaFilterToggle")
    
    self.wndArenaFilterListToggle:AttachWindow(self.wndArenaFilterList)

    -- Battleground Filter
    self.wndBattlegroundFilterList       = self.wndMain:FindChild("BattlegroundFilterToggleList")
    self.wndBattlegroundFilterListToggle = self.wndMain:FindChild("BattlegroundFilterToggle")
    
    self.wndBattlegroundFilterListToggle:AttachWindow(self.wndBattlegroundFilterList)
		
		self.eSelectedFilter = nil
    self.eSelectedArenaFilter = tArenaFilters.All
    self.eSelectedBattlegroundFilter = nil
		
    -- Initialize Database if necessary
		if self.bgchrondb.MatchHistory == nil or next(self.bgchrondb.MatchHistory) == nil then
	
			self.bgchrondb.MatchHistory = {}
			
			for key, tMatchType in pairs(ktMatchTypes) do
				self.bgchrondb.MatchHistory[key] = {}
			end
		end

		-- TODO: I feel that this could be done in a more elegant way, clean it up later
		-- Maybe the UI reloaded so be sure to check if we are in a match already
		if MatchingGame:IsInMatchingGame() then
			local tMatchState = MatchingGame:GetPVPMatchState()

			if tMatchState ~= nil then
				self:OnPVPMatchEntered()
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- BGChron Events
-----------------------------------------------------------------------------------------------

--[[
  NAME:          OnPVPMatchQueued
  PRECONDITION:  The player is able to queue.
  POSTCONDITION: Preliminary match information is stored in a temporary table.
]]
function BGChron:OnPVPMatchQueued()
	local tMatchInfo = self:GetMatchInfo()
	
	if not tMatchInfo then
		return
	end

	self.bgchrondb.TempMatch = nil
	self.bgchrondb.TempMatch = BGChronMatch:new({
		["nMatchType"] = tMatchInfo.nMatchType,
		["nTeamSize"]  = tMatchInfo.nTeamSize,
    ["bQueuedAsGroup"] = tMatchInfo.bQueuedAsGroup
	})
	self.bgchrondb.TempMatch:GenerateRatingInfo()
	
	self.currentMatch = self.bgchrondb.TempMatch
end

--[[
  NAME:          OnPublicEventStart
  PRECONDITION:  The user is near a public event.
  POSTCONDITION: If the public event is a valid PVP event, the event type is stored in a temporary table.
]]
function BGChron:OnPublicEventStart(peEvent)
  local eType = peEvent:GetEventType()
  if self.currentMatch and ktPvPEvents[eType] then
    self.currentMatch.nEventType = eType
  end
end

--[[
  NAME:          OnPVPMatchEntered
  PRECONDITION:  The user was queued for a valid PVP match and accepted the queue.
  POSTCONDITION: The current match is restored from a backup if the user had to reload, otherwise the time is saved.
]]
function BGChron:OnPVPMatchEntered()
	if not self.currentMatch and self.bgchrondb.TempMatch then
		-- Restore from backup
		self.currentMatch = self.bgchrondb.TempMatch
	else
		self.currentMatch.nMatchEnteredTick = os.time()
	end
end

-- TODO: This only seems to work for RBG because the rating updates after you leave the match
--[[
  NAME:          OnPVPRatingUpdated
  PRECONDITION:  The user is eligible to receive a rating update, typically after a rated match is completed.
  POSTCONDITION: The rating change is saved to the match database.
]]
function BGChron:OnPVPRatingUpdated(eRatingType)
	if ktSupportedTypes[eRatingType] == true then
		self:UpdateRating(eRatingType)
	end
end

-----------------------------------------------------------------------------------------------
-- BGChron Match Leaving Events
-----------------------------------------------------------------------------------------------

function BGChron:OnPVPMatchFinished(eWinner, eReason, nDeltaTeam1, nDeltaTeam2)
  if not self.currentMatch then
    return
  end
  local eEventType = self.currentMatch.nEventType

  if eEventType == nil or not ktPvPEvents[eEventType] or eEventType == PublicEvent.PublicEventType_PVP_Warplot then
    return
  end

  local tMatchState = MatchingGame:GetPVPMatchState()
  local eMyTeam = nil
  local tArenaTeamInfo = nil
  if tMatchState then
    eMyTeam = tMatchState.eMyTeam
  end

  self.currentMatch.nResult = self:GetResult(eMyTeam, eWinner)
  self.currentMatch.nMatchEndedTick = os.time()

  if nDeltaTeam1 and nDeltaTeam2 then
    self.arRatingDelta =
    {
      nDeltaTeam1,
      nDeltaTeam2
    }
  end

  if tMatchState and eEventType == PublicEvent.PublicEventType_PVP_Arena and tMatchState.arTeams then
  	tArenaTeamInfo = {}
    for idx, tCurr in pairs(tMatchState.arTeams) do

      if eMyTeam == tCurr.nTeam then
        --Event_FireGenericEvent("SendVarToRover", "MatchData", tCurr)
        tArenaTeamInfo.tPlayerTeam = tCurr
        --Print("You won't believe what I just got")
      else
        tArenaTeamInfo.tEnemyTeam = tCurr
      end

      self.currentMatch.tArenaTeamInfo = tArenaTeamInfo
    end
  end
  --self:UpdateMatchHistory(self.currentMatch)
end

function BGChron:OnPublicEventEnd(peEnding, eReason, tStats)

  local eEventType = peEnding:GetEventType()

  if self.currentMatch and ktPvPEvents[eEventType] then
    self.currentMatch.tMatchStats = tStats
  end
end

function BGChron:OnPVPMatchExited()
  if self.currentMatch then
    -- Check if user left before match finished.
    if not self.currentMatch.nResult then
      self.currentMatch.nResult = eResultTypes.Forfeit
    end
    self.currentMatch.nMatchEndedTick = os.time()
    self:UpdateMatchHistory(self.currentMatch)
  end
end

-----------------------------------------------------------------------------------------------
-- BGChron Slash Commands
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/bgchron"
function BGChron:OnBGChronOn()
	
	self.wndMain:Show(true)
	self.wndFilterList:Show(false)
  self.wndArenaFilterList:Show(false)
  self.wndArenaFilterListToggle:Show(false)
  self.wndBattlegroundFilterList:Show(false)
  self.wndBattlegroundFilterListToggle:Show(false)
  self.wndMain:FindChild("IntroDialog"):Show(false)
  local tData = nil

  -- Hide all grids
  for key, wndCurr in pairs(self.wndMain:FindChild("GridContainer"):GetChildren()) do
    wndCurr:Show(false)
  end

  -- Show dialog
  -- DEBUG: Only for intro version
  self:ShowIntro()

  if self.bIntroShown == false then
    self.wndFilterListToggle:Show(false)
    return
  else
    self.wndFilterListToggle:Show(true)
  end
	
	-- Move to selected filter, if eligible
	if self.eSelectedFilter == MatchingGame.MatchType.Battleground then
		local strMode = Apollo.GetString("MatchMaker_PracticeGrounds")
		self.wndFilterListToggle:SetText(strMode)
		self.wndFilterList:FindChild("BattlegroundBtn"):SetCheck(true)
    self.wndBattlegroundFilterListToggle:Show(true)

    self:UpdateBattlegroundFilterUI()
    tData = self:FilterBattlegroundDataByType(self.bgchrondb.MatchHistory[self.eSelectedFilter], self.eSelectedBattlegroundFilter)
	elseif self.eSelectedFilter == MatchingGame.MatchType.Arena then
		self.wndFilterListToggle:SetText(Apollo.GetString("MatchMaker_Arenas"))
		self.wndFilterList:FindChild("ArenaBtn"):SetCheck(true)
    self.wndArenaFilterListToggle:Show(true)

    self:UpdateArenaFilterUI()
    tData = self:FilterArenaDataByTeamSize(self.bgchrondb.MatchHistory[self.eSelectedFilter], self.eSelectedArenaFilter)
	elseif self.eSelectedFilter == MatchingGame.MatchType.RatedBattleground then
		local strMode = Apollo.GetString("CRB_Battlegrounds")
		self.wndFilterListToggle:SetText(strMode)
		self.wndFilterList:FindChild("RatedBattlegroundBtn"):SetCheck(true)
    self.wndBattlegroundFilterListToggle:Show(true)

    self:UpdateBattlegroundFilterUI()
    tData = self:FilterBattlegroundDataByType(self.bgchrondb.MatchHistory[self.eSelectedFilter], self.eSelectedBattlegroundFilter)
	elseif self.eSelectedFilter == MatchingGame.MatchType.OpenArena then
		self.wndFilterListToggle:SetText(Apollo.GetString("MatchMaker_OpenArenas"))
		self.wndFilterList:FindChild("OpenArenaBtn"):SetCheck(true)
    self.wndArenaFilterListToggle:Show(true)

    self:UpdateArenaFilterUI()
    tData = self:FilterArenaDataByTeamSize(self.bgchrondb.MatchHistory[self.eSelectedFilter], self.eSelectedArenaFilter)
	end
	
	-- Build a list
	if self.eSelectedFilter then
		self:HelperBuildGrid(self.wndMain:FindChild("GridContainer"), tData)
	end
end

-- on SlashCommand "/bgchronclear"
function BGChron:OnBGChronClear()
	Print("BGChron: Match History cleared")
	self.bgchrondb.MatchHistory = {}
end

-----------------------------------------------------------------------------------------------
-- BGChron Functions
-----------------------------------------------------------------------------------------------

function BGChron:UpdateRating(eRatingType)
	if not self.bgchrondb.MatchHistory then
		return
	end

  local nLastEntry = nil
  local tLastEntry = nil
  local nMatchType = nil
  local result     = self:GetCurrentRating(eRatingType)

  if not self.currentMatch then
    nLastEntry = #self.bgchrondb.MatchHistory[ktRatingTypeToMatchType[eRatingType]]
    tLastEntry = self.bgchrondb.MatchHistory[ktRatingTypeToMatchType[eRatingType]][nLastEntry]
  else
    tLastEntry = self.currentMatch
  end

  nMatchType = tLastEntry.nMatchType

	if nMatchType == ktRatingTypeToMatchType[eRatingType] then
		result = self:GetCurrentRating(eRatingType)
		
		if not tLastEntry.tRating.nEndRating then
			tLastEntry.tRating.nEndRating = result
		end
		
		if not tLastEntry.tRating.nRatingType then
			tLastEntry.tRating.nRatingType = eRatingType
		end
	end
end

function BGChron:GetResult(eMyTeam, eWinner)
	if eMyTeam == eWinner then
		return eResultTypes.Win
	else
		return eResultTypes.Loss
	end
end

function BGChron:GetCurrentRating(eRatingType)
	return MatchingGame.GetPvpRating(eRatingType).nRating
end

function BGChron:GetMatchInfo()
	local result = nil
	local tAllTypes =
	{
		MatchingGame.MatchType.Battleground,
		MatchingGame.MatchType.Arena,
		MatchingGame.MatchType.RatedBattleground,
		MatchingGame.MatchType.OpenArena
	}

	for key, nType in pairs(tAllTypes) do
		local tGames = MatchingGame.GetAvailableMatchingGames(nType)
		for key, matchGame in pairs(tGames) do
			if matchGame:IsQueued() == true then
				result = {
					nMatchType = nType,
					nTeamSize  = matchGame:GetTeamSize()
				}

        -- Check if solo or group queue
        result.bQueuedAsGroup = MatchingGame.IsQueuedAsGroup()
			end
		end
	end

	return result
end

function BGChron:UpdateMatchHistory(tMatch)
	if self.bgchrondb.MatchHistory == nil or next(self.bgchrondb.MatchHistory) == nil then
	
		self.bgchrondb.MatchHistory = {}
		
		for key, tMatchType in pairs(ktMatchTypes) do
			self.bgchrondb.MatchHistory[key] = {}
		end
	end
	table.insert(self.bgchrondb.MatchHistory[tMatch.nMatchType], tMatch)
	
	tMatch = nil
	self.currentMatch = nil
	self.bgchrondb.TempMatch = nil
end

-----------------------------------------------------------------------------------------------
-- BGChron Filters
-----------------------------------------------------------------------------------------------

-- TODO: Can we get better than log(n)?
-- Filters the arena list using eArenaFilter which coincides with team size
function BGChron:FilterArenaDataByTeamSize(tData, eArenaFilter)
  local tResult = {}

  if eArenaFilter == tArenaFilters.All then
    return tData
  end

  for key, tMatch in pairs(tData) do
    if tMatch.nTeamSize == eArenaFilter then
      table.insert(tResult, tMatch)
    end
  end
  return tResult
end

function BGChron:FilterBattlegroundDataByType(tData, eBattlegroundFilter)
  local tResult = {}

  if eBattlegroundFilter == nil then
    return tData
  end

  for key, tMatch in pairs(tData) do
    if tMatch.nEventType == eBattlegroundFilter then
      table.insert(tResult, tMatch)
    end
  end
  return tResult
end

-----------------------------------------------------------------------------------------------
-- BGChronForm Helpers
-----------------------------------------------------------------------------------------------

function BGChron:HelperBuildGrid(wndParent, tData)
	if not tData then
		-- Print("No data found")
		return
	end

	local wndGrid = wndParent:FindChild(ktMatchTypeToGridName[self.eSelectedFilter])
  wndGrid:Show(true)

	local nVScrollPos 	= wndGrid:GetVScrollPos()
	local nSortedColumn	= wndGrid:GetSortColumn() or 1
	local bAscending 	  = wndGrid:IsSortAscending()
	
	wndGrid:DeleteAll()
	
	for row, tMatch in pairs(tData) do
		local wndResultGrid = wndGrid
		self:HelperBuildRow(wndResultGrid, tMatch)
	end

	wndGrid:SetVScrollPos(nVScrollPos)
	wndGrid:SetSortColumn(nSortedColumn, bAscending)

end

function BGChron:HelperBuildRow(wndGrid, tMatchData)
	local chronMatch = BGChronMatch:new(tMatchData)
	row = wndGrid:AddRow("")

  wndGrid:SetCellLuaData(row, 1, tMatchData)
	
	local tValues     = chronMatch:GetFormattedData()
	local tSortValues = chronMatch:GetFormattedSortData()

	for col, sFormatKey in pairs(BGChronMatch.ktMatchTypeKeys[tMatchData.nMatchType]) do
		wndGrid:SetCellText(row, col, tValues[sFormatKey])
		wndGrid:SetCellSortText(row, col, tSortValues[sFormatKey])
	end
end

function BGChron:UpdateArenaFilterUI()
  if self.eSelectedArenaFilter == tArenaFilters.All then
    self.wndArenaFilterListToggle:SetText("All")
    self.wndArenaFilterList:FindChild("ArenaAllBtn"):SetCheck(true)
  elseif self.eSelectedArenaFilter == tArenaFilters.Twos then
    self.wndArenaFilterListToggle:SetText("2v2")
    self.wndArenaFilterList:FindChild("2v2Btn"):SetCheck(true)
  elseif self.eSelectedArenaFilter == tArenaFilters.Threes then
    self.wndArenaFilterListToggle:SetText("3v3")
    self.wndArenaFilterList:FindChild("3v3Btn"):SetCheck(true)
  elseif self.eSelectedArenaFilter == tArenaFilters.Fives then
    self.wndArenaFilterListToggle:SetText("5v5")
    self.wndArenaFilterList:FindChild("5v5Btn"):SetCheck(true)
  end
end

function BGChron:UpdateBattlegroundFilterUI()
  if self.eSelectedBattlegroundFilter == nil then
    self.wndBattlegroundFilterListToggle:SetText("All")
    self.wndBattlegroundFilterList:FindChild("BattlegroundAllBtn"):SetCheck(true)
  elseif self.eSelectedBattlegroundFilter == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
    self.wndBattlegroundFilterListToggle:SetText("Walatiki Temple")
    self.wndBattlegroundFilterList:FindChild("WalatikiBtn"):SetCheck(true)
  elseif self.eSelectedBattlegroundFilter == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
    self.wndBattlegroundFilterListToggle:SetText("Halls of the Bloodsworn")
    self.wndBattlegroundFilterList:FindChild("HotBBtn"):SetCheck(true)
  end
end

-----------------------------------------------------------------------------------------------
-- Statistics Functions
-----------------------------------------------------------------------------------------------

--[[
  NAME:          AverageForKey
  PRECONDITION:  A valid data set and key to access within the data set is given. 
                 Values are assumed to be numeric.
                 tData is a table of containing n > 0 tables
  POSTCONDITION: An average value is returned based on the given data.
]]
function BGChron:AverageForKey(tData, strKey)
  if not strKey or not tData then
    return 0
  end

  count = 0
  value = 0

  for key, tSubData in pairs(tData) do
    value = value + tSubData[strKey]
    count = count + 1
  end

  return value / count
end

-----------------------------------------------------------------------------------------------
-- BGChronForm Functions
-----------------------------------------------------------------------------------------------

function BGChron:OnClose( wndHandler, wndControl )
	self.wndMain:Close()
end

function BGChron:OnFilterBtnCheck( wndHandler, wndControl, eMouseButton )
	self.wndFilterList:Show(true)
end

function BGChron:OnFilterBtnUncheck( wndHandler, wndControl, eMouseButton )
	self.wndFilterList:Show(false)
end

function BGChron:OnSelectRatedBattlegrounds( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = MatchingGame.MatchType.RatedBattleground
	
	self:OnBGChronOn()
end

function BGChron:OnSelectArenas( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = MatchingGame.MatchType.Arena
	
	self:OnBGChronOn()
end

function BGChron:OnSelectBattlegrounds( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = MatchingGame.MatchType.Battleground
	
	self:OnBGChronOn()
end

function BGChron:OnSelectOpenArenas( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = MatchingGame.MatchType.OpenArena
	
	self:OnBGChronOn()
end

function BGChron:OnRowClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if bDoubleClick then
    local wndGrid = self.wndMain:FindChild(ktMatchTypeToGridName[self.eSelectedFilter])
		local nSelectedRow = wndGrid:GetCurrentRow()
    if not nSelectedRow then
      return
    end
		local MatchData    = wndHandler:GetCellLuaData(nSelectedRow, 1)
		
		-- Event_FireGenericEvent("SendVarToRover", "MatchData", wndHandler)
    MatchData:Initialize(self.wndMatchForm)
    wndGrid:SetCurrentRow(-1)
	end
end

-- Arena Filters

function BGChron:OnArenaFilterBtnCheck( wndHandler, wndControl, eMouseButton )
	self.wndArenaFilterList:Show(true)
end

function BGChron:OnArenaFilterBtnUncheck( wndHandler, wndControl, eMouseButton )
	self.wndArenaFilterList:Show(false)
end

function BGChron:OnSelectArenaFilterAll( wndHandler, wndControl, eMouseButton )
  self.eSelectedArenaFilter = tArenaFilters.All

  self:OnBGChronOn()
end

function BGChron:OnSelectArenaFilter2v2( wndHandler, wndControl, eMouseButton )
  self.eSelectedArenaFilter = tArenaFilters.Twos

  self:OnBGChronOn()
end

function BGChron:OnSelectArenaFilter3v3( wndHandler, wndControl, eMouseButton )
  self.eSelectedArenaFilter = tArenaFilters.Threes

  self:OnBGChronOn()
end

function BGChron:OnSelectArenaFilter5v5( wndHandler, wndControl, eMouseButton )
  self.eSelectedArenaFilter = tArenaFilters.Fives

  self:OnBGChronOn()
end

-- Battleground Filters

function BGChron:OnBattlegroundFilterBtnCheck( wndHandler, wndControl, eMouseButton )
  self.wndBattlegroundFilterList:Show(true)
end

function BGChron:OnBattlegroundFilterBtnUncheck( wndHandler, wndControl, eMouseButton )
  self.wndBattlegroundFilterList:Show(false)
end

function BGChron:OnSelectBattlegroundFilterAll( wndHandler, wndControl, eMouseButton )
  self.eSelectedBattlegroundFilter = nil

  self:OnBGChronOn()
end

function BGChron:OnSelectBattlegroundFilterWT( wndHandler, wndControl, eMouseButton )
  self.eSelectedBattlegroundFilter = PublicEvent.PublicEventType_PVP_Battleground_Vortex

  self:OnBGChronOn()
end

function BGChron:OnSelectBattlegroundFilterHotB( wndHandler, wndControl, eMouseButton )
  self.eSelectedBattlegroundFilter = PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine

  self:OnBGChronOn()
end
---------------------------------------------------------------------------------------------------
-- BGChronMatchForm Functions
---------------------------------------------------------------------------------------------------

function BGChron:OnMatchClose( wndHandler, wndControl, eMouseButton )
	self.wndMatchForm:Show(false)
end

---------------------------------------------------------------------------------------------------
-- BGChron Debugging
---------------------------------------------------------------------------------------------------

function BGChron:ShowIntro()
  if self.bIntroShown == true then
    return
  end

  self.wndMain:FindChild("IntroDialog"):Show(true)
end

function BGChron:CloseIntro()
  self.bIntroShown = true
  self.wndMain:FindChild("IntroDialog"):Show(false)
  self:OnBGChronOn()
end

-----------------------------------------------------------------------------------------------
-- BGChron Instance
-----------------------------------------------------------------------------------------------
local BGChronInst = BGChron:new()
BGChronInst:Init()
