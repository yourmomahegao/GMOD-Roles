print( "-----------------------" )
print( "YMA Roles is loading..." )

util.AddNetworkString("AnnounceRoleChange")
util.AddNetworkString("GetClosestRole")
util.AddNetworkString("GiveClosestRole")

PlayerRolesWithoutImune = {"user", "level1", "level2", "level3", "level4", "level5"}
PlayerLevelRoles = {"level1", "level2", "level3", "level4", "level5"}
PlayerRolesTime = {0, 7200, 86400, 172800, 259200}

-- Creating roles directory
if not file.Exists("ymaroles", "DATA") then
	file.CreateDir("ymaroles")
end

-- Creating roles data file
if not file.Exists("ymaroles/players.json", "DATA") then
	file.Write("ymaroles/players.json", "{}")
end

-- Checks is player info is nil
if PlayersInfo == nil then PlayersInfo = {} end

-- Getting closest time, that any role req
local function GetClosestTimeValue(val)
	local level = 0

	-- Getting level acording to val
	for i, prt in pairs(PlayerRolesTime) do
		if ((os.time() - val) - prt) > 0 then
			level = level + 1
		end
	end

	-- Change level if level equal 0
	if level == 0 then level = 1 end

	return level, PlayerLevelRoles[level]
end

-- Checks is SteamId is in table
local function IsSteamIDInsideTable(steamid, tbl_players_info)
	local is_inside = false

	-- Check every player info in table
	for i, info in pairs(tbl_players_info) do
		-- Checks target SteamID
		if info[1]['steamid'] != nil then
			if steamid == info[1]['steamid'] then
				is_inside = true
				return i, is_inside
			end
		else
			return "steamidnull", is_inside
		end
	end

	return nil, is_inside
end

-- Checks is player role is wrong
local function CheckIsRoleIsWrong(ply, tbl_players_info)
	-- Check every player info in table
	for i, info in pairs(tbl_players_info) do
		-- Checks target SteamID and Role
		if info[1]['role'] != nil and info[1]['time'] != nil and info[1]['steamid'] == ply:SteamID() then
			-- Get req role for that player
			local RoleIndex, ReqRole = GetClosestTimeValue(info[1]['time'])
			
			-- Checks immune
			if table.HasValue(PlayerRolesWithoutImune, ply:GetUserGroup()) then
				-- If role is wrong sets req role
				if ReqRole != info[1]['role'] then
					-- Advert level changing
					for i, p in ipairs( player.GetAll() ) do
						net.Start("AnnounceRoleChange", false)
							net.WriteEntity(player.GetBySteamID(info[1]['steamid']))
							net.WriteString(tostring(RoleIndex))
						net.Send(p)
					end

					-- Setting up usergroup
					ply:SetUserGroup(ReqRole)

					-- Change info in table
					info[1]['role'] = ReqRole
				end
			end
		end
	end
end

-- Giving role and time for requested player
net.Receive("GetClosestRole", function()
	steamid = net.ReadString()
	ply = net.ReadEntity()

	local SteamIdIndex, IsHasSteamID = IsSteamIDInsideTable(steamid, PlayersInfo)
	local time = PlayersInfo[SteamIdIndex][1]['time']
	local level, next_role = GetClosestTimeValue(time)
	local current_role = PlayersInfo[SteamIdIndex][1]['role']

	net.Start("GiveClosestRole")
		net.WriteInt(time, 32)
		net.WriteInt(level, 32)
		net.WriteString(current_role)
		net.WriteString(next_role)
		net.WriteTable(PlayerRolesWithoutImune)
	net.Send(ply)
end)

-- Refreshing database
timer.Create("RefreshRolesDatabase", 5, 0, function()
	-- Getting info from json data file
	PlayersInfoFile = file.Open("ymaroles/players.json", "r", "DATA")
		PlayersInfo = util.JSONToTable(PlayersInfoFile:Read())
	PlayersInfoFile:Close()

	-- Get all players
	local Players = player.GetAll()
	-- Get all players SteamID
	local PlayersSteamID = {}
	for i, ply in pairs(Players) do table.insert(PlayersSteamID, i, ply:SteamID()) end

	-- Add or update player in json file
	for i, ply in pairs(Players) do
		-- Check is steamid is already written and giving steam id index
		local PlayerSteamID = ply:SteamID()
		if PlayerSteamID != nil then
			local SteamIdIndex, IsHasSteamID = IsSteamIDInsideTable(PlayerSteamID, PlayersInfo)

			if IsHasSteamID then
				local PlayersTempInfo = util.JSONToTable('[{"steamid": "' .. PlayerSteamID .. '", "time": "' .. PlayersInfo[SteamIdIndex][1]['time'] .. '", "role": "' .. ply:GetUserGroup() .. '"}]')
				PlayersInfo[SteamIdIndex] = PlayersTempInfo
			else
				if SteamIdIndex != "steamidnull" then
					local PlayersTempInfo = util.JSONToTable('[{"steamid": "' .. PlayerSteamID .. '", "time": "' .. os.time() .. '", "role": "' .. ply:GetUserGroup() .. '"}]')
					table.insert(PlayersInfo, table.Count(PlayersInfo), PlayersTempInfo)
				end
			end
		end
	end

	-- Checking players roles
	for i, ply in pairs(Players) do CheckIsRoleIsWrong(ply, PlayersInfo) end

	-- Writing info to json data file
	PlayersInfoFile = file.Open("ymaroles/players.json", "w", "DATA")
		PlayersInfoFile:Write(util.TableToJSON(PlayersInfo, true))
	PlayersInfoFile:Close()
end)