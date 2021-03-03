-- // METADATA
-- Creator: Ty_Scripts
-- Date created: 2/26/2021 16:00 UTC-5
-- More info: https://devforum.roblox.com/t/banit-simple-ban-module-for-anyone/1074218
-- Version: 8

-- // VARIABLES

local serverBanTable = {}

local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local banStore = DSS:GetDataStore("BanStore" .. game.PlaceId .. "123456789")
local timedBanStore = DSS:GetDataStore("TimedBanStore" .. game.PlaceId .. "123456789")
local shadowBanStore = DSS:GetDataStore("ShadowBanStore".. game.PlaceId .. "123456789")
local globalBans, timedBans, shadowBans = {}, {}, {}

xpcall(function()
	globalBans = banStore:GetAsync("Bans") or {}
end, function(err)
	warn("BanIt | DataStore failed. Try turning on Studio Access to API Services. Error: " .. err)
end)

xpcall(function()
	timedBans = timedBanStore:GetAsync("TimedBans") or {}
end, function(err)
	warn("BanIt | DataStore failed. Try turning on Studio Access to API Services. Error: " .. err)
end)

xpcall(function()
	shadowBans = shadowBanStore:GetAsync("ShadowBans") or {}
end, function(err)
	warn("BanIt | DataStore failed. Try turning on Studio Access to API Services. Error: " .. err)
end)


-- // FUNCTIONS

local function saveData()
	xpcall(function()
		banStore:SetAsync("Bans", globalBans)
		print("BanIt | Successfully saved!")
	end, function(err)
		warn("BanIt | Data saving failed! Error: " .. err)
	end)
end

local function saveTimeData()
	xpcall(function()
		timedBanStore:SetAsync("TimedBans", timedBans)
		print("BanIt | Successfully saved!")
	end, function(err)
		warn("BanIt | Data saving failed! Error: " .. err)
	end)
end

local function saveShadowBanData()
	xpcall(function()
		shadowBanStore:SetAsync("ShadowBans", shadowBans)
		print("BanIt | Successfully saved!")
	end, function(err)
		warn("BanIt | Data saving failed! Error: " .. err)
	end)
end

local ShadowBan
do
	local ShadowBanMessages = {
		".ROBLOXWALKSPEEDJUMPPOWER failure. Please rejoin.\nIncident ticket: 0x4F5A3C4", "ACLI: Loading Error [Took Too Long (>10 Minutes)]",
		"Loading Error: PlayerGui Missing (Waited 10 Minutes)", "Invalid Client Data (r10002)",
		"Communication Key Error (r10003)", "Invalid Remote Data (r10004)",
		"Client Not Responding [Client hasn't checked in >5 minutes]", "Error. Client not firing remote.",
		"Invalid remote key generation.", "Remote key invalid.",
		"System Auth incorrect key",
	}
	
	local function onShadowBanChar(playerCharacter)
		local humanoid = playerCharacter:FindFirstChildWhichIsA("Humanoid") or playerCharacter:WaitForChild("Humanoid")
		humanoid.WalkSpeed = math.random(1, 1500) / 100
		humanoid.JumpPower = math.random(1, 4000) / 100
		if math.random(1, 2) == 2 then -- // Makes the character server owned creating more input lag. Also prevents movement exploiters.
			for _, v in ipairs(playerCharacter:GetChildren()) do
				if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
					v:SetNetworkOwner(nil)
				end
			end
		end
		if math.random(1, 3) == 2 then -- // Makes their character not able to turn unless in first person
			humanoid.AutoRotate = false
		else
			hu
		end
		wait(math.random(29, 70))
		plr:Kick(ShadowBanMessages[math.random(1, #ShadowBanMessages)])	
	end
	
	shadowBan = function(plr)
		if math.random(1, 6) == 2 then -- // Makes their character appear as the default studio testing character.
			plr.CanLoadCharacterAppearance = false
		end
		coroutine.wrap(onShadowBanChar)(plr.Character or plr.CharacterAdded:Wait())
		plr.CharacterAdded:Connect(onShadowBanChar)
	end
end

Players.PlayerAdded:Connect(function(plr)
	if table.find(globalBans, plr.UserId) or table.find(serverBanTable, plr.UserId) then
		plr:Kick("You are banned from the game!")
	elseif timedBans[tostring(plr.UserId)] ~= nil then
		for k, v in pairs(timedBans) do
			print(k, v)
		end
		local banData = string.split(timedBans[tostring(plr.UserId)], ";")
		local timeLeft = os.time() - tonumber(banData[1])
		local banLength = tonumber(banData[2]) 
		if banLength - timeLeft >= 1 then
			plr:Kick(tostring(banLength - timeLeft) .. " seconds left on ban.")
		else
			timedBans[tostring(plr.UserId)] = nil
			saveTimeData()
			if table.find(globalBans, plr.UserId) or table.find(serverBanTable, plr.UserId) then
				plr:Kick("You are banned from the game!")
			elseif table.find(shadowBans, plr.UserId) then
				shadowBan(plr)
			else
				print("No data found")
			end
		end
	elseif table.find(shadowBans, plr.UserId) then
		shadowBan(plr)
	else
		print("No data found")
	end
end)

xpcall(function()
	return MS:SubscribeAsync("Ban", function(message)
		local dataTable = string.split(message.Data, "⌐")
		if Players:FindFirstChild(dataTable[1]) then
			Players:FindFirstChild(dataTable[1]):Kick(dataTable[2] or "You have been banned from the game.")
		end
	end)
end, function(err)
	warn("BanIt | Subscribing to ban list failed! Error: " .. err)
end)

xpcall(function()
	return MS:SubscribeAsync("ShadowBan", function(message)
		local potentialPlr = Players:FindFirstChild(message.Data)
		if potentialPlr then
			shadowBan(potentialPlr)
		end
	end)
end, function(err)
	warn("BanIt | Subscribing to ban list failed! Error: " .. err)
end)

-- // MODULE

local BanIt = {}

function BanIt.ServerBan(plrUser, reason)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		table.insert(serverBanTable, plr)
		local potentialPlr = Players:FindFirstChild(plrUser)
		if potentialPlr then
			potentialPlr:Kick(reason or "You are banned from the server!")
		end
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.Ban(plrUser, reason)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		table.insert(globalBans, plr)
		saveData()
		local potentialPlr = Players:FindFirstChild(plrUser)
		if potentialPlr then
			potentialPlr:Kick(reason or "You are banned from the game!")
		else
			xpcall(function()
				return MS:PublishAsync("Ban", plrUser .. "⌐" .. reason)
			end, function(err)
				warn("Ban data failed to publish. Error: " .. err)
			end)
		end
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.Unban(plrUser)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		local pos = table.find(globalBans, plr)
		table.remove(globalBans, pos)
		saveData()
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.ServerUnban(plrUser)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		local pos = table.find(serverBanTable, plr)
		table.remove(serverBanTable, pos)
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.TimedBan(plrUser, num, numType)
	xpcall(function()
		if numType:lower() == "minutes" then
			num *= 60
		elseif numType:lower() == "hours" then
			num *= 3600
		elseif numType:lower() == "days" then
			num *= 86400
		end
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		local current = os.time()
		timedBans[plr] = current .. ";" .. num
		print(timedBans[plr])
		saveTimeData()
		if Players:FindFirstChild(plrUser) then
			Players[plrUser]:Kick("Banned for " .. num .. " " .. numType .. " from the game.")
		else
			xpcall(function()
				MS:PublishAsync("Ban", plrUser .. "⌐" .. "Banned for " .. num .. " " .. numType .. " from the game.")
			end, function(err)
				warn("Error publishing ban data. Error: " .. err)
			end)
		end
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.ShadowBan(plrUser)
	xpcall(function()
		local plr = Players:FindFirstChild(plrUser)
		local plrId = assert(Players:GetUserIdFromNameAsync(plrUser), "Not found a player with that name")
		table.insert(shadowBans, plrId)
		saveShadowBanData()
		if plr then
			shadowBan(plr)
		else
			xpcall(function()
				MS:PublishAsync("ShadowBan", plrUser)
			end, function(err)
				warn("Error publishing ban data. Error: " .. err)
			end)
		end
	end, function(err)
		warn(err)
	end)
end

function BanIt.ShadowUnban(plrUser)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "Not found a player with that name")
		local pos = table.find(shadowBans, plr)
		table.remove(shadowBans, pos)
		saveShadowBanData()
	end, function(err)
		warn(err)
	end)
end

return BanIt
