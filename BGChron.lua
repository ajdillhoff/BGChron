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

local eResultTypes = {
	Win     = 0,
	Loss    = 1,
	Forfeit = 2
}

-- TODO: This will be expanded to a table if more views are added
local kEventTypeToWindowName = "ResultGrid"

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
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("bgchronclear",     	"OnBGChronClear", self)
		Apollo.RegisterSlashCommand("bgchron",              "OnBGChronOn", self)
		Apollo.RegisterEventHandler("MatchingJoinQueue",	"OnPVPMatchQueued", self)
		Apollo.RegisterEventHandler("MatchEntered",         "OnPVPMatchEntered", self)
		Apollo.RegisterEventHandler("MatchExited",          "OnPVPMatchExited", self)
		Apollo.RegisterEventHandler("PvpRatingUpdated",     "OnPVPRatingUpdated", self)
		-- Apollo.RegisterEventHandler("PVPMatchStateUpdated", "OnPVPMatchStateUpdated", self)	
		Apollo.RegisterEventHandler("PVPMatchFinished",     "OnPVPMatchFinished", self)	
		--Apollo.RegisterEventHandler("PublicEventStart",     "OnPublicEventStart", self)

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

function BGChron:OnPVPMatchQueued()
	local tDate = GameLib:GetLocalTime()
	local nMatchType = self:GetMatchType()
	local tRating = nil
	
	if not nMatchType then
		return
	end

	tDate["nTickCount"] = GameLib:GetTickCount()
	
	-- If rated RBG, get personal rating. Other types are calculated after the match ends
	if nMatchType == MatchingGame.MatchType.RatedBattleground then
		tRating = {
			["nBeginRating"] = self:GetCurrentRating(MatchingGame.RatingType.RatedBattleground),
			["nEndRating"]   = nil
		}
	end

	self.bgchrondb.TempMatch = nil
	self.bgchrondb.TempMatch = BGChronMatch:new({
		["tDate"]      = tDate,
		["nMatchType"] = nMatchType,
		["nResult"]    = nil, 
		["tRating"]    = tRating
	})
	
	Print("Queued and TempMatch saved")
	
	self.currentMatch = self.bgchrondb.TempMatch
end

function BGChron:OnPVPMatchEntered()
	if self.bgchrondb.TempMatch then
		-- Restore from backup
		self.currentMatch = self.bgchrondb.TempMatch
	end
end

function BGChron:OnPVPMatchExited()
	if self.currentMatch then
		-- User left before match finished.
		self.currentMatch.nResult = eResultTypes.Forfeit
		self:UpdateMatchHistory(self.currentMatch)
	end
end

function BGChron:OnPVPRatingUpdated(eRatingType)
	if eRatingType == MatchingGame.RatingType.RatedBattleground then
		self:UpdateRating(eRatingType)
	end
end

function BGChron:OnPVPMatchFinished(eWinner, eReason, nDeltaTeam1, nDeltaTeam2)
	if not self.currentMatch then
		return
	end

	local tMatchState = MatchingGame:GetPVPMatchState()
	local eMyTeam = nil
	local tRatingDeltas = {
		nDeltaTeam1,
		nDeltaTeam2
	}
	
	if tMatchState then
		eMyTeam = tMatchState.eMyTeam
	end	
	
	self.currentMatch.nResult = self:GetResult(eMyTeam, eWinner)
	
	if tRatingDeltas then
		-- Rating Changes Happened
		if tMatchState.arTeams then
			local tRating = nil
			for idx, tCurr in pairs(tMatchState.arTeams) do
				if eMyTeam == tCurr.nTeam then
					tRating.nEndRating = tCurr.nRating
					tRating.nBeginRating = tCurr.nRating - tRatingDeltas[idx]
				end
			end
			self.currentMatch.tRating = tRating
		end
	end

	self:UpdateMatchHistory(self.currentMatch)
end

-----------------------------------------------------------------------------------------------
-- BGChron Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/bgchron"
function BGChron:OnBGChronOn()

	local t = {
		{
			["tDate"]      = {
			  ["nHour"] = 1,
			  ["nSecond"] = 51,
			  ["nMonth"] = 6,
			  ["nHour"] = 16,
			  ["strFormattedTime"] = "1:15:51 AM",
			  ["nYear"] = 2014,
			  ["nTickCount"] = 885763218,
			  ["nDay"] = 25,
			  ["nDayOfWeek"] = 4,
			},
			["nMatchType"] = 3,
			["nResult"]    = nil,
			["tRating"]    = {
			  ["nBeginRating"] = 1000,
			  ["nEndRating"]   = 1040
			}
		},
	}
	
	BGChron:HelperBuildGrid(self.wndMain:FindChild("GridContainer"), self.bgchrondb.MatchHistory)
	self.wndMain:Invoke() -- show the window
end

-- on SlashCommand "/bgchronclear"
function BGChron:OnBGChronClear()
	Print("BGChron: Match History cleared")
	self.bgchrondb.MatchHistory = {}
end

function BGChron:UpdateRating(eRatingType)
	if not self.bgchrondb.MatchHistory then
		return
	end

	local nLastEntry = #self.bgchrondb.MatchHistory
	local tLastEntry = self.bgchrondb.MatchHistory[nLastEntry]
	local nMatchType = tLastEntry["nMatchType"]
	local result     = nil

	if nMatchType == ktRatingTypeToMatchType[eRatingType] then
		result = self:GetCurrentRating(ktRatingTypeToMatchType[eRatingType])
	end

	tLastEntry.tRating.nEndRating = result
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

function BGChron:GetMatchType()
	local result = nil
	local tAllTypes =
	{
		MatchingGame.MatchType.Battleground,
		MatchingGame.MatchType.Arena,
		--MatchingGame.MatchType.Warplot,
		MatchingGame.MatchType.RatedBattleground,
		MatchingGame.MatchType.OpenArena
	}

	for key, nType in pairs(tAllTypes) do
		local tGames = MatchingGame.GetAvailableMatchingGames(nType)
		for key, matchGame in pairs(tGames) do
			if matchGame:IsQueued() == true then
				result = nType
			end
		end
	end

	return result
end

function BGChron:UpdateMatchHistory(tMatch)
	if self.bgchrondb.MatchHistory == nil then
		self.bgchrondb.MatchHistory = {}
	end
	table.insert(self.bgchrondb.MatchHistory, tMatch)
	
	tMatch = nil
	self.bgchrondb.TempMatch = nil
end

-----------------------------------------------------------------------------------------------
-- BGChronForm Functions
-----------------------------------------------------------------------------------------------

function BGChron:HelperBuildGrid(wndParent, tData)
	if not tData then
		-- Print("No data found")
		return
	end

	local wndGrid = wndParent:FindChild("ResultGrid")

	local nVScrollPos 	= wndGrid:GetVScrollPos()
	local nSortedColumn	= wndGrid:GetSortColumn() or 1
	local bAscending 	= wndGrid:IsSortAscending()
	
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
	
	local tValues     = chronMatch:GetFormattedData()
	local tSortValues = chronMatch:GetFormattedSortData()

	for col, sFormatKey in pairs(BGChronMatch.tFormatKeys) do
		wndGrid:SetCellText(row, col, tValues[sFormatKey])
		wndGrid:SetCellSortText(row, col, tSortValues[sFormatKey])
	end
end

function BGChron:OnClose( wndHandler, wndControl )
	self.wndMain:Close()
end

-----------------------------------------------------------------------------------------------
-- BGChron Instance
-----------------------------------------------------------------------------------------------
local BGChronInst = BGChron:new()
BGChronInst:Init()
