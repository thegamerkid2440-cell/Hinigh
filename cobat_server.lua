
-- INFINITE CARNAGE V11
-- REAL MULTIPLAYER COMBAT SERVER
-- ServerScriptService / Script

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local remote = ReplicatedStorage:FindFirstChild("CarnageCombatV11")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "CarnageCombatV11"
    remote.Parent = ReplicatedStorage
end

local cooldown = {}

local ATTACKS = {
    PUNCH = {
        damage = 20,
        range = 10,
        cooldown = 0.5,
        color = Color3.fromRGB(255, 245, 245)
    },
    RED = {
        damage = 30,
        range = 65,
        cooldown = 1.5,
        color = Color3.fromRGB(255, 35, 60)
    },
    BLUE = {
        damage = 25,
        range = 65,
        cooldown = 1.5,
        color = Color3.fromRGB(40, 165, 255)
    },
    PURPLE = {
        damage = 75,
        range = 80,
        cooldown = 2.8,
        color = Color3.fromRGB(165, 45, 255)
    }
}

local function getCharacter(player)
    local char = player.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not hum or not root or hum.Health <= 0 then
        return
    end

    return hum, root, char
end

local function visual(from, to, kind, config)
    local start = Instance.new("Part")
    start.Name = "Carnage_" .. kind
    start.Shape = Enum.PartType.Ball
    start.Material = Enum.Material.Neon
    start.Color = config.color
    start.Size = Vector3.new(2, 2, 2)
    start.Anchored = true
    start.CanCollide = false
    start.CanTouch = false
    start.CanQuery = false
    start.Position = from
    start.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = config.color
    light.Range = 22
    light.Brightness = 5
    light.Parent = start

    local length = (to - from).Magnitude
    local duration = math.clamp(length / 140, 0.12, 0.45)

    local size = kind == "PURPLE" and 10
        or kind == "PUNCH" and 3
        or 6

    local fly = TweenService:Create(
        start,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Position = to}
    )
    fly:Play()

    fly.Completed:Connect(function()
        if not start.Parent then return end

        TweenService:Create(
            start,
            TweenInfo.new(0.2),
            {
                Size = Vector3.new(size, size, size),
                Transparency = 1
            }
        ):Play()
    end)

    Debris:AddItem(start, duration + 0.3)
end

remote.OnServerEvent:Connect(function(player, kind, targetId)
    if type(kind) ~= "string" then return end
    local config = ATTACKS[kind]
    if not config then return end

    if type(targetId) ~= "number" then return end
    local victim = Players:GetPlayerByUserId(targetId)

    if not victim or victim == player then return end

    local attackerHum, attackerRoot, attackerChar =
        getCharacter(player)

    local victimHum, victimRoot, victimChar =
        getCharacter(victim)

    if not attackerHum or not victimHum then return end

    -- Optional friendly-fire protection
    if player.Team ~= nil
        and player.Team == victim.Team then
        return
    end

    local distance =
        (attackerRoot.Position - victimRoot.Position).Magnitude

    if distance > config.range then return end

    -- Require the attacker to be generally facing the target
    local direction =
        (victimRoot.Position - attackerRoot.Position).Unit

    local facing = attackerRoot.CFrame.LookVector:Dot(direction)

    if facing < 0.1 then return end

    -- Validate clear line of sight
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {attackerChar}

    local hit = workspace:Raycast(
        attackerRoot.Position,
        victimRoot.Position - attackerRoot.Position,
        rayParams
    )

    if hit and not hit.Instance:IsDescendantOf(victimChar) then
        return
    end

    local userCooldown = cooldown[player]
    if not userCooldown then
        userCooldown = {}
        cooldown[player] = userCooldown
    end

    local now = os.clock()

    if now - (userCooldown[kind] or -100)
        < config.cooldown then
        return
    end

    userCooldown[kind] = now

    -- Server-approved damage
    victimHum:TakeDamage(config.damage)

    if kind == "BLUE" then
        -- Pull target slightly toward attacker.
        local pull = attackerRoot.Position - victimRoot.Position
        if pull.Magnitude > 1 then
            victimRoot:ApplyImpulse(
                pull.Unit * victimRoot.AssemblyMass * 28
            )
        end
    elseif kind == "RED" then
        -- Push target backward.
        victimRoot:ApplyImpulse(
            direction * victimRoot.AssemblyMass * 35
        )
    end

    -- Spawned on the server: other players can see it.
    visual(
        attackerRoot.Position + direction * 3,
        victimRoot.Position,
        kind,
        config
    )

    remote:FireClient(
        player,
        "HIT",
        kind,
        config.damage
    )
end)

Players.PlayerRemoving:Connect(function(player)
    cooldown[player] = nil
end)

print("CARNAGE V11 MULTIPLAYER COMBAT READY")
