-- // METADATA
-- Creator: Ty_Scripts
-- Date created: 2/26/2021 16:00 UTC-5
-- More info: https://devforum.roblox.com/t/banit-simple-ban-module-for-anyone/1074218
-- Version: 10

-- // VARIABLES

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local banStore = DataStoreService:GetDataStore("BanStore123456789")
local timedBanStore = DataStoreService:GetDataStore("TimedBanStore123456789")
local shadowBanStore = DataStoreService:GetDataStore("ShadowBanStore123456789")
local unbannableStore = DataStoreService:GetDataStore("UnbannableStore1234567890")
local groupStore = DataStoreService:GetDataStore("GroupStore1234567890")

local globalBans, timedBans, shadowBans, unbannables, groupBans, serverBanTable = {}, {}, {}, {}, {}, {}

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

xpcall(function()
	unbannables = unbannableStore:GetAsync("Unbannables") or {}
end, function(err)
	warn("BanIt | DataStore failed. Try turning on Studio Access to API Services. Error: " .. err)
end)

xpcall(function()
	groupBans = groupStore:GetAsync("GroupBans") or {}
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

local function saveUnbannableData()
	xpcall(function()
		unbannableStore:SetAsync("Unbannables", unbannables)
		print("BanIt | Successfully saved!")
	end, function(err)
		warn("BanIt | Data saving failed! Error: " .. err)
	end)
end

local function saveGroupData()
	xpcall(function()
		groupStore:SetAsync("Unbannables", unbannables)
		print("BanIt | Successfully saved!")
	end, function(err)
		warn("BanIt | Data saving failed! Error: " .. err)
	end)
end

local shadowBanMessages = {
	".ROBLOXWALKSPEEDJUMPPOWER failure. Please rejoin.\nIncident ticket: 0x4F5A3C4", "ACLI: Loading Error [Took Too Long (>10 Minutes)]",
	"Loading Error: PlayerGui Missing (Waited 10 Minutes)", "Invalid Client Data (r10002)",
	"Communication Key Error (r10003)", "Invalid Remote Data (r10004)",
	"Error. Client not firing remote.", "System Auth incorrect key",
	"Invalid remote key generation.", "Remote key invalid.",
}

local function onShadowBanChar(playerCharacter)
	local humanoid = playerCharacter:FindFirstChildWhichIsA("Humanoid") or playerCharacter:WaitForChild("Humanoid")
	humanoid.WalkSpeed, humanoid.JumpPower, humanoid.AutoRotate = math.random(10, 1590) / 100, math.random(10, 4900) / 100, math.random(1, 4) == 2
	for _, v in ipairs(playerCharacter:GetChildren()) do -- // Makes the character server owned creating more input lag. Also prevents movement exploiters.
		if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
			v:SetNetworkOwner(nil)
		end
	end
end

local function shadowBan(plr)
	plr.CanLoadCharacterAppearance = math.random(1, 6) == 2 -- // Makes their character appear as the default studio testing character.
	coroutine.wrap(function()
		if not plr.Character then
			plr.CharacterAdded:Wait()
		end

		task.wait(math.random(25, 99))
		plr:Kick(math.random(1, 4) == 3 and "Client Not Responding [Client hasn't checked in >5 minutes]" or shadowBanMessages[math.random(1, #shadowBanMessages)])
	end)()
	if plr.Character then
		coroutine.wrap(onShadowBanChar)(plr.Character)
	end
	plr.CharacterAdded:Connect(onShadowBanChar)
end

Players.PlayerAdded:Connect(function(plr)
	if (table.find(globalBans, plr.UserId) or table.find(serverBanTable, plr.UserId)) and table.find(unbannables, plr.UserId) == nil then
		plr:Kick("You are banned from the game!")
	elseif timedBans[tostring(plr.UserId)] ~= nil and table.find(unbannables, plr.UserId) == nil then
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
	elseif table.find(shadowBans, plr.UserId) and table.find(unbannables, plr.UserId) == nil then
		shadowBan(plr)
	elseif table.find(unbannables, plr.UserId) ~= nil then
		print("User is an unbannable!")
	else
		for i, v in ipairs(groupBans) do
			if plr:IsInGroup(v) then
				plr:Kick("You are banned from the game!")
			end
		end
		print("No data found")
	end
end)

xpcall(function()
	return MessagingService:SubscribeAsync("Ban", function(message)
		local dataTable = string.split(message.Data, "â")
		if Players:FindFirstChild(dataTable[1]) then
			Players:FindFirstChild(dataTable[1]):Kick(dataTable[2] or "You have been banned from the game.")
		end
	end)
end, function(err)
	warn("BanIt | Subscribing to ban list failed! Error: " .. err)
end)

xpcall(function()
	return MessagingService:SubscribeAsync("ShadowBan", function(message)
		local potentialPlr = Players:FindFirstChild(message.Data)
		if potentialPlr then
			shadowBan(potentialPlr)
		end
	end)
end, function(err)
	warn("BanIt | Subscribing to ban list failed! Error: " .. err)
end)

xpcall(function()
	return MessagingService:SubscribeAsync("GroupBan", function(message)
		local dataTable = string.split(message.Data, "â")
		for i, v in ipairs(Players:GetChildren()) do
			if v:IsInGroup(tonumber(dataTable[1])) then
				v:Kick(dataTable[2] or "You have been banned from the game because you are in the group with the id: " .. dataTable[1])
			end
		end
	end)
end, function(err)
	warn("BanIt | Subscribing to ban list failed! Error: " .. err)
end)

-- // MODULE

local BanIt = {}

function BanIt.ServerBan(plrUser, reason)
	reason = reason or ""
	xpcall(function()
		-- Code below gets the user ID by searching for their username then kicks them
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		if table.find(unbannables, plr) ~= nil then return end
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
	reason = reason or ""
	xpcall(function()
		-- Code below gets the user ID by searching for their username then kicks them and continues adds them to the database
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		if table.find(unbannables, plr) ~= nil then return end
		table.insert(globalBans, plr)
		saveData()
		local potentialPlr = Players:FindFirstChild(plrUser)
		if potentialPlr then
			potentialPlr:Kick(reason or "You are banned from the game!")
		else
			xpcall(function()
				return MessagingService:PublishAsync("Ban", plrUser .. "â" .. reason)
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
		-- Code below gets the user ID by searching for their username then searches for them in the database and proceeds to remove them and save data
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
		-- Code below gets the user ID by searching for their username then searches for them in the serverbantable and continues to remove them
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		local pos = table.find(serverBanTable, plr)
		table.remove(serverBanTable, pos)
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.TimedBan(plrUser, num, numType)
	xpcall(function()
		-- Code below performs an if-statement to see how many seconds a user needs to be banned for in minutes/hours or days and then gets a user id from a players name
		-- Code then proceeds to get the time from the os.time() function and kicks the user for the specified amount of time
		if numType:lower() == "minutes" then
			num *= 60
		elseif numType:lower() == "hours" then
			num *= 3600
		elseif numType:lower() == "days" then
			num *= 86400
		end
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		if table.find(unbannables, plr) ~= nil then return end
		local current = os.time()
		timedBans[plr] = current .. ";" .. num
		print(timedBans[plr])
		saveTimeData()
		if Players:FindFirstChild(plrUser) then
			Players[plrUser]:Kick("Banned for " .. num .. " " .. numType .. " from the game.")
		else
			xpcall(function()
				MessagingService:PublishAsync("Ban", plrUser .. "â" .. "Banned for " .. num .. " " .. numType .. " from the game.")
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
		-- Code finds first child (localplayer) below gets the user ID by searching for their username then kicks them with a false error
		local plr = Players:FindFirstChild(plrUser)
		if table.find(unbannables, plr) ~= nil then return end
		local plrId = assert(Players:GetUserIdFromNameAsync(plrUser), "Not found a player with that name")
		table.insert(shadowBans, plrId)
		saveShadowBanData()
		if plr then
			shadowBan(plr)
		else
			xpcall(function()
				MessagingService:PublishAsync("ShadowBan", plrUser)
			end, function(err)
				warn("Error publishing ban data. Error: " .. err)
			end)
		end
	end, warn)
end

function BanIt.ShadowUnban(plrUser)
	xpcall(function()
		-- Code below gets the user ID by searching for their username then removes the user from the shadowban datastore
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "Not found a player with that name")
		local pos = table.find(shadowBans, plr)
		table.remove(shadowBans, pos)
		saveShadowBanData()
	end, warn)
end

function BanIt.SetUnbannable(plrUser)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		table.insert(unbannables, plr)
		saveUnbannableData()
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.SetBannable(plrUser)
	xpcall(function()
		local plr = assert(Players:GetUserIdFromNameAsync(plrUser), "No player found in database!")
		if table.find(unbannables, plr) == nil then return end
		table.remove(unbannables, table.find(unbannables, plr))
		saveUnbannableData()
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.GroupBan(groupId, reason)
	xpcall(function()
		table.insert(groupBans, groupId)
		saveGroupData()
		for i, v in ipairs(Players:GetChildren()) do
			if v:IsInGroup(groupId) then
				v:Kick(reason or "You have been banned from the game because you are in the group with the id: " .. tostring(groupId))
			else
				xpcall(function()
					return MessagingService:PublishAsync("GroupBan", tostring(groupId) .. "â" .. reason)
				end, function(err)
					warn("Ban data failed to publish. Error: " .. err)
				end)
			end
		end
	end, function(err)
		warn("Error: " .. err)
	end)
end

function BanIt.GroupUnban(groupId)
	xpcall(function()
		table.remove(groupBans, table.find(groupBans, groupId))
		saveGroupData()
	end, function(err)
		warn("Error: " .. err)
	end)
end

return BanIt
