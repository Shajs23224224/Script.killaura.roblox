local Players = game:GetService("Players")

local function setUltraGhostMode(character)
	if not character then return end
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 0.9
			part.Material = Enum.Material.ForceField
		elseif part:IsA("Decal") then
			part.Transparency = 0.9
		end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayName = "👻 Fantasma Etéreo"
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://317255881"
	emitter.Rate = 5
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(0.5, 1)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new(0.7)
	emitter.Parent = character:WaitForChild("HumanoidRootPart")
end

local player = Players.LocalPlayer

player.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	task.wait(0.2)
	setUltraGhostMode(char)
end)

if player.Character then
	setUltraGhostMode(player.Character)
end	emitter.Texture = "rbxassetid://317255881" -- textura de niebla blanca
	emitter.Rate = 5
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(0.5, 1)
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
	emitter.Transparency = NumberSequence.new(0.7)
	emitter.Parent = character:WaitForChild("HumanoidRootPart")
end

local player = Players.LocalPlayer

-- Aplicar el modo fantasma al reaparecer
player.CharacterAdded:Connect(function(char)
	char:WaitForChild("HumanoidRootPart")
	task.wait(0.2)
	setUltraGhostMode(char)
end)

-- Si el personaje ya está en el juego
if player.Character then
	setUltraGhostMode(player.Character)
end
