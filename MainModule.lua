-- // METADATA
-- Creator: Ty_Scripts
-- Date created: 2/26/2021 16:00 UTC-5
-- More info: https://devforum.roblox.com/t/banit-simple-ban-module-for-anyone/1074218
-- Version: 7

-- // OUTPUT PREFIX
local OldPrint, OldWarn = print, warn
local print, warn = function(...)
	OldPrint("BanIt | ", ...)
end, function(...)
	OldWarn("BanIt-Warning | ", ...)
end

-- // VARIABLES

local ServerBans = {}

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local BanStore = DataStoreService:GetDataStore(string.format("BanStore%d123456789", game.PlaceId))
local TimeBanStore = DataStoreService:GetDataStore(string.format("TimedBanStore%d123456789", game.PlaceId))
local GlobalBans, TimeBans

xpcall(function()
	GlobalBans = BanStore:GetAsync("Bans") or {}
end, function(Err)
	warn("DataStore failed. Try turning on Studio Access to API Services. Reason: ", Err)
end)

xpcall(function()
	TimeBans = TimeBanStore:GetAsync("TimedBans") or {}
end, function(Err)
	warn("DataStore failed. Try turning on Studio Access to API Services. Reason: ", Err)
end)

-- // FUNCTIONS

local function saveData()
	xpcall(function()
		BanStore:SetAsync("Bans", GlobalBans)
		print("Successfully saved")
	end, function(Err)
		warn(Err)
	end)
end

local function saveTimeData()
	xpcall(function()
		TimeBanStore:SetAsync("TimedBans", TimeBans)
		print("Successfully saved")
		for i, v in pairs(TimeBans) do
			print(i, v)
		end
	end, function(Err)
		warn(Err)
	end)
end

Players.PlayerAdded:Connect(function(Plr)
	if table.find(GlobalBans, Plr.UserId) or table.find(ServerBans, Plr.UserId) then
		Plr:Kick("Banned from the game!")
	elseif TimeBans[tostring(Plr.UserId)] ~= nil then
		local BanData = string.split(TimeBans[tostring(Plr.UserId)], ";")
		local TimeLeft = os.time() - tonumber(BanData[1])
		local BanLenght = tonumber(BanData[2]) 
		
		if BanLenght - TimeLeft >= 1 then
			Plr:Kick(tostring(BanLenght - TimeLeft) .. " seconds left on ban.")
		end
	elseif not TimeBans[tostring(Plr.UserId)] then
		print("No data for user " .. Plr.Name)
	end
end)

xpcall(function()
	MessagingService:SubscribeAsync("Ban", function(Message)
		local dataTable = string.split(Message.Data, "⌐")
		if Players:FindFirstChild(dataTable[1]) then
			Players:FindFirstChild(dataTable[1]):Kick(dataTable[2] or "You have been banned.")
		end
	end)
end, warn)

-- // MODULE

local BanIt = {}

function BanIt.ServerBan(PlrInstance, Reason)
	xpcall(function()
		local Plr = Players:GetUserIdFromNameAsync(PlrInstance)
		
		table.insert(ServerBans, Plr)
		local FoundPlayer = Players:FindFirstChild(PlrInstance)
		if FoundPlayer then
			FoundPlayer:Kick(Reason or "Banned from the server!")
		end
	end, function(Err)
		warn("Player not found in database. Call may have failed, try again. Reason: ", Err)
	end)
end

function BanIt.Ban(PlrInstance, Reason)
	xpcall(function()
		local Plr = Players:GetUserIdFromNameAsync(PlrInstance)

		table.insert(GlobalBans, Plr)
		saveData()
		
		local FoundPlayer = Players:FindFirstChild(PlrInstance)
		if FoundPlayer then
			FoundPlayer:Kick(Reason or "Banned from the game!")
		else
			xpcall(function()
				MessagingService:PublishAsync("Ban", PlrInstance .. "⌐" .. Reason)
			end, warn)
		end
	end, function(Err)
		warn("Player not found in database. Call may have failed, try again. Reason: ", Err)
	end)
end

function BanIt.Unban(PlrInstance)
	xpcall(function()
		local Plr = assert(Players:GetUserIdFromNameAsync(PlrInstance), "No player returned by Players:GetUserIdFromNameAsync().")

		local i = table.find(GlobalBans, Plr)
		
		print(i)
		table.remove(GlobalBans, i)
		print(GlobalBans[i])
		saveData()
	end, function(Err)
		warn("Player not found in database. Call may have failed, try again. Reason: ", Err)
	end)
end

function BanIt.ServerUnban(PlrInstance)
	xpcall(function()
		local Plr = assert(Players:GetUserIdFromNameAsync(PlrInstance), "No player returned by Players:GetUserIdFromNameAsync().")

		local i = table.find(ServerBans, Plr)
		
		print(i)
		table.remove(ServerBans, i)
		print(ServerBans[i])
		saveData()
	end, function(Err)
		warn("Player not found in database. Call may have failed, try again. Reason: ", Err)
	end)
end

function BanIt.TimedBan(PlrInstance, BanLenght, TimeType)
	if string.lower(TimeType) == "minutes" then
		BanLenght *= 60
	elseif string.lower(TimeType) == "hours" then
		BanLenght *= 3600
	elseif string.lower(TimeType) == "days" then
		BanLenght *= 86400
	end
	xpcall(function()
		local Plr = Players:GetUserIdFromNameAsync(PlrInstance)
		
		TimeBans[Plr] = os.time() .. ";" .. BanLenght
		print(TimeBans[Plr])
		saveTimeData()
		if Players:FindFirstChild(PlrInstance) then
			Players[PlrInstance]:Kick("Banned for " .. BanLenght .. " " .. TimeType .. " from the game.")
		else
			xpcall(function()
				MessagingService:PublishAsync("Ban", PlrInstance .. "⌐" .. "Banned for " .. BanLenght .. " " .. TimeType .. " from the game.")
			end, warn)
		end
	end, function(Err)
		warn("Player not found in database. Call may have failed, try again. Reason: ", Err)
	end)
end

return BanIt
