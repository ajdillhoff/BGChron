
--------------------------------
-- BGChronMatch
--------------------------------

BGChronMatch = {}
BGChronMatch.__index = BGChronMatch


setmetatable(BGChronMatch, {
  __call = function(cls, ...)
    local self = setmetatable({}, cls)
    self:_init(...)
    return self
  end
})

---------------------------------------------
-- Constants
---------------------------------------------

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
  self:_init()
  self:SetData(o)
  self.__index = self
  return o
end


function BGChronMatch:_init()
  self.tDate      = nil
  self.nMatchType = nil
  self.nResult    = nil
  self.tRating    = nil
  self.nTeamSize  = nil
  
  self.tFormatKeys = {
	"strDate",
	"strMatchType",
	"strResult",
	"strRating"
	}
end

-- Return raw match data
function BGChronMatch:GetData()
  return {
    self.tDate,
    self.nMatchType,
    self.nResult,
    self.tRating
  }
end

function BGChronMatch:SetData(tData)
  self.tDate      = tData.tDate
  self.nMatchType = tData.nMatchType
  self.nResult    = tData.nResult
  self.tRating    = tData.tRating
  self.nTeamSize  = tData.nTeamSize
end

-- Returns data formatted for a grid
function BGChronMatch:GetFormattedData()
  return {
    ["strDate"]      = self:GetDateString(),
    ["strMatchType"] = self:GetMatchTypeString(),
    ["strResult"]    = self:GetResultString(),
    ["strRating"]    = self:GetRatingString()
  }
end

-- Returns sort text for a grid
function BGChronMatch:GetFormattedSortData()
  return {
    ["strDate"]      = self:GetDateSortString(),
    ["strMatchType"] = self:GetMatchTypeString(),
    ["strResult"]    = self:GetResultString(),
    ["strRating"]    = self:GetRatingSortString()
  }
end

function BGChronMatch:GenerateRatingInfo()
	if not self.nMatchType then
		return
	end
	
	if self.nMatchType == MatchingGame.MatchType.RatedBattleground then
		self.tRating = {
			["nBeginRating"] = MatchingGame.GetPvpRating(MatchingGame.RatingType.RatedBattleground).nRating,
			["nEndRating"]   = nil,
			["nRatingType"]  = MatchingGame.RatingType.RatedBattleground
		}
	elseif self.nMatchType == MatchingGame.MatchType.RatedArena then
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
-- Data Formatting Functions
-----------------------------------------------------------------------------------------------

function BGChronMatch:GetDateString() 
  local result = "N/A"

  if self.tDate then
    result = string.format("%02d/%02d/%4d %s", self.tDate["nMonth"], self.tDate["nDay"], self.tDate["nYear"], self.tDate["strFormattedTime"])
  end

  return result
end

function BGChronMatch:GetMatchTypeString()
  result = "N/A"

  if self.tRating and self.tRating.nRatingType then
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

function BGChronMatch:GetDateSortString()
  local result = ""

  if self.tDate then
    result = self.tDate.nTickCount
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