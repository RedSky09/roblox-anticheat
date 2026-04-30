-- Mencatat data pergerakan pemain setiap frame
-- Output: tabel data siap export ke CSV

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local Config       = require(game.ReplicatedStorage.Shared.AntiCheatConfig)

-- Storage 
local dataLog      = {}   -- semua baris data
local prevPos      = {}   -- posisi frame sebelumnya per player
local prevSpeed    = {}   -- kecepatan frame sebelumnya per player
local cheatLabel   = {}   -- label aktif per player (diset CheatSimulator)
local sessionStart = tick()

-- Fungsi utama pencatat data 
local function recordPlayer(player)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum then return end

	local pos     = hrp.Position
	local vel     = hrp.Velocity
	local userId  = player.UserId
	local t       = tick() - sessionStart

	-- Kecepatan horizontal
	local speed   = Vector3.new(vel.X, 0, vel.Z).Magnitude

	-- Kecepatan vertikal
	local vel_y   = vel.Y

	-- Status fisika (menyentuh lantai?)
	local grounded = (hum.FloorMaterial ~= Enum.Material.Air) and 1 or 0

	-- Percepatan (perubahan kecepatan antar frame)
	local prev_spd = prevSpeed[userId] or speed
	local acc      = math.abs(speed - prev_spd)

	-- Perpindahan posisi antar frame
	local prev_p   = prevPos[userId] or pos
	local pos_delta = (pos - prev_p).Magnitude

	-- Label saat ini
	local label = cheatLabel[userId] or "normal"

	-- Simpan baris data
	table.insert(dataLog, {
		t         = math.round(t * 1000) / 1000,
		player    = player.Name,
		x         = math.round(pos.X * 100) / 100,
		y         = math.round(pos.Y * 100) / 100,
		z         = math.round(pos.Z * 100) / 100,
		speed     = math.round(speed * 100) / 100,
		vel_y     = math.round(vel_y * 100) / 100,
		grounded  = grounded,
		acc       = math.round(acc * 100) / 100,
		pos_delta = math.round(pos_delta * 100) / 100,
		label     = label,
	})

	-- Update nilai sebelumnya
	prevPos[userId]   = pos
	prevSpeed[userId] = speed

	-- Auto export jika data sudah banyak
	if #dataLog >= Config.MAX_LOG_SIZE then
		exportCSV()
	end
end

-- export ke CSV 
function exportCSV()
	if #dataLog == 0 then
		warn("[DataCollector] Tidak ada data untuk diekspor.")
		return
	end

	-- Header
	local lines = {
		"timestamp,player,x,y,z,speed,vel_y,grounded,acc,pos_delta,label"
	}

	-- Isi data
	for _, row in ipairs(dataLog) do
		table.insert(lines, string.format(
			"%.3f,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%d,%.2f,%.2f,%s",
			row.t, row.player,
			row.x, row.y, row.z,
			row.speed, row.vel_y,
			row.grounded,
			row.acc, row.pos_delta,
			row.label
			))
	end

	-- Print ke Output Roblox Studio
	-- Copy-paste hasilnya ke file .csv di komputer
	print("\n===== CSV EXPORT START =====")
	print(table.concat(lines, "\n"))
	print("===== CSV EXPORT END =====")
	print(string.format("[DataCollector] %d baris data diekspor.", #dataLog))

	-- Reset log setelah export
	dataLog = {}
end

-- Public API (bisa dipanggil script lain) 
-- Fungsi ini dipanggil oleh CheatSimulator untuk set label
local DataCollector = {}

function DataCollector.setLabel(player, label)
	cheatLabel[player.UserId] = label
	if Config.DEBUG_MODE then
		print(string.format(
			"[DataCollector] Label '%s' → %s",
			label, player.Name
			))
	end
end

function DataCollector.exportNow()
	exportCSV()
end

function DataCollector.getCount()
	return #dataLog
end

-- Event: player join/leave 
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		prevPos[player.UserId]   = nil
		prevSpeed[player.UserId] = nil
		cheatLabel[player.UserId] = "normal"
		if Config.DEBUG_MODE then
			print("[DataCollector] Mulai rekam: " .. player.Name)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	prevPos[player.UserId]    = nil
	prevSpeed[player.UserId]  = nil
	cheatLabel[player.UserId] = nil
end)

-- Loop utama pencatatan 
local timer = 0
RunService.Heartbeat:Connect(function(dt)
	if not Config.COLLECTING_DATA then return end
	timer += dt
	if timer >= Config.RECORD_INTERVAL then
		timer = 0
		for _, player in Players:GetPlayers() do
			recordPlayer(player)
		end
	end
end)

-- Command via chat untuk kontrol manual 
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		-- Hanya bisa dipakai saat playtesting (bukan production)
		if msg == "/export" then
			exportCSV()
		elseif msg == "/count" then
			print("[DataCollector] Data terkumpul: " .. #dataLog .. " baris")
		elseif msg == "/normal" then
			DataCollector.setLabel(player, "normal")
		end
	end)
end)

-- Expose ke script lain via _G (global)
_G.DataCollector = DataCollector

if Config.DEBUG_MODE then
	print("[DataCollector] Aktif — interval: " .. Config.RECORD_INTERVAL .. "s")
end