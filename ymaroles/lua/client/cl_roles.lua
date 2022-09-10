function sendmsg()
	local Player = net.ReadEntity()
	local LevelIndex = net.ReadString()

	chat.AddText( Color(100, 255, 100), "[Уровни] ", team.GetColor(Player:Team()), Player:Name(), Color(255, 255, 255), " перешёл на ", team.GetColor(Player:Team()), "Уровень " .. LevelIndex)
end

hook.Add("OnPlayerChat", "GetPlayerRoleInfo", function(ply, txt, teamChat, isDead)
	if ply == LocalPlayer() and string.lower(txt) == "!level" then
		net.Start("GetClosestRole")
			net.WriteString(LocalPlayer():SteamID())
			net.WriteEntity(LocalPlayer())
		net.SendToServer()
	end
end)

-- Giving info about player level
net.Receive("GiveClosestRole", function()
	-- Getting some values
	local time = net.ReadInt(32)
	local level = net.ReadInt(32)
	local current_role = net.ReadString()
	local next_role = net.ReadString()
	local players_without_immune = net.ReadTable()

	if table.HasValue(players_without_immune, current_role) then
		if level >= 5 then
			chat.AddText( Color(100, 255, 100), "[Уровни] ", team.GetColor(LocalPlayer():Team()), LocalPlayer():Name(), Color(255, 255, 255), " сейчас на уровне: ", team.GetColor(LocalPlayer():Team()), "Уровень " .. level)
			chat.AddText( Color(100, 255, 100), "[Уровни] ", Color(255, 255, 255), "Вы достигли максимального уровня, спасибо за ваш вклад в сервер!")
		elseif level < 5 then
			chat.AddText( Color(100, 255, 100), "[Уровни] ", team.GetColor(LocalPlayer():Team()), LocalPlayer():Name(), Color(255, 255, 255), " сейчас на уровне: ", team.GetColor(LocalPlayer():Team()), "Уровень " .. level)
			chat.AddText( Color(100, 255, 100), "[Уровни] ", Color(255, 255, 255), "Для перехода на следующий уровень: ")
			chat.AddText( Color(100, 255, 100), "[Уровни] ", Color(255, 255, 255), "Отыграйте ещё " .. tostring(math.Round(((os.time() - time) / 60 / 60), 2)) .. " часов.")
		end
	else
		chat.AddText( Color(100, 255, 100), "[Уровни] ", team.GetColor(LocalPlayer():Team()), LocalPlayer():Name(), Color(255, 255, 255), ", ваша группа не позволяет вам получать уровни.")
	end
end)

net.Receive("AnnounceRoleChange", sendmsg)