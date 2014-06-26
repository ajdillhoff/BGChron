
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
	[MatchingGame.MatchType.Warplot]           = "Warplot",
	[MatchingGame.MatchType.RatedBattleground] = "Rated Battleground",
	[MatchingGame.MatchType.OpenArena]         = "Arena"
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
  self.__index = self
  return o
end


function BGChronMatch:_init()
  self.tDate      = nil
  self.nMatchType = nil
  self.nResult    = nil
  self.tRating    = nil
  
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
	result = ktRatingTypesToString[self.tRating.nRatingType]
  elseif self.nMatchType then
    result = ktMatchTypes[self.nMatchType]
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
  local result = nil

  if self.tDate then
    result = self.tDate.nTickCount
  end

  return result
end

function BGChronMatch:GetRatingSortString()
  local result = nil

  if self.tRating then
    return self.tRating.nEndRating
  end

  return result
end