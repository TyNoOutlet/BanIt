-- // METADATA
-- Creator: Ty_Scripts
-- Date created: 2/26/2021 16:00 UTC-5
-- More info: https://devforum.roblox.com/t/banit-simple-ban-module-for-anyone/1074218
-- Version: 7

-- // VARIABLES

local serverBanTable = {}

local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
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
		local timeLeft = os.time() - tonumber(strTable[1])
		local num = tonumber(strTable[2]) 
		if num - timeLeft >= 1 then
			plr:Kick(tostring(num - timeLeft) .. " seconds left on ban.")
		end
	elseif data2[tostring(plr.UserId)] == nil then
		print("No data for user " .. plr.Name)
	end
end)

local subSuc, subCon = pcall(function()
	return MS:SubscribeAsync("Ban", function(message)
		local data = message.Data
		local dataTable = string.split(data, "⌐")
		if Players:FindFirstChild(dataTable[1]) then
			Players:FindFirstChild(dataTable[1]):Kick(dataTable[2] or "You have been banned.")
		end
	end)
end)
-- // MODULE

local BanIt = {}

function BanIt.ServerBan(plrUser, reason)
	local success = pcall(function()
		plr = Players:GetUserIdFromNameAsync(plrUser)
	end)
	if success and plr then
		table.insert(serverBanTable, plr)
		if Players:FindFirstChild(plrUser) then
			Players[plrUser]:Kick(reason or "Banned from the server!")
		end
	else
		warn("Player not found in database. Call may have failed, try again.")
	end
end

function BanIt.Ban(plrUser, reason)
	local success = pcall(function()
		plr = Players:GetUserIdFromNameAsync(plrUser)
	end)
	if success and plr then
		table.insert(data, plr)
		saveData()
		if Players:FindFirstChild(plrUser) then
			Players[plrUser]:Kick(reason or "Banned from the game!")
		else
			local s, result = pcall(function()
				return MS:PublishAsync("Ban", plrUser .. "⌐" .. reason)
			end)
		end
	else
		warn("Player not found in database. Call may have failed, try again.")
	end
end

function BanIt.Unban(plrUser)
	local success = pcall(function()
		plr = Players:GetUserIdFromNameAsync(plrUser)
	end)
	if success and plr then
		local pos = table.find(data, plr)
		print(pos)
		table.remove(data, pos)
		print(data[pos])
		saveData()
	else
		warn("Player not found in database. Call may have failed, try again.")
	end
end

function BanIt.ServerUnban(plrUser)
	local success = pcall(function()
		plr = Players:GetUserIdFromNameAsync(plrUser)
	end)
	if success and plr then
		local pos = table.find(serverBanTable, plr)
		print(pos)
		table.remove(serverBanTable, pos)
		print(serverBanTable[pos])
		saveData()
	else
		warn("Player not found in database. Call may have failed, try again.")
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
	local success = pcall(function()
		plr = Players:GetUserIdFromNameAsync(plrUser)
	end)
	if success and plr then
		local current = os.time()
		data2[plr] = current .. ";" .. num
		print(data2[plr])
		saveTimeData()
		if Players:FindFirstChild(plrUser) then
			Players[plrUser]:Kick("Banned for " .. num .. " " .. numType .. " from the game.")
		else
			local s, result = pcall(function()
				return MS:PublishAsync("Ban", plrUser .. "⌐" .. "Banned for " .. num .. " " .. numType .. " from the game.")
			end)
		end
	else
		warn("Player not found in database. Call may have failed, try again.")
	end
end

return BanIt
