-- // METADATA
-- Creator: Ty_Scripts
-- Date created: 2/26/2021 16:00 UTC-5
-- More info: https://devforum.roblox.com/t/banit-simple-ban-module-for-anyone/1074218
-- Version: 6.01

-- // VARIABLES

local serverBanTable = {} 

local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local banStore = DSS:GetDataStore("BanStore" .. game.PlaceId .. "123456789")
local timedBanStore = DSS:GetDataStore("TimedBanStore" .. game.PlaceId .. "123456789")
local data = nil
local data2 = nil

local success, data = pcall(function()
	return banStore:GetAsync("Bans")
end)

if success and not data then
	data = {}
elseif not success then
	warn("DataStore failed. Try turning on Studio Access to API Services.")
end

local succ, err = pcall(function()
	data2 = timedBanStore:GetAsync("TimedBans")
end)

if succ and data2 == nil then
	data2 = {}
	print("There was no data")
elseif not succ then
	warn("DataStore failed. Try turning on Studio Access to API Services.")
elseif succ and err then
	warn(err)
end

-- // FUNCTIONS

local function saveData()
	local suc, err = pcall(function()
		return banStore:SetAsync("Bans", data)
	end)
	if not suc and err then
		warn(err)
	elseif suc then
		print("BanIt | Successfully saved")
	end
end

local function saveTimeData()
	local yes, no = pcall(function()
		return timedBanStore:SetAsync("TimedBans", data2)
	end)
	if not yes and no then
		warn(no)
	elseif yes then
		print("BanIt | Successfully saved")
		for k, v in pairs(data2) do
			print(k, v)
		end
	elseif not yes then
		print("idk")
	end
end

Players.PlayerAdded:Connect(function(plr)
	if table.find(data, plr.UserId) or table.find(serverBanTable, plr.UserId) then
		plr:Kick("Banned from the game!")
	elseif data2[tostring(plr.UserId)] ~= nil then
		local strTable = string.split(data2[tostring(plr.UserId)], ";")
		local timeLeft = os.time() - tostring(strTable[1])
		local num = tonumber(strTable[2]) 
		if num - timeLeft >= 1 then
			plr:Kick(tostring(num - timeLeft) .. " seconds left on ban.")
		end
	elseif data2[tostring(plr.UserId)] == nil then
		print("No data for user " .. plr.Name)
	end
end)

-- // MODULE

local BanIt = {}

function BanIt.ServerBan(plrUser, reason)
	local plr = Players:GetUserIdFromNameAsync(plrUser)
	table.insert(serverBanTable, plr)
	if Players:FindFirstChild(plrUser) then
		Players[plrUser]:Kick(reason or "Banned from the server!")
	end
end

function BanIt.Ban(plrUser, reason)
	local plr = Players:GetUserIdFromNameAsync(plrUser)
	table.insert(data, plr)
	saveData()
	if Players:FindFirstChild(plrUser) then
		Players[plrUser]:Kick(reason or "Banned from the game!")
	end
end

function BanIt.Unban(plrUser)
	local plr = Players:GetUserIdFromNameAsync(plrUser)
	if plr then
		local pos = table.find(data, plr)
		print(pos)
		table.remove(data, pos)
		print(data[pos])
		saveData()
	else
		warn("Player not found in database.")
	end
end

function BanIt.ServerUnban(plrUser)
	local plr = Players:GetUserIdFromNameAsync(plrUser)
	if plr then
		local pos = table.find(serverBanTable, plr)
		print(pos)
		table.remove(serverBanTable, pos)
		print(serverBanTable[pos])
		saveData()
	else
		warn("Player not found in database.")
	end
end

function BanIt.TimedBan(plrUser, num, numType)
	if numType:lower() == "minutes" then
		num *= 60
	elseif numType:lower() == "hours" then
		num *= 3600
	elseif numType:lower() == "days" then
		num *= 86400
	end
	local plr = Players:GetUserIdFromNameAsync(plrUser)
	print(typeof(plr))
	local current = os.time()
	data2[plr] = current .. ";" .. num
	print(data2[plr])
	saveTimeData()
	if Players:FindFirstChild(plrUser) then
		Players[plrUser]:Kick("Banned for " .. num .. " " .. numType .. " from the game.")
	end
end


return BanIt
