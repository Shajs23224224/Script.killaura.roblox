-- OrbSpawnerUnified.lua
-- Único Script para crear spawner de 3 esferas cada 2s alrededor del jugador,
-- que se acercan y curan ligeramente al tocar. También inyecta el LocalScript al cliente.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- Nombres de RemoteEvents
local REQUEST_EVENT_NAME = "OrbSpawnerRequestEvent"   -- cliente -> servidor (start/stop)
local FEEDBACK_EVENT_NAME = "OrbSpawnerFeedbackEvent" -- servidor -> cliente (feedback visual/sonoro)

-- Crear RemoteEvents si no existen
local function ensureRemote(name)
	if ReplicatedStorage:FindFirstChild(name) then
		return ReplicatedStorage[name]
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = ReplicatedStorage
	return ev
end

local RequestEvent = ensureRemote(REQUEST_EVENT_NAME)
local FeedbackEvent = ensureRemote(FEEDBACK_EVENT_NAME)

-- =======================
-- CONFIGURACIÓN (modifica si quieres)
-- =======================
local SPAWN_INTERVAL = 2.0         -- segundos entre lotes de 3 esferas
local ORBS_PER_BATCH = 3
local ORB_RADIUS = 0.2             -- distancia inicial desde HRP (studs). ≈ 0.2 studs ≈ 5 cm
local ORB_SIZE = 0.4               -- diámetro de la esfera en studs
local ORB_SPEED = 3.0              -- studs por segundo (velocidad hacia el jugador)
local ORB_LIFETIME = 12            -- segundos máximo por orb
local HEAL_ON_HIT = 8              -- puntos de vida restaurados al tocar
local HEAL_DISTANCE = 1.0          -- distancia (studs) para considerar "toque" y curar
local MAX_ACTIVE_ORBS_PER_PLAYER = 30
local SPAWNER_COOLDOWN = 0.5       -- secs entre requests para evitar spam
-- =======================

-- tablas de control
local playerSpawnerActive = {}     -- [player] = true/false
local playerLastRequest = {}       -- [player] = tick()
local playerActiveOrbCount = {}    -- [player] = n

-- Helper para crear orb servidor-side (visible para todos)
local function createOrbPart(spawnPosition)
	local orb = Instance.new("Part")
	orb.Name = "HealingOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(ORB_SIZE, ORB_SIZE, ORB_SIZE)
	orb.Anchored = true -- la movemos manualmente
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.BrickColor = BrickColor.new("Bright red")
	orb.CFrame = CFrame.new(spawnPosition)
	orb.Parent = workspace

	-- Luz y partículas para que brillen
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 60, 60)
	pl.Range = 8
	pl.Brightness = 2
	pl.Parent = orb

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "OrbParticles"
	-- textura por defecto (roblox) — puedes cambiar por un asset si quieres
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Rate = 20
	emitter.Lifetime = NumberRange.new(0.25, 0.6)
	emitter.Speed = NumberRange.new(0.05, 0.3)
	emitter.Size = NumberSequence.new(ORB_SIZE * 0.7)
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 80, 80))
	emitter.Parent = orb

	return orb
end

-- Mover la orb hacia el HRP del player y detectar colisión por distancia
local function moveOrbTowardsPlayer(player, orb)
	local startTime = tick()
	-- safety: si player desconecta o muere, terminar
	while orb and orb.Parent and tick() - startTime <= ORB_LIFETIME do
		if not player or not player.Parent then break end
		local char = player.Character
		if not char then break end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid then break end

		local dt = RunService.Heartbeat:Wait()
		local currentPos = orb.Position
		local targetPos = hrp.Position
		local dir = targetPos - currentPos
		local dist = dir.Magnitude

		-- Si está dentro de distancia de curación -> aplicar heal (servidor-side)
		if dist <= HEAL_DISTANCE then
			if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
				local newHealth = math.min(humanoid.Health + HEAL_ON_HIT, humanoid.MaxHealth)
				humanoid.Health = newHealth
			end

			-- enviar feedback al jugador (cliente puede reproducir sonido/vfx)
			pcall(function()
				FeedbackEvent:FireClient(player, {type = "heal", position = orb.Position})
			end)

			orb:Destroy()
			playerActiveOrbCount[player] = math.max(0, (playerActiveOrbCount[player] or 1) - 1)
			return
		end

		-- mover hacia el objetivo
		if dist > 0.001 then
			local moveStep = math.min(ORB_SPEED * dt, dist)
			local newPos = currentPos + dir.Unit * moveStep
			orb.CFrame = CFrame.new(newPos)
		end
	end

	-- Expiró o condiciones invalidas -> destruir
	if orb and orb.Parent then
		orb:Destroy()
		playerActiveOrbCount[player] = math.max(0, (playerActiveOrbCount[player] or 1) - 1)
	end
end

-- Spawnea ORBS_PER_BATCH orbs alrededor del HRP del jugador
local function spawnBatchForPlayer(player)
	if not player or not player.Parent then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	playerActiveOrbCount[player] = playerActiveOrbCount[player] or 0
	if playerActiveOrbCount[player] >= MAX_ACTIVE_ORBS_PER_PLAYER then
		return
	end

	-- 3 posiciones en ángulo: 0°, 120°, 240°
	local anglesDeg = {0, 120, 240}
	for i = 1, ORBS_PER_BATCH do
		if playerActiveOrbCount[player] >= MAX_ACTIVE_ORBS_PER_PLAYER then break end

		local ang = math.rad(anglesDeg[i])
		local offset = Vector3.new(math.cos(ang) * ORB_RADIUS, 0.5, math.sin(ang) * ORB_RADIUS)
		local spawnPos = hrp.Position + offset

		local orb = createOrbPart(spawnPos)
		playerActiveOrbCount[player] = (playerActiveOrbCount[player] or 0) + 1

		-- mover orb en coroutine para no bloquear
		coroutine.wrap(function()
			moveOrbTowardsPlayer(player, orb)
		end)()

		-- limpieza en caso de que no toque (safety)
		Debris:AddItem(orb, ORB_LIFETIME + 1)
	end
end

-- Loop de spawner por jugador
local function startSpawnerForPlayer(player)
	if not player or not player.Parent then return end
	if playerSpawnerActive[player] then return end

	playerSpawnerActive[player] = true
	playerActiveOrbCount[player] = playerActiveOrbCount[player] or 0

	coroutine.wrap(function()
		while playerSpawnerActive[player] do
			if not player or not player.Parent then break end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				spawnBatchForPlayer(player)
			end

			-- esperar intervalo con Heartbeat para precisión y posibilidad de cancelar
			local waited = 0
			while waited < SPAWN_INTERVAL do
				if not playerSpawnerActive[player] then break end
				local dt = RunService.Heartbeat:Wait()
				waited = waited + dt
			end
		end
		playerSpawnerActive[player] = nil
	end)()
end

local function stopSpawnerForPlayer(player)
	playerSpawnerActive[player] = nil
end

-- Manejar requests desde cliente
RequestEvent.OnServerEvent:Connect(function(player, data)
	local now = tick()
	if playerLastRequest[player] and now - playerLastRequest[player] < SPAWNER_COOLDOWN then
		return
	end
	playerLastRequest[player] = now

	if type(data) ~= "table" or type(data.action) ~= "string" then return end

	if data.action == "start" then
		startSpawnerForPlayer(player)
	elseif data.action == "stop" then
		stopSpawnerForPlayer(player)
	end
end)

-- Limpieza cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	playerSpawnerActive[player] = nil
	playerLastRequest[player] = nil
	playerActiveOrbCount[player] = nil
end)
-- Asegurar que se para cuando muere/respawnea
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		playerSpawnerActive[player] = nil
	end)
end)

-- =========================
-- INYECTAR LocalScript en cada jugador (cliente)
-- =========================
-- Contenido del LocalScript (se inyecta como texto). El LocalScript:
--  * pide al servidor start cuando aparece el Character
--  * pide stop cuando muere/respawnea
--  * escucha feedback del servidor para reproducir sonido/vfx local
local localScriptSource = [[
-- OrbSpawnerClient (inyectado automáticamente)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local REQUEST_EVENT_NAME = "]] .. REQUEST_EVENT_NAME .. [["
local FEEDBACK_EVENT_NAME = "]] .. FEEDBACK_EVENT_NAME .. [["

local requestRemote = ReplicatedStorage:WaitForChild(REQUEST_EVENT_NAME)
local feedbackRemote = ReplicatedStorage:WaitForChild(FEEDBACK_EVENT_NAME)
local player = Players.LocalPlayer

-- Reproducir sonido local y efecto breve cuando el servidor manda feedback
local function playHealFeedback(worldPosition)
	-- sonido local
	local sound = Instance.new("Sound")
	-- (opcional) cambia rbxassetid por tu asset si quieres un SFX concreto
	sound.SoundId = "rbxasset://sounds\\heal.wav"
	sound.Volume = 1
	sound.Looped = false
	sound.Parent = workspace.CurrentCamera or workspace
	sound:Play()
	Debris:AddItem(sound, 2)

	-- flash GUI breve
	local gui = Instance.new("ScreenGui")
	gui.Name = "OrbHealFlash"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local rect = Instance.new("Frame")
	rect.Size = UDim2.new(1,0,1,0)
	rect.BackgroundTransparency = 0.85
	rect.BackgroundColor3 = Color3.fromRGB(255,100,100)
	rect.Parent = gui
	game:GetService("TweenService"):Create(rect, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
	Debris:AddItem(gui, 0.8)
end

-- Recibir feedback del servidor
feedbackRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.type == "heal" then
		-- payload.position puede usarse para spawn de VFX locales si quieres
		pcall(function()
			playHealFeedback(payload.position)
		end)
	end
end)

-- Pedir al servidor iniciar/stop spawner cuando aparece tu Character
local function requestStart()
	pcall(function() requestRemote:FireServer({action = "start"}) end)
end
local function requestStop()
	pcall(function() requestRemote:FireServer({action = "stop"}) end)
end

player.CharacterAdded:Connect(function()
	wait(0.25)
	requestStart()
end)

player.CharacterRemoving:Connect(function()
	requestStop()
end)

-- Si ya tenía character (por si se inyecta tarde)
if player.Character then
	wait(0.25)
	requestStart()
end
]]

-- Creamos un LocalScript "plantilla" en ReplicatedStorage para clonar
local templateName = "OrbSpawnerClient_Template"
local existingTemplate = ReplicatedStorage:FindFirstChild(templateName)
if not existingTemplate then
	local template = Instance.new("LocalScript")
	template.Name = templateName
	template.Source = localScriptSource
	template.Parent = ReplicatedStorage
end

-- Función para inyectar el LocalScript en PlayerGui (para jugadores ya conectados y los nuevos)
local function injectClientScriptToPlayer(player)
	-- clonar la plantilla y ponerla en PlayerGui para que ejecute en el cliente inmediatamente
	local template = ReplicatedStorage:FindFirstChild(templateName)
	if not template then return end
	local cloned = template:Clone()
	-- poner en PlayerGui (LocalScripts corren cuando están en PlayerGui)
	cloned.Parent = player:WaitForChild("PlayerGui")
	-- Además colocar en StarterPlayerScripts para futuras reapariciones si quieres persistencia
	local starter = game:GetService("StarterPlayer")
	if starter then
		local existing = starter:FindFirstChild("StarterOrbSpawnerClient")
		if not existing then
			local starterClone = template:Clone()
			starterClone.Name = "StarterOrbSpawnerClient"
			starterClone.Parent = starter:WaitForChild("StarterPlayerScripts")
		end
	end
end

-- Inyectar a jugadores existentes
for _, pl in pairs(Players:GetPlayers()) do
	coroutine.wrap(function()
		-- esperar PlayerGui
		pl:WaitForChild("PlayerGui")
		injectClientScriptToPlayer(pl)
	end)()
end

-- Inyectar a jugadores nuevos
Players.PlayerAdded:Connect(function(pl)
	pl.CharacterAdded:Wait() -- esperar al menos al character para que PlayerGui exista
	pl:WaitForChild("PlayerGui")
	injectClientScriptToPlayer(pl)
end)

-- FIN del Script unificado
print("[OrbSpawnerUnified] Inicializado: RemoteEvents creados y client script inyectable.")
