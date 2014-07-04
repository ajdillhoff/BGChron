
--------------------------------
-- BGChronMatch
--------------------------------

BGChronMatch = {}
-- BGChronMatch.__index = BGChronMatch


-- setmetatable(BGChronMatch, {
--   __call = function(cls, ...)
--     local self = setmetatable({}, cls)
--     -- self:_init(...)
--     return self
--   end
-- })

---------------------------------------------
-- Constants
---------------------------------------------

local ktParticipantKeys = -- Can swap to event type id's, but this just saves space
{
  ["Arena"] =
  {
    "strName",
    "nKills",
    "nDeaths",
    "nAssists",
    "nDamage",
    "nHealed",
    "nDamageReceived",
    "nHealingReceived",
    "nSaves"
  },

  ["WarPlot"] =
  {
    "strName",
    "nKills",
    "nDeaths",
    "nAssists",
    "nDamage",
    "nHealed",
    "nDamageReceived",
    "nHealingReceived",
    "nSaves",
    "nKillStreak"
  },

  ["HoldTheLine"] =
  {
    "strName",
    "nKills",
    "nDeaths",
    "nAssists",
    "nCustomNodesCaptured",
    "nDamage",
    "nHealed",
    "nDamageReceived",
    "nHealingReceived",
    "nSaves",
    "nKillStreak"
  },
  ["CTF"] =
  {
    "strName",
    "nKills",
    "nDeaths",
    "nAssists",
    "nCustomFlagsPlaced",
    "bCustomFlagsStolen",
    "nDamage",
    "nHealed",
    "nDamageReceived",
    "nHealingReceived",
    "nSaves",
    "nKillStreak"
  },
  ["Sabotage"] =
  {
    "strName",
    "nKills",
    "nDeaths",
    "nAssists",
    "nDamage",
    "nHealed",
    "nDamageReceived",
    "nHealingReceived",
    "nSaves",
    "nKillStreak"
  }
}

local kstrClassToMLIcon =
{
  [GameLib.CodeEnumClass.Warrior]     = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Warrior\"></T> ",
  [GameLib.CodeEnumClass.Engineer]    = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Engineer\"></T> ",
  [GameLib.CodeEnumClass.Esper]       = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Esper\"></T> ",
  [GameLib.CodeEnumClass.Medic]       = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Medic\"></T> ",
  [GameLib.CodeEnumClass.Stalker]     = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Stalker\"></T> ",
  [GameLib.CodeEnumClass.Spellslinger]  = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Spellslinger\"></T> ",
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

local ktEventTypeToWindowName =
{
  [PublicEvent.PublicEventType_PVP_Arena]                     = "PvPArenaContainer",
  [PublicEvent.PublicEventType_PVP_Warplot]                   = "PvPWarPlotContainer",
  [PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]  = "PvPHoldContainer",
  [PublicEvent.PublicEventType_PVP_Battleground_Vortex]       = "PvPCTFContainer",
  [PublicEvent.PublicEventType_PVP_Battleground_Sabotage]     = "PvPSaboContainer",
}

-- necessary until we can either get column names for a compare/swap or a way to set localized strings in XML for columns
local ktEventTypeToColumnNameList =
{
  [PublicEvent.PublicEventType_PVP_Arena] =
  {
    "PublicEventStats_Name",
    "PublicEventStats_Kills",
    "PublicEventStats_Deaths",
    "PublicEventStats_Assists",
    "PublicEventStats_DamageDone",
    "PublicEventStats_HealingDone",
    "PublicEventStats_DamageTaken",
    "PublicEventStats_HealingTaken",
    "PublicEventStats_Saves"
  },
  [PublicEvent.PublicEventType_PVP_Warplot] =
  {
    "PublicEventStats_Name",
    "PublicEventStats_Kills",
    "PublicEventStats_Deaths",
    "PublicEventStats_Assists",
    "PublicEventStats_DamageDone",
    "PublicEventStats_HealingDone",
    "PublicEventStats_DamageTaken",
    "PublicEventStats_HealingTaken",
    "PublicEventStats_Saves",
    "PublicEventStats_KillStreak"
  },
  [PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] =
  {
    "PublicEventStats_Name",
    "PublicEventStats_Kills",
    "PublicEventStats_Deaths",
    "PublicEventStats_Assists",
    "PublicEventStats_Captures",
    "PublicEventStats_DamageDone",
    "PublicEventStats_HealingDone",
    "PublicEventStats_DamageTaken",
    "PublicEventStats_HealingTaken",
    "PublicEventStats_Saves",
    "PublicEventStats_KillStreak"
  },
  [PublicEvent.PublicEventType_PVP_Battleground_Vortex] =
  {
    "PublicEventStats_Name",
    "PublicEventStats_Kills",
    "PublicEventStats_Deaths",
    "PublicEventStats_Assists",
    "PublicEventStats_Captures",
    "PublicEventStats_Stolen",
    "PublicEventStats_DamageDone",
    "PublicEventStats_HealingDone",
    "PublicEventStats_DamageTaken",
    "PublicEventStats_HealingTaken",
    "PublicEventStats_Saves",
    "PublicEventStats_KillStreak"
  },
  [PublicEvent.PublicEventType_PVP_Battleground_Sabotage] =
  {
    "PublicEventStats_Name",
    "PublicEventStats_Kills",
    "PublicEventStats_Deaths",
    "PublicEventStats_Assists",
    "PublicEventStats_DamageDone",
    "PublicEventStats_HealingDone",
    "PublicEventStats_DamageTaken",
    "PublicEventStats_HealingTaken",
    "PublicEventStats_Saves",
    "PublicEventStats_KillStreak"
  }
}

local eResultTypes = {
  Win     = 0,
  Loss    = 1,
  Forfeit = 2
}

local ktMatchTypes =
{
	[MatchingGame.MatchType.Battleground]      = "Battleground",
	[MatchingGame.MatchType.Arena]             = "Rated Arena",
	--[MatchingGame.MatchType.Warplot]           = "Warplot",
	[MatchingGame.MatchType.RatedBattleground] = "Rated Battleground",
	[MatchingGame.MatchType.OpenArena]         = {
		[2] = "Open Arena (2v2)",
		[3] = "Open Arena (3v3)",
		[5] = "Open Arena (5v5)"
	}
}

local ktRatingTypesToString = 
{ 
	[MatchingGame.RatingType.Arena2v2]          = "Rated Arena (2v2)", 
	[MatchingGame.RatingType.Arena3v3]          = "Rated Arena (3v3)", 
	[MatchingGame.RatingType.Arena5v5]          = "Rated Arena (5v5)", 
	[MatchingGame.RatingType.RatedBattleground] = "Rated Battleground",
	--[MatchingGame.RatingType.Warplot]           = "Warplot"
}

function BGChronMatch:new(o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  self:_init()
  -- self:SetData(o)
  return o
end


function BGChronMatch:_init()
  self.nMatchEnteredTick  = nil
  self.nMatchEndedTick    = nil
  self.tMatchStats        = nil
  self.tArenaTeamInfo     = nil
  self.nMatchType         = nil
  self.nEventType         = nil
  self.nMatchResult       = nil
  self.tRating            = nil
  self.nTeamSize          = nil
  self.bQueuedAsGroup     = nil
  self.nGroupSize         = nil
  
  self.ktMatchTypeKeys = {
    [MatchingGame.MatchType.Battleground]      = {
      "strDate",
      "strMatchType",
      "strResult",
      "strMatchTime",
      "strGroupType"
    },
    [MatchingGame.MatchType.Arena]             = {
      "strDate",
      "strMatchType",
      "strResult",
      "strRating",
      "strMatchTime",
      "strTeamName"
    },
    [MatchingGame.MatchType.RatedBattleground] = {
      "strDate",
      "strMatchType",
      "strResult",
      "strRating",
      "strMatchTime",
      "strGroupType"
    },
    [MatchingGame.MatchType.OpenArena]         = {
      "strDate",
      "strMatchType",
      "strResult",
      "strMatchTime",
      "strGroupType"
    }
  }

end

-- Return raw match data
function BGChronMatch:GetData()
  return {
    self.nMatchEnteredTick,
    self.nMatchEndedTick,
    self.tMatchStats,
    self.tArenaTeamInfo,
    self.nMatchType,
    self.nEventType,
    self.nMatchResult,
    self.tRating,
    self.nTeamSize,
    self.bQueuedAsGroup,
    self.nGroupSize    
  }
end

function BGChronMatch:SetData(tData)
  self.nMatchEnteredTick  = tData.nMatchEnteredTick      
  self.nMatchEndedTick    = tData.nMatchEndedTick        
  self.tMatchStats        = tData.tMatchStats        
  self.tArenaTeamInfo     = tData.tArenaTeamInfo     
  self.nMatchType         = tData.nMatchType         
  self.nEventType         = tData.nEventType         
  self.nMatchResult       = tData.nMatchResult       
  self.tRating            = tData.tRating            
  self.nTeamSize          = tData.nTeamSize          
  self.bQueuedAsGroup     = tData.bQueuedAsGroup     
  self.nGroupSize         = tData.nGroupSize         
end

-- Returns data formatted for a grid
function BGChronMatch:GetFormattedData()
  return {
    ["strDate"]      = self:GetDateString(),
    ["strMatchType"] = self:GetMatchTypeString(),
    ["strResult"]    = self:GetResultString(),
    ["strRating"]    = self:GetRatingString(),
    ["strMatchTime"] = self:GetMatchTimeString(),
    ["strTeamName"]  = self:GetTeamNameString(),
    ["strGroupType"] = self:GetGroupTypeString()
  }
end

-- Returns sort text for a grid
function BGChronMatch:GetFormattedSortData()
  return {
    ["strDate"]      = self:GetDateSortString(),
    ["strMatchType"] = self:GetMatchTypeString(),
    ["strResult"]    = self:GetResultString(),
    ["strRating"]    = self:GetRatingSortString(),
    ["strMatchTime"] = self:GetMatchTimeSortString(),
    ["strTeamName"]  = self:GetTeamNameString(),
    ["strGroupType"] = self:GetGroupTypeString()
  }
end

function BGChronMatch:GenerateRatingInfo()
	if not self.nMatchType then
		return
	end
	
  Print("Generating Rating Info")

	if self.nMatchType == MatchingGame.MatchType.RatedBattleground then
		self.tRating = {
			["nBeginRating"] = MatchingGame.GetPvpRating(MatchingGame.RatingType.RatedBattleground).nRating,
			["nEndRating"]   = nil,
			["nRatingType"]  = MatchingGame.RatingType.RatedBattleground
		}
	elseif self.nMatchType == MatchingGame.MatchType.Arena then
		if self.nTeamSize == 2 then
			self.tRating = {
				["nBeginRating"] = MatchingGame.GetPvpRating(MatchingGame.RatingType.Arena2v2).nRating,
				["nEndRating"]   = nil,
				["nRatingType"]  = MatchingGame.RatingType.Arena2v2,
				["strTeamName"]  = self:GetTeamName(MatchingGame.RatingType.Arena2v2)
			}
			self.strTeamName = self:GetTeamName(MatchingGame.RatingType.Arena2v2)
		elseif self.nTeamSize == 3 then
			self.tRating = {
				["nBeginRating"] = MatchingGame.GetPvpRating(MatchingGame.RatingType.Arena3v3).nRating,
				["nEndRating"]   = nil,
				["nRatingType"]  = MatchingGame.RatingType.Arena3v3,
				["strTeamName"]  = self:GetTeamName(MatchingGame.RatingType.Arena3v3)
			}
		elseif self.nTeamSize == 5 then
			self.tRating = {
				["nBeginRating"] = MatchingGame.GetPvpRating(MatchingGame.RatingType.Arena5v5).nRating,
				["nEndRating"]   = nil,
				["nRatingType"]  = MatchingGame.RatingType.Arena5v5,
				["strTeamName"]  = self:GetTeamName(MatchingGame.RatingType.Arena5v5)
			}
		end
	end
end

function BGChronMatch:GetTeamName(eRatingType)
	local result = nil
	local ktRatingTypeToGuildType = {
		[MatchingGame.RatingType.Arena2v2] = GuildLib.GuildType_ArenaTeam_2v2,
		[MatchingGame.RatingType.Arena3v3] = GuildLib.GuildType_ArenaTeam_3v3,
		[MatchingGame.RatingType.Arena5v5] = GuildLib.GuildType_ArenaTeam_5v5
	}

	for key, tCurrGuild in pairs(GuildLib.GetGuilds()) do
		if tCurrGuild:GetType() == ktRatingTypeToGuildType[eRatingType] then
			result = tCurrGuild:GetName()
		end
	end
	
	return result
end

-----------------------------------------------------------------------------------------------
-- Drawing Method
-----------------------------------------------------------------------------------------------

function BGChronMatch:Redraw(wndMain)
  local tData = wndMain:GetData()
  local tStatsSelf = tData.tStatsSelf
  local tStatsTeam = tData.tStatsTeam
  local tStatsParticipants = tData.tStatsParticipants
  local tMegaList = self:HelperBuildCombinedList(tStatsSelf, tStatsTeam, tStatsParticipants)

  for key, wndCurr in pairs(wndMain:FindChild("MainGridContainer"):GetChildren()) do
    wndCurr:Show(false)
  end

  local eEventType = self.nEventType
  local wndGrid = wndMain:FindChild(ktEventTypeToWindowName[eEventType])

  if eEventType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
    self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "HoldTheLine")
  elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
    self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "CTF")
  elseif eEventType == PublicEvent.PublicEventType_PVP_Warplot then
    self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "WarPlot")
  elseif eEventType == PublicEvent.PublicEventType_PVP_Arena then
    self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "Arena")
  elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
    self:HelperBuildPvPSharedGrids(wndGrid, tMegaList, "Sabotage")
  end

  -- Title Text (including timer)
  -- TODO: Update this to something useful
  local strTitleText = "Match Detail"
  
  wndMain:FindChild("EventTitleText"):SetText(strTitleText)

  if wndGrid then
    wndGrid:Show(true)
  end

  if not wndMain:IsShown() then
    wndMain:Show(true)
    wndMain:ToFront()
  end
end


-----------------------------------------------------------------------------------------------
-- Data Formatting Functions
-----------------------------------------------------------------------------------------------

function BGChronMatch:GetDateString() 
  local result = "N/A"

  if self.nMatchEndedTick then
    result = string.format("%s", os.date("%c", self.nMatchEndedTick))
  end

  return result
end

function BGChronMatch:GetMatchTypeString()
  result = "N/A"

  local ktEventTypeToMapName = {
    [PublicEvent.PublicEventType_PVP_Battleground_Vortex]      = "Walatiki Temple",
    [PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] = "Halls of the Bloodsworn"
  }

  if ktEventTypeToMapName[self.nEventType] ~= nil then
    result = ktEventTypeToMapName[self.nEventType]
  elseif self.tRating and self.tRating.nRatingType then
    -- Rated
    result = ktRatingTypesToString[self.tRating.nRatingType]
  elseif self.nMatchType then
    -- Non Rated
    if self.nMatchType == MatchingGame.MatchType.OpenArena then
  		result = ktMatchTypes[self.nMatchType][self.nTeamSize]
  	else
  		result = ktMatchTypes[self.nMatchType]
  	end
  end

  return result
end

function BGChronMatch:GetResultString()
  local result = "N/A"
  local ktResultTypes = { 
    [eResultTypes.Win]     = "Win",
    [eResultTypes.Loss]    = "Loss",
    [eResultTypes.Forfeit] = "Forfeit"
  }

  if self.nResult then
    result = ktResultTypes[self.nResult]
  end

  return result
end

function BGChronMatch:GetRatingString()
  local result = "N/A"
  
  if not self.tRating or not self.tRating.nBeginRating or not self.tRating.nEndRating then
	return result
  end
  
  local nPreviousRating = self.tRating.nBeginRating
  local nCurrentRating  = self.tRating.nEndRating

  if nPreviousRating and nCurrentRating then
    if nPreviousRating < nCurrentRating then
      result = string.format("%d (+%d)", nCurrentRating, (nCurrentRating - nPreviousRating))
    elseif nPreviousRating > nCurrentRating then
      result = string.format("%d (-%d)", nCurrentRating, (nPreviousRating - nCurrentRating))
    end
  end

  return result
end

function BGChronMatch:GetMatchTimeString()
  local result = "N/A"

  if not self.tMatchStats or not self.tMatchStats.nElapsedTime then
    return result
  end

  result = self:HelperConvertTimeToString(self.tMatchStats.nElapsedTime)

  return result
end

function BGChronMatch:GetGroupTypeString()
  local result = "N/A"

  if self.bQueuedAsGroup == nil then
    return result
  end

  local bQueuedAsGroup = self.bQueuedAsGroup

  if bQueuedAsGroup == true then
    result = "Group"
  else
    result = "Solo"
  end

  return result
end

function BGChronMatch:GetTeamNameString()
  local result = "N/A"

  if not self.tRating or
    not self.tRating.strTeamName then
    return result
  end

  result = self.tRating.strTeamName

  return result
end

function BGChronMatch:GetDateSortString()
  local result = ""

  if self.nMatchEndedTick then
    result = self.nMatchEndedTick
  end

  return result
end

function BGChronMatch:GetRatingSortString()
  local result = ""

  if self.tRating and self.tRating.nEndRating then
    return self.tRating.nEndRating
  end

  return result
end

function BGChronMatch:GetMatchTimeSortString()
  local result = ""

  if not self.tMatchStats or not self.tMatchStats.nElapsedTime then
    return result
  end

  result = self.tMatchStats.nElapsedTime

  return result
end

function BGChronMatch:Initialize(wndMain)

  if not self.tMatchStats or not next(self.tMatchStats) then
    return
  end

  local eEventType = self.nEventType
  local wndParent = wndMain:FindChild(ktEventTypeToWindowName[eEventType])

  local wndGrid = wndParent

  if wndGrid:GetName() ~= "PublicEventGrid" then
    wndGrid = wndParent:FindChild("PvPTeamGridBot")

    for idx = 1, wndGrid:GetColumnCount() do
      wndGrid:SetColumnText(idx, Apollo.GetString(ktEventTypeToColumnNameList[eEventType][idx]))
    end

    wndGrid = wndParent:FindChild("PvPTeamGridTop")
  end

  local nMaxWndMainWidth = wndMain:GetWidth() - wndGrid:GetWidth() + 15 -- Magic number for the width of the scroll bar
  for idx = 1, wndGrid:GetColumnCount() do
    nMaxWndMainWidth = nMaxWndMainWidth + wndGrid:GetColumnWidth(idx)
    wndGrid:SetColumnText(idx, Apollo.GetString(ktEventTypeToColumnNameList[eEventType][idx]))
  end

  wndMain:SetSizingMinimum(500, 500)
  wndMain:SetSizingMaximum(nMaxWndMainWidth, 800)

  local tData =
  {
    tStatsSelf = self.tMatchStats.arPersonalStats or {},
    tStatsTeam = self.tMatchStats.arTeamStats or {},
    tStatsParticipants = self.tMatchStats.arParticipantStats or {}
  }

  wndMain:SetData(tData)
  wndMain:Show(false)

  self:Redraw(wndMain)

end

-----------------------------------------------------------------------------------------------
-- Grid Building
-----------------------------------------------------------------------------------------------

-- ty Carbine
function BGChronMatch:HelperBuildPvPSharedGrids(wndParent, tMegaList, eEventType)
  if not tMegaList or not tMegaList.tStatsTeam or not tMegaList.tStatsParticipant then
    return
  end

  if not wndParent or not self.tMatchStats then
    return
  end

  local wndGridTop  = wndParent:FindChild("PvPTeamGridTop")
  local wndGridBot  = wndParent:FindChild("PvPTeamGridBot")
  local wndHeaderTop  = wndParent:FindChild("PvPTeamHeaderTop")
  local wndHeaderBot  = wndParent:FindChild("PvPTeamHeaderBot")

  local nVScrollPosTop  = wndGridTop:GetVScrollPos()
  local nVScrollPosBot  = wndGridBot:GetVScrollPos()
  local nSortedColumnTop  = wndGridTop:GetSortColumn() or 1
  local nSortedColumnBot  = wndGridBot:GetSortColumn() or 1
  local bAscendingTop   = wndGridTop:IsSortAscending()
  local bAscendingBot   = wndGridBot:IsSortAscending()
  
  wndGridTop:DeleteAll()
  wndGridBot:DeleteAll()

  local strMyTeamName = ""

  for key, tCurr in pairs(tMegaList.tStatsTeam) do
    local wndHeader = nil
    if not wndHeaderTop:GetData() or wndHeaderTop:GetData() == tCurr.strTeamName then
      wndHeader = wndHeaderTop
      wndGridTop:SetData(tCurr.strTeamName)
      wndHeaderTop:SetData(tCurr.strTeamName)
    elseif not wndHeaderBot:GetData() or wndHeaderBot:GetData() == tCurr.strTeamName then
      wndHeader = wndHeaderBot
      wndGridBot:SetData(tCurr.strTeamName)
      wndHeaderBot:SetData(tCurr.strTeamName)
    end

    local strHeaderText = wndHeader:FindChild("PvPHeaderText"):GetData() or ""
    local crTitleColor = ApolloColor.new("ff7fffb9")
    local strDamage = String_GetWeaselString(Apollo.GetString("PublicEventStats_Damage"), self:HelperFormatNumber(tCurr.nDamage))
    local strHealed = String_GetWeaselString(Apollo.GetString("PublicEventStats_Healing"), self:HelperFormatNumber(tCurr.nHealed))

    -- Setting up the team names / headers
    if eEventType == "CTF" or eEventType == "HoldTheLine" or eEventType == "Sabotage" then
      if tCurr.strTeamName == "Exiles" then
        crTitleColor = ApolloColor.new("ff31fcf6")
      elseif tCurr.strTeamName == "Dominion" then
        crTitleColor = ApolloColor.new("ffb80000")
      end
      local strKDA = String_GetWeaselString(Apollo.GetString("PublicEventStats_KDA"), tCurr.nKills, tCurr.nDeaths, tCurr.nAssists)

      strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_PvPHeader"), strKDA, strDamage, strHealed)
    elseif eEventType == "Arena" then
      strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_ArenaHeader"), strDamage, strHealed) -- TODO, Rating Change when support is added
      if tCurr.bIsMyTeam then
        strMyTeamName = tCurr.strTeamName
      end
    elseif eEventType == "Warplot" then
      strHeaderText = wndHeader:FindChild("PvPHeaderText"):GetData() or ""
    end

    wndHeader:FindChild("PvPHeaderText"):SetText(strHeaderText)
    wndHeader:FindChild("PvPHeaderTitle"):SetTextColor(crTitleColor)
    wndHeader:FindChild("PvPHeaderTitle"):SetText(tCurr.strTeamName)
  end

  for key, tParticipant in pairs(tMegaList.tStatsParticipant) do
    local wndGrid = wndGridBot
    if wndGridTop:GetData() == tParticipant.strTeamName then
      wndGrid = wndGridTop
    end

    -- Custom Stats
    if eEventType == "HoldTheLine" then
      for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
        if tCustomTable.strName == Apollo.GetString("PublicEventStats_SecondaryPointCaptured") then
          tParticipant.nCustomNodesCaptured = tCustomTable.nValue or 0
        end
      end
    elseif eEventType == "CTF" then
      for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
        if idx == 1 then
          tParticipant.nCustomFlagsPlaced = tCustomTable.nValue or 0
        else
          tParticipant.bCustomFlagsStolen = tCustomTable.nValue or 0
        end
      end
    end
  end

  for key, tParticipant in pairs(tMegaList.tStatsParticipant) do
    local wndGrid = wndGridBot
    if wndGridTop:GetData() == tParticipant.strTeamName then
      wndGrid = wndGridTop
    end

    -- Custom Stats
    if eEventType == "HoldTheLine" then
      for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
        if tCustomTable.strName == Apollo.GetString("PublicEventStats_SecondaryPointCaptured") then
          tParticipant.nCustomNodesCaptured = tCustomTable.nValue or 0
        end
      end
    elseif eEventType == "CTF" then
      for idx, tCustomTable in pairs(tParticipant.arCustomStats) do
        if idx == 1 then
          tParticipant.nCustomFlagsPlaced = tCustomTable.nValue or 0
        else
          tParticipant.bCustomFlagsStolen = tCustomTable.nValue or 0
        end
      end
    end


    local wndCurrRow = self:HelperGridFactoryProduce(wndGrid, tParticipant.strName) -- GOTCHA: This is an integer
    wndGrid:SetCellLuaData(wndCurrRow, 1, tParticipant.strName)
    for idx, strParticipantKey in pairs(ktParticipantKeys[eEventType]) do
      local value = tParticipant[strParticipantKey]
      if type(value) == "number" then
        wndGrid:SetCellSortText(wndCurrRow, idx, string.format("%8d", value))
      else
        wndGrid:SetCellSortText(wndCurrRow, idx, value or 0)
      end

      local strClassIcon = idx == 1 and kstrClassToMLIcon[tParticipant.eClass] or ""

      wndGrid:SetCellDoc(wndCurrRow, idx, string.format("<T Font=\"CRB_InterfaceSmall\">%s%s</T>", strClassIcon, self:HelperFormatNumber(value)))
    end
  end

  wndGridTop:SetVScrollPos(nVScrollPosTop)
  wndGridBot:SetVScrollPos(nVScrollPosBot)
  wndGridTop:SetSortColumn(nSortedColumnTop, bAscendingTop)
  wndGridBot:SetSortColumn(nSortedColumnBot, bAscendingBot)
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function BGChronMatch:HelperBuildCombinedList(tStatsSelf, tStatsTeam, tStatsParticipants)
  local tMegaList = {}
  tMegaList.tStatsSelf = {tStatsSelf}

  if tStatsTeam then
    for key, tCurr in pairs(tStatsTeam) do
      if not tMegaList.tStatsTeam then
        tMegaList.tStatsTeam = {}
      end
      table.insert(tMegaList.tStatsTeam, tCurr)
    end
  end

  if tStatsParticipants then
    for key, tCurr in pairs(tStatsParticipants) do
      if not tMegaList.tStatsParticipant then
        tMegaList.tStatsParticipant = {}
      end
      table.insert(tMegaList.tStatsParticipant, tCurr)
    end
  end
  return tMegaList
end

function BGChronMatch:HelperFormatNumber(nArg)
  if tonumber(nArg) and tonumber(nArg) > 10000 then
    nArg = String_GetWeaselString(Apollo.GetString("PublicEventStats_Thousands"), math.floor(nArg/1000))
  else
    nArg = tostring(nArg)
  end
  return nArg
  -- TODO: Consider trimming huge numbers into a more readable format
end

function BGChronMatch:HelperConvertTimeToString(fTime)
  fTime = math.floor(fTime / 1000) -- TODO convert to full seconds

  return string.format("%d:%02d", math.floor(fTime / 60), math.floor(fTime % 60))
end

function BGChronMatch:HelperGridFactoryProduce(wndGrid, tTargetComparison)
  for nRow = 1, wndGrid:GetRowCount() do
    if wndGrid:GetCellLuaData(nRow, 1) == tTargetComparison then -- GetCellLuaData args are row, col
      return nRow
    end
  end
  return wndGrid:AddRow("") -- GOTCHA: This is a row number
end