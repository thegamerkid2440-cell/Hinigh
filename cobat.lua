
-- INFINITE CARNAGE V11
-- RED / BLUE / PURPLE / PUNCH GUI
-- Delta-compatible LocalScript
-- Real damage requires the V11 server component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local env = getgenv and getgenv() or _G

if type(env.CarnageCombatUnload) == "function" then
    pcall(env.CarnageCombatUnload)
end

local old = pg:FindFirstChild("CarnageCombatGUI")
if old then old:Destroy() end

local function make(class, properties, parent)
    local o = Instance.new(class)
    for k, v in pairs(properties) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

local gui = make("ScreenGui", {
    Name = "CarnageCombatGUI",
    ResetOnSpawn = false,
    DisplayOrder = 1000
}, pg)

local frame = make("Frame", {
    Size = UDim2.fromOffset(255, 245),
    Position = UDim2.new(0.5, -127, 0.5, -122),
    BackgroundColor3 = Color3.fromRGB(17, 12, 32),
    Active = true,
    Draggable = true
}, gui)

make("UICorner", {
    CornerRadius = UDim.new(0, 12)
}, frame)

make("UIStroke", {
    Color = Color3.fromRGB(155, 65, 255),
    Thickness = 2
}, frame)

local function button(text, y, height)
    local b = make("TextButton", {
        Position = UDim2.fromOffset(9, y),
        Size = UDim2.fromOffset(237, height),
        BackgroundColor3 = Color3.fromRGB(77, 43, 130),
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Text = text
    }, frame)

    make("UICorner", {
        CornerRadius = UDim.new(0, 8)
    }, b)

    return b
end

local title = make("TextLabel", {
    Position = UDim2.fromOffset(8, 5),
    Size = UDim2.fromOffset(202, 28),
    BackgroundTransparency = 1,
    Text = "CARNAGE COMBAT V11",
    TextColor3 = Color3.fromRGB(230, 205, 255),
    Font = Enum.Font.GothamBlack,
    TextSize = 13
}, frame)

local x = make("TextButton", {
    Position = UDim2.fromOffset(217, 5),
    Size = UDim2.fromOffset(29, 28),
    BackgroundColor3 = Color3.fromRGB(120, 30, 55),
    TextColor3 = Color3.new(1, 1, 1),
    Text = "X",
    Font = Enum.Font.GothamBold
}, frame)

local selector = button("SELECT TARGET", 38, 32)
local cycle = button("TECHNIQUE: RED", 78, 34)
local fire = button("FIRE TECHNIQUE", 120, 34)
local punch = button("PUNCH", 163, 34)

local status = make("TextLabel", {
    Position = UDim2.fromOffset(8, 205),
    Size = UDim2.fromOffset(239, 33),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(218, 195, 255),
    TextSize = 11,
    TextWrapped = true,
    Text = "Checking multiplayer support..."
}, frame)

local mini = make("TextButton", {
    Position = UDim2.fromOffset(18, 215),
    Size = UDim2.fromOffset(88, 43),
    BackgroundColor3 = Color3.fromRGB(145, 55, 255),
    TextColor3 = Color3.new(1, 1, 1),
    Text = "COMBAT",
    Font = Enum.Font.GothamBold,
    Visible = false,
    ZIndex = 50
}, gui)

make("UICorner", {
    CornerRadius = UDim.new(0, 12)
}, mini)

local attacks = {"RED", "BLUE", "PURPLE"}
local colors = {
    RED = Color3.fromRGB(255, 35, 60),
    BLUE = Color3.fromRGB(40, 165, 255),
    PURPLE = Color3.fromRGB(165, 45, 255),
    PUNCH = Color3.fromRGB(245, 240, 255)
}

local index = 1
local target
local targetIndex = 0
local connections = {}
local lastAction = 0

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local function remote()
    return ReplicatedStorage:FindFirstChild("CarnageCombatV11")
end

local function report(message)
    if status.Parent then
        status.Text = message
    end
end

local function getRoot(p)
    local character = p and p.Character
    return character
        and character:FindFirstChild("HumanoidRootPart")
end

local function localEffect(kind)
    local root = getRoot(player)
    if not root then return end

    local from = root.Position
        + root.CFrame.LookVector * 3
        + Vector3.new(0, 1, 0)

    local destination =
        from + root.CFrame.LookVector * 9

    local targetRoot = getRoot(target)
    if targetRoot then
        destination = targetRoot.Position
    end

    local orb = make("Part", {
        Name = "CarnageClientPreview",
        Shape = Enum.PartType.Ball,
        Size = Vector3.new(2, 2, 2),
        Color = colors[kind],
        Material = Enum.Material.Neon,
        Anchored = true,
        CanCollide = false,
        CanTouch = false,
        CanQuery = false,
        Position = from
    }, workspace)

    TweenService:Create(
        orb,
        TweenInfo.new(0.25),
        {
            Position = destination,
            Size = Vector3.new(5, 5, 5),
            Transparency = 1
        }
    ):Play()

    Debris:AddItem(orb, 0.35)
end

local function attack(kind)
    if not target or not target.Parent then
        report("Select a target first")
        return
    end

    if os.clock() - lastAction < 0.25 then
        return
    end
    lastAction = os.clock()

    local r = remote()

    if r then
        r:FireServer(kind, target.UserId)
        report(kind .. " requested - server validating")
    else
        localEffect(kind)
        report("VISUAL ONLY - no combat server installed")
    end
end

connect(selector.Activated, function()
    local list = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(list, p)
        end
    end

    table.sort(list, function(a, b)
        return a.Name < b.Name
    end)

    if #list == 0 then
        target = nil
        report("No other players")
        return
    end

    targetIndex = targetIndex % #list + 1
    target = list[targetIndex]

    selector.Text = "TARGET: " .. target.Name
    report("Selected " .. target.Name)
end)

connect(cycle.Activated, function()
    index = index % #attacks + 1
    local kind = attacks[index]

    cycle.Text = "TECHNIQUE: " .. kind
    cycle.BackgroundColor3 = colors[kind]
    report(kind .. " selected")
end)

connect(fire.Activated, function()
    attack(attacks[index])
end)

connect(punch.Activated, function()
    attack("PUNCH")
end)

connect(x.Activated, function()
    frame.Visible = false
    mini.Visible = true
end)

connect(mini.Activated, function()
    mini.Visible = false
    frame.Visible = true
end)

local r = remote()

if r then
    connect(r.OnClientEvent, function(event, kind, damage)
        if event == "HIT" then
            report(
                kind .. " HIT! -" .. tostring(damage)
                .. " health"
            )
        end
    end)

    report("MULTIPLAYER COMBAT CONNECTED")
else
    report("VISUAL ONLY - server not installed")
end

local function unload()
    for _, c in ipairs(connections) do
        c:Disconnect()
    end

    gui:Destroy()

    if env.CarnageCombatUnload == unload then
        env.CarnageCombatUnload = nil
    end
end

env.CarnageCombatUnload = unload

print("CARNAGE COMBAT V11 LOADED")
