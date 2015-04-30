function gadget:GetInfo()
	return {
		name 	= "Heightmap IO",
		desc 	= "reads and writes heightmap to and from unsynced",
		author 	= "eronoobos",
		date 	= "April 2015",
		license = "WTFPL",
		layer	= 0,
		version = "1",
		enabled = true,
	}
end

-- function localization

local mFloor = math.floor
local mCeil = math.ceil
local tInsert = table.insert
local spEcho = Spring.Echo
local spSetHeightMapFunc = Spring.SetHeightMapFunc
local spSetHeightMap = Spring.SetHeightMap

-- local functions

local function StringBegins(str, beginStr)
	return string.sub(str, 1, string.len(beginStr)) == beginStr
end

local function splitIntoWords(s)
  local words = {}
  for w in s:gmatch("%S+") do tInsert(words, w) end
  return words
end

local function WriteHeightRect(heights, x1, z1, x2, z2, h1, h2)
	local dx = x2 - x1
	local dh = h2 - h1
	local width = dx + 1
	local hmult = dh / 65535
	spSetHeightMapFunc(function()
		for i, u16int in pairs(heights) do
			local n = i - 1
			local x = (n % width) + x1
			local z = mFloor(n / width) + z1
			x = x * 8
			z = z * 8
			local h = (u16int * hmult) + h1
			spSetHeightMap(x, z, h)
		end
	end)
end

----- SPRING SYNCED ------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------

function gadget:RecvLuaMsg(msg, playerID)
	if not StringBegins(msg, 'HIO') then return end
	local w = splitIntoWords(msg)
	local cmd = w[2]
	if cmd == 'p' then -- packet
		-- p z x1 z1 x2 z2 h1 h2 data
		local zipped, x1, z1, x2, z2, h1, h2 = w[3] == 'z', w[4], w[5], w[6], w[7], w[8], w[9]
		local lastWord = string.find(msg, w[9])
		local packet = string.sub(msg, lastWord+string.len(w[9])+1)
		if zipped then
			packet = VFS.ZlibDecompress(packet)
		end
		local heights = VFS.UnpackU16(packet, 1, string.len(packet))
		WriteHeightRect(heights, x1, z1, x2, z2, h1, h2)
		-- Spring.Echo("got height rect", x1, z2, x2, z2, h1, h2)
	end
end

--------------------------------------------------------
else
----- SPRING UNSYNCED ------------------------------------------

local function HeightmapPacketToLuaUI(_)
  Script.LuaUI.ReceiveHeightmapPacket()
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction('HeightmapPacket', HeightmapPacketToLuaUI)
end

--------------------------------------------------------
end
--------------------------------------------------------