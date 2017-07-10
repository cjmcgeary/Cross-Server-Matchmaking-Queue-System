-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")

-- DataStores
local PlayerData = DataStoreService:GetDataStore("PlayerData")
local UnrankedQueue = DataStoreService:GetDataStore("UnrankedQueue") -- Key: "Uers" Value: {[UserId] = {UnrankedRating, TimeEntered}}
local RankedQueue = DataStoreService:GetDataStore("RankedQueue") -- Key: "Uers" Value: {[UserId] = {RankedRating, TimeEntered}}
local ArcadeQueue = DataStoreService:GetDataStore("ArcadeQueue") -- Key: "Uers" Value: {[UserId] = {ArcadeRating, TimeEntered}}

-- Events
local FindGameEvent = game.ReplicatedStorage.FindGameEvent

-- Variables
local PlayerTable = nil
local PlayerId = nil
local MapIds = {820182217} -- PlaceIds to be chosen at random when sending players to a match

local UnrankedUsers = nil
local RankedUsers = nil
local ArcadeUsers = nil

local UnrankedQueued = false
local RankedQueued = false
local ArcadeQueued = false



--[[ ***************  EVENTS ***************** ]]
Players.PlayerAdded:connect(function(Player) -- When player added, load the data into the variable PlayerTable
	PlayerData:UpdateAsync(Player.UserId, function(PlayerDataTable) -- Create initial rating for new players
			if not PlayerDataTable then
				PlayerDataTable = {1500, 1500, 1500, 0} -- Unranked, Ranked, Arcade, XP, Player
			end
		return PlayerDataTable
	end)
	
	PlayerTable = PlayerData:GetAsync(Player.UserId) -- Store player's rating in variable PlayerTable
	PlayerId = Player.UserId
	
	-- Display rating on Gui
end)

Players.PlayerRemoving:connect(function(Player)
	if UnrankedQueued then
		print(Player.Name .. " has left unranked queue.")
		UnrankedQueued = false
		RemovePlayerFromQueue("Quick Play", Player.UserId)
	end
		
	if RankedQueued then
		print(Player.Name .. " has left ranked queue.")
		RankedQueued = false
		RemovePlayerFromQueue("Competitive", Player.UserId)
	end
		
	if ArcadeQueued then
		print(Player.Name .. " has left arcade queue.")
		ArcadeQueued = false
		RemovePlayerFromQueue("Arcade", Player.UserId)
	end
end)

FindGameEvent.OnServerEvent:connect(function(Player, MatchType)
	local TimeEntered = os.time()
	
	if MatchType == "Quick Play" then
		print(Player.Name .. " queued for quick play match.")
		AddPlayerToQueue(MatchType, Player.UserId, TimeEntered)
		UnrankedUsers = UnrankedQueue:GetAsync("Users")
		UnrankedQueued = true
		
	elseif MatchType == "Competitive" then
		print(Player.Name .. " queued for competitive match.")
		AddPlayerToQueue(MatchType, Player.UserId, TimeEntered)
		RankedUsers = RankedQueue:GetAsync("Users")
		RankedQueued = true
		
	elseif MatchType == "Arcade" then
		print(Player.Name .. " queued for arcade match.")
		AddPlayerToQueue(MatchType, Player.UserId, TimeEntered)
		ArcadeUsers = ArcadeQueue:GetAsync("Users")
		ArcadeQueued = true
		
	else
		if UnrankedQueued then
			print(Player.Name .. " has left unranked queue.")
			RemovePlayerFromQueue("Quick Play", Player.UserId)
			UnrankedQueued = false
		end
		
		if RankedQueued then
			print(Player.Name .. " has left ranked queue.")
			RemovePlayerFromQueue("Competitive", Player.UserId)
			RankedQueued = false
		end
		
		if ArcadeQueued then
			print(Player.Name .. " has left arcade queue.")
			RemovePlayerFromQueue("Arcade", Player.UserId)
			ArcadeQueued = false
		end
	end
end)



--[[ ***************  FUNCTIONS ***************** ]]
function GetRange(WaitTime)
	if WaitTime < 10 then
		return 100
	elseif WaitTime >=10 and WaitTime < 20 then
		return 200
	elseif WaitTime >=20 and WaitTime <= 35 then
		return 300
	end
	return math.huge
end

function FindMatchedPlayer(MatchType, UserData, Range)
	
	if MatchType == "Quick Play" then
		
	elseif MatchType == "Competitive" then
		
	elseif MatchType == "Arcade" then

	end
	
	return nil
end

function AddPlayerToQueue(MatchType, UserId, TimeEntered)
	if MatchType == "Quick Play" then
		UnrankedQueue:UpdateAsync("Users", function(UnrankedQueueTable) -- Add player to queue
			if not UnrankedQueueTable then
				UnrankedQueueTable = {}
			end
			UnrankedQueueTable[tostring(UserId)] = {PlayerTable[1], TimeEntered}
			return UnrankedQueueTable
		end)
	elseif MatchType == "Competitive" then
		RankedQueue:UpdateAsync("Users", function(RankedQueueTable) -- Add player to queue
			if not RankedQueueTable then
				RankedQueueTable = {}
			end
			RankedQueueTable[tostring(UserId)] = {PlayerTable[2], TimeEntered}
			return RankedQueueTable
		end)
	elseif MatchType == "Arcade" then
		ArcadeQueue:UpdateAsync("Users", function(ArcadeQueueTable) -- Add player to queue
			if not ArcadeQueueTable then
				ArcadeQueueTable = {}
			end
			ArcadeQueueTable[tostring(UserId)] = {PlayerTable[3], TimeEntered}
			return ArcadeQueueTable
		end)
	end
end

function RemovePlayerFromQueue(MatchType, UserId)
	if MatchType == "Quick Play" then
		UnrankedQueue:UpdateAsync("Users", function(UnrankedQueueTable) -- Remove player from queue
			table.remove(UnrankedQueueTable, UserId)
			return UnrankedQueueTable
		end)
	elseif MatchType == "Competitive" then
		RankedQueue:UpdateAsync("Users", function(RankedQueueTable) -- Remove player from queue
			table.remove(RankedQueueTable, UserId)
			return RankedQueueTable
		end)
	elseif MatchType == "Arcade" then
		ArcadeQueue:UpdateAsync("Users", function(ArcadeQueueTable) -- Remove player from queue
			table.remove(ArcadeQueueTable, UserId)
			return ArcadeQueueTable
		end)
	end
end

function StartGame(UserId1, UserId2) -- Do I need the player to be able to teleport?
	print("Starting game...")
	local Player1 = PlayerData:GetAsync(UserId1)
	local Player2 = PlayerData:GetAsync(UserId2)
	local MapId = MapIds[math.random(1, #MapIds)]
	
	local NewPlaceId = AssetService:CreatePlaceAsync("Place for "..Player1.Name.." and "..Player2.Name, MapId)
	
	Player1.OnTeleport:connect(function(State, PlaceId)
		if State == Enum.TeleportState.Started then
			while true do -- Keep checking if Player1 has arrived in other instance.
				local Success, error, PlaceId, NewInstanceId = TeleportService:GetPlayerPlaceInstanceAsync(UserId1)
				if PlaceId == NewPlaceId then -- If Player1 is in the correct place then we can teleport Player2 there as well
					TeleportService:TeleportToPlaceInstance(NewPlaceId, NewInstanceId, Player2)
					return
				end
				wait()
			end
		end
	end)
	
	TeleportService:Teleport(NewPlaceId, Player1)
end


-- Matchmaking loop
while true do
	local CurrentTime = os.time()
	
	if UnrankedQueued then
		print("Getting UnrankedQueueData")
		for UserId,UserDataTable in ipairs(UnrankedUsers) do
			local Range = GetRange(CurrentTime - UnrankedUsers[tostring(PlayerId)][2])
			local MatchedPlayer = FindMatchedPlayer("Quick Play", UserDataTable, Range)
			if MatchedPlayer then
				print("Found player!")
				RemovePlayerFromQueue("Quick Play", UserId)
				RemovePlayerFromQueue("Quick Play", PlayerId)
				StartGame(UserId, PlayerId)
			end
		end
		
	elseif RankedQueued then
		print("Getting RankedQueueData")
		for UserId,UserDataTable in ipairs(RankedUsers) do
			local Range = GetRange(CurrentTime - RankedUsers[tostring(PlayerId)][2])
			local MatchedPlayer = FindMatchedPlayer("Competitive", UserDataTable, Range)
			if MatchedPlayer then
				print("Found player!")
				RemovePlayerFromQueue("Competitive", UserId)
				RemovePlayerFromQueue("Competitive", PlayerId)
				StartGame(UserId, PlayerId)
			end
		end
		
	elseif ArcadeQueued then
		print("Getting ArcadeQueueData")
		for UserId,UserDataTable in ipairs(ArcadeUsers) do
			local Range = GetRange(CurrentTime - ArcadeUsers[tostring(PlayerId)][2])
			local MatchedPlayer = FindMatchedPlayer("Arcade", UserDataTable, Range)
			if MatchedPlayer then
				print("Found player!")
				RemovePlayerFromQueue("Arcade", UserId)
				RemovePlayerFromQueue("Arcade", PlayerId)
				StartGame(UserId, PlayerId)
			end
		end
	end
	
	wait(5)
end
