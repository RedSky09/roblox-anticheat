local Config = {

	-- parameter fisika
	NORMAL_WALKSPEED    = 16,   -- WalkSpeed default Roblox
	NORMAL_JUMPPOWER    = 50,   -- JumpPower default Roblox
	MAX_LEGIT_SPEED     = 30,   -- batas atas kecepatan normal
	MAX_POSITION_DELTA  = 50,   -- batas perpindahan posisi wajar per frame

	-- parameter collect data
	RECORD_INTERVAL     = 0.05, -- catat data setiap 0.05 detik (20 fps)
	MAX_LOG_SIZE        = 5000, -- maksimal baris data sebelum auto-export

	-- parameter deteksi (diisi after training)
	ANOMALY_THRESHOLD   = 0.05, -- placeholder, diganti hasil Python nanti

	-- parameter aksi / keputusan
	WARN_LIMIT          = 3,    -- jumlah warning sebelum kick
	BAN_AFTER_KICKS     = 2,    -- jumlah kick sebelum ban

	-- mode
	DEBUG_MODE          = true, -- tampilkan log di output
	COLLECTING_DATA     = true, -- true = mode kumpul data, false = mode deteksi
}

return Config