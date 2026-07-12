local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    return
end

if _G.HouMenKeCyberDestroy then
    pcall(_G.HouMenKeCyberDestroy)
end

local defaults = {
    walkSpeed = 16,
    jumpPower = 50,
    gravity = workspace.Gravity,
    fov = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    flySpeed = 3,
    stepAmount = 25,
    spinSpeed = 90,
    aimFov = 120,
    aimSmoothness = 5,
    accent = Color3.fromRGB(0, 255, 225),
}

local state = {
    destroyed = false,
    panelVisible = true,
    chroma = true,
    accent = defaults.accent,
    walkSpeed = defaults.walkSpeed,
    jumpPower = defaults.jumpPower,
    gravity = defaults.gravity,
    fov = defaults.fov,
    flySpeed = defaults.flySpeed,
    stepAmount = defaults.stepAmount,
    spinSpeed = defaults.spinSpeed,
    fly = false,
    noclip = false,
    infiniteJump = false,
    esp = false,
    espBoxes = false,
    espNames = false,
    espTracers = false,
    espHealth = false,
    fullBright = false,
    shiftLock = false,
    antiAfk = false,
    antiFling = false,
    spin = false,
    localAura = false,
    aimbot = false,
    aimHold = true,
    targetHead = true,
    teamCheck = false,
    aimFov = defaults.aimFov,
    aimSmoothness = defaults.aimSmoothness,
    spectating = "",
    savedCFrame = nil,
    adminTarget = "me",
    adminNumber = 100,
    adminMusicId = "1843529274",
    adminVolume = 3,
    adminTime = 14,
    adminInterval = 1.5,
    rawCommand = ";cmds",
    autoKillLoop = false,
    autoFreezeLoop = false,
    autoJailLoop = false,
    autoPunishLoop = false,
    autoBringLoop = false,
    autoSpinLoop = false,
    autoSizeLoop = false,
    rawCommandLoop = false,
    lockdownLoop = false,
    chaosLoop = false,
    autoKillJoin = false,
    autoJailJoin = false,
    autoPunishJoin = false,
    autoFreezeJoin = false,
    moveInput = {
        forward = false,
        back = false,
        left = false,
        right = false,
        up = false,
        down = false,
    },
}

local lightingBackup = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

local theme = {
    background = Color3.fromRGB(8, 10, 18),
    panel = Color3.fromRGB(12, 16, 28),
    panelAlt = Color3.fromRGB(16, 21, 38),
    section = Color3.fromRGB(18, 26, 44),
    inset = Color3.fromRGB(7, 10, 18),
    text = Color3.fromRGB(235, 242, 255),
    subtext = Color3.fromRGB(140, 163, 196),
    line = Color3.fromRGB(42, 53, 79),
    success = Color3.fromRGB(0, 255, 180),
    warning = Color3.fromRGB(255, 205, 90),
    danger = Color3.fromRGB(255, 95, 120),
}

local controls = {}
local connections = {}
local accentBindings = {}
local styleRefreshers = {}
local notify
local runtime = {
    espHighlights = {},
    playerVisuals = {},
    localAura = nil,
    playerButtonsContainer = nil,
    playerButtonsLayout = nil,
    overlay = nil,
    overlayFovRing = nil,
    rightMouseHeld = false,
    lastStableCFrame = nil,
    lastAimTarget = nil,
    hudRows = {},
    loopTimers = {},
}

local function trackConnection(connection)
    table.insert(connections, connection)
    return connection
end

local function create(className, properties, children)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        instance[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    return instance
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

local function roundToStep(value, step)
    if step <= 0 then
        return value
    end
    return math.floor((value / step) + 0.5) * step
end

local function formatNumber(value)
    if math.abs(value - math.floor(value)) < 0.001 then
        return tostring(math.floor(value))
    end
    return string.format("%.1f", value)
end

local function bindAccent(object, property)
    table.insert(accentBindings, {
        object = object,
        property = property,
    })
    pcall(function()
        object[property] = state.accent
    end)
    return object
end

local function registerStyleRefresher(callback)
    table.insert(styleRefreshers, callback)
    callback()
end

local function refreshAccent()
    for index = #accentBindings, 1, -1 do
        local binding = accentBindings[index]
        if binding.object and binding.object.Parent then
            pcall(function()
                binding.object[binding.property] = state.accent
            end)
        else
            table.remove(accentBindings, index)
        end
    end

    for _, callback in ipairs(styleRefreshers) do
        pcall(callback)
    end
end

local function getGuiParent()
    if gethui then
        return gethui()
    end
    if CoreGui then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function getCharacter()
    return LocalPlayer.Character
end

local function getHumanoid(character)
    character = character or getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(character)
    character = character or getCharacter()
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function safeNotify(title, message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = 2,
        })
    end)
end

local function getExecutorName()
    if identifyexecutor then
        local ok, result = pcall(identifyexecutor)
        if ok and result and result ~= "" then
            return result
        end
    end
    return "Unknown"
end

local function applyMovementStats()
    local character = getCharacter()
    local humanoid = getHumanoid(character)
    if humanoid then
        humanoid.WalkSpeed = state.walkSpeed
        pcall(function()
            humanoid.UseJumpPower = true
        end)
        humanoid.JumpPower = state.jumpPower
    end

    workspace.Gravity = state.gravity

    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = state.fov
    end
end

local function setLocalAuraEnabled(enabled)
    state.localAura = enabled

    if runtime.localAura then
        runtime.localAura:Destroy()
        runtime.localAura = nil
    end

    if not enabled then
        return
    end

    local character = getCharacter()
    if not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "HMK_LocalAura"
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = state.accent
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = character
    runtime.localAura = highlight
end

local function setFullBrightEnabled(enabled)
    state.fullBright = enabled

    if enabled then
        Lighting.Brightness = 4
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(180, 195, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(160, 180, 255)
    else
        for key, value in pairs(lightingBackup) do
            Lighting[key] = value
        end
    end
end

local function setShiftLockEnabled(enabled)
    state.shiftLock = enabled
    local humanoid = getHumanoid()
    if humanoid then
        if enabled then
            humanoid.CameraOffset = Vector3.new(1.75, 0, 0)
            humanoid.AutoRotate = false
        else
            humanoid.CameraOffset = Vector3.zero
            humanoid.AutoRotate = true
        end
    end
end

local function clearEsp()
    for _, highlight in pairs(runtime.espHighlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    runtime.espHighlights = {}
end

local function setEspEnabled(enabled)
    state.esp = enabled
    if not enabled then
        clearEsp()
    end
end

local function setAntiAfkEnabled(enabled)
    state.antiAfk = enabled
end

local function setWalkSpeed(value)
    state.walkSpeed = clamp(value, 0, 300)
    applyMovementStats()
end

local function setJumpPower(value)
    state.jumpPower = clamp(value, 0, 300)
    applyMovementStats()
end

local function setGravity(value)
    state.gravity = clamp(value, 0, 400)
    applyMovementStats()
end

local function setFov(value)
    state.fov = clamp(value, 40, 120)
    applyMovementStats()
end

local function setFlySpeed(value)
    state.flySpeed = clamp(value, 1, 12)
end

local function setStepAmount(value)
    state.stepAmount = clamp(value, 1, 250)
end

local function setSpinSpeed(value)
    state.spinSpeed = clamp(value, 5, 100000)
end

local function copyToClipboard(text, label)
    if setclipboard then
        setclipboard(text)
        safeNotify("后门客", label .. " 已复制")
    else
        safeNotify("后门客", "当前执行器不支持剪贴板")
    end
end

local function getBackpack()
    return LocalPlayer:FindFirstChildOfClass("Backpack")
end

local function normalizeToken(text, fallback)
    local token = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if token == "" then
        return fallback
    end
    return token
end

local function getToolByName(toolName)
    local backpack = getBackpack()
    if backpack then
        local fromBackpack = backpack:FindFirstChild(toolName)
        if fromBackpack then
            return fromBackpack
        end
    end

    local character = getCharacter()
    if character then
        return character:FindFirstChild(toolName)
    end

    return nil
end

local function equipToolByName(toolName)
    local humanoid = getHumanoid()
    local tool = getToolByName(toolName)
    if not humanoid or not tool then
        notify("后门客", toolName .. " 不在背包或角色上")
        return
    end

    humanoid:EquipTool(tool)
    notify("后门客", "已装备 " .. toolName)
end

local function unequipTools()
    local humanoid = getHumanoid()
    if not humanoid then
        notify("后门客", "角色还没加载")
        return
    end

    humanoid:UnequipTools()
    notify("后门客", "已卸下当前工具")
end

local function teleportToInstance(instance, yOffset)
    local root = getRootPart()
    if not root or not instance then
        notify("后门客", "目标实例不可用")
        return
    end

    local pivot
    if instance:IsA("Model") then
        pivot = instance:GetPivot()
    elseif instance:IsA("BasePart") then
        pivot = instance.CFrame
    else
        local part = instance:FindFirstChildWhichIsA("BasePart", true)
        if part then
            pivot = part.CFrame
        end
    end

    if not pivot then
        notify("后门客", "目标没有可传送的位置")
        return
    end

    root.CFrame = pivot + Vector3.new(0, yOffset or 4, 0)
end

local function teleportToBaseplate()
    local terrain = workspace:FindFirstChild("Terrain")
    local baseplate = terrain and terrain:FindFirstChild("Baseplate")
    if not baseplate then
        notify("后门客", "没找到 Baseplate")
        return
    end

    teleportToInstance(baseplate, 6)
    notify("后门客", "已传送到 Baseplate")
end

local function teleportToHDAdminCore()
    local hdAdmin = workspace:FindFirstChild("HD Admin")
    local core = hdAdmin and hdAdmin:FindFirstChild("Core")
    if not core then
        notify("后门客", "没找到 HD Admin Core")
        return
    end

    teleportToInstance(core, 6)
    notify("后门客", "已传送到 HD Admin Core")
end

local function copyMapSummary()
    local workspaceItems = {}
    for _, child in ipairs(workspace:GetChildren()) do
        table.insert(workspaceItems, child.Name .. ":" .. child.ClassName)
    end

    local toolItems = {}
    local backpack = getBackpack()
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                table.insert(toolItems, child.Name)
            end
        end
    end

    local summary = table.concat({
        "Workspace => " .. table.concat(workspaceItems, " | "),
        "Backpack Tools => " .. (#toolItems > 0 and table.concat(toolItems, ", ") or "None"),
        "HD Admin => " .. tostring(workspace:FindFirstChild("HD Admin") ~= nil),
    }, "\n")

    copyToClipboard(summary, "地图摘要")
    notify("后门客", "地图摘要已复制")
end

local function getHDAdminSignals()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local bridge = replicatedStorage:FindFirstChild("HDAdminHDClient")
    return bridge and bridge:FindFirstChild("Signals") or nil
end

local function runHDAdminCommand(commandText, silent)
    local signals = getHDAdminSignals()
    local requestCommand = signals and signals:FindFirstChild("RequestCommand")
    if not requestCommand then
        notify("后门客", "HD Admin RequestCommand 不存在")
        return false, "missing"
    end

    local text = normalizeToken(commandText, "")
    if text == "" then
        notify("后门客", "命令不能为空")
        return false, "empty"
    end

    if string.sub(text, 1, 1) ~= ";" then
        text = ";" .. text
    end

    local ok, result = pcall(function()
        return requestCommand:InvokeServer(text)
    end)

    if not silent then
        if ok and result ~= false then
            notify("HD Admin", "已执行: " .. text)
        else
            notify("HD Admin", "执行失败: " .. text)
        end
    end

    return ok and result ~= false, result
end

local function runHDAdminTargeted(commandName, targetToken, extraToken)
    local target = normalizeToken(targetToken, state.adminTarget)
    local command = commandName .. " " .. target
    if extraToken ~= nil and tostring(extraToken) ~= "" then
        command = command .. " " .. tostring(extraToken)
    end
    return runHDAdminCommand(command, false)
end

local function shouldPulse(loopName, interval)
    local now = os.clock()
    local previous = runtime.loopTimers[loopName] or 0
    if now - previous >= interval then
        runtime.loopTimers[loopName] = now
        return true
    end
    return false
end

local function runJoinPunishers(player)
    if not player or player == LocalPlayer then
        return
    end

    local targetName = player.Name
    task.delay(0.8, function()
        if state.destroyed then
            return
        end
        if state.autoKillJoin then
            runHDAdminTargeted("kill", targetName)
        end
        if state.autoFreezeJoin then
            runHDAdminTargeted("freeze", targetName)
        end
        if state.autoJailJoin then
            runHDAdminTargeted("jail", targetName)
        end
        if state.autoPunishJoin then
            runHDAdminTargeted("punish", targetName)
        end
    end)
end

local function runLockdownBurst()
    runHDAdminCommand("freeze others", true)
    runHDAdminCommand("jail others", true)
    runHDAdminCommand("bring others me", true)
end

local function runChaosBurst()
    runHDAdminCommand("kill others", true)
    runHDAdminCommand("spin others " .. tostring(math.floor(state.adminNumber)), true)
    runHDAdminCommand("size others " .. tostring(math.floor(state.adminNumber)), true)
    runHDAdminCommand("bring others me", true)
end

local function giveBTools()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then
        safeNotify("后门客", "背包不存在")
        return
    end

    local names = {
        Hammer = 4,
        Clone = 3,
        Grab = 2,
    }

    for toolName, binType in pairs(names) do
        local existing = backpack:FindFirstChild(toolName)
        if not existing then
            local tool = Instance.new("HopperBin")
            tool.Name = toolName
            tool.BinType = binType
            tool.Parent = backpack
        end
    end

    safeNotify("后门客", "BTools 已加入背包")
end

local function suicide()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

local function saveCurrentPosition()
    local root = getRootPart()
    if not root then
        safeNotify("后门客", "角色未加载")
        return
    end
    state.savedCFrame = root.CFrame
    safeNotify("后门客", "已保存当前位置")
end

local function returnToSavedPosition()
    local root = getRootPart()
    if not root or not state.savedCFrame then
        safeNotify("后门客", "没有可返回的位置")
        return
    end
    root.CFrame = state.savedCFrame
    safeNotify("后门客", "已返回保存位置")
end

local function stepUp()
    local root = getRootPart()
    if not root then
        safeNotify("后门客", "角色未加载")
        return
    end
    root.CFrame = root.CFrame + Vector3.new(0, state.stepAmount, 0)
end

local function teleportToSpawn()
    local root = getRootPart()
    if not root then
        safeNotify("后门客", "角色未加载")
        return
    end

    local spawnPoint = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if not spawnPoint then
        safeNotify("后门客", "地图里没找到 SpawnLocation")
        return
    end

    root.CFrame = spawnPoint.CFrame + Vector3.new(0, 4, 0)
    safeNotify("后门客", "已传送到出生点")
end

local function copyCoordinates()
    local root = getRootPart()
    if not root then
        safeNotify("后门客", "角色未加载")
        return
    end

    local position = root.Position
    local text = string.format("%.1f, %.1f, %.1f", position.X, position.Y, position.Z)
    copyToClipboard(text, "坐标")
end

local function rejoinServer()
    safeNotify("后门客", "正在尝试重进当前服务器")
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

local function teleportToPlayer(targetPlayer)
    if not targetPlayer or targetPlayer == LocalPlayer then
        return
    end

    local myRoot = getRootPart()
    local targetRoot = getRootPart(targetPlayer.Character)
    if not myRoot or not targetRoot then
        safeNotify("后门客", "目标角色未加载")
        return
    end

    myRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
    safeNotify("后门客", "已传送到 " .. targetPlayer.Name)
end

local function setAimFov(value)
    state.aimFov = clamp(value, 40, 300)
end

local function setAimSmoothness(value)
    state.aimSmoothness = clamp(value, 1, 25)
end

local function hasOverlayVisuals()
    return state.espBoxes or state.espNames or state.espTracers or state.espHealth
end

local function isFriendlyPlayer(player)
    if not player or player == LocalPlayer or not state.teamCheck then
        return false
    end

    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end

    if LocalPlayer.Neutral or player.Neutral then
        return false
    end

    return LocalPlayer.TeamColor == player.TeamColor
end

local function canTargetPlayer(player)
    if not player or player == LocalPlayer or isFriendlyPlayer(player) then
        return false
    end

    local character = player.Character
    local humanoid = getHumanoid(character)
    return character ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function getAimPart(character)
    if not character then
        return nil
    end

    if state.targetHead then
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end

    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function getProjectedPlayerBox(player)
    local character = player and player.Character
    local humanoid = getHumanoid(character)
    local root = getRootPart(character)
    local head = character and character:FindFirstChild("Head")
    local camera = workspace.CurrentCamera

    if not player or not character or not humanoid or humanoid.Health <= 0 or not root or not head or not camera then
        return nil
    end

    local headPoint, headVisible = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
    local feetPoint, feetVisible = camera:WorldToViewportPoint(root.Position - Vector3.new(0, humanoid.HipHeight + 3, 0))
    if not headVisible or not feetVisible or headPoint.Z <= 0 or feetPoint.Z <= 0 then
        return nil
    end

    local height = math.abs(feetPoint.Y - headPoint.Y)
    if height < 8 then
        return nil
    end

    local width = math.clamp(height * 0.62, 22, 260)
    local top = headPoint.Y - 6
    local left = headPoint.X - (width / 2)

    return {
        left = left,
        top = top,
        width = width,
        height = height + 10,
        center = Vector2.new(headPoint.X, top + ((height + 10) / 2)),
        distance = (camera.CFrame.Position - root.Position).Magnitude,
        health = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1),
        aimPart = getAimPart(character),
    }
end

local function ensureOverlayRoot()
    if runtime.overlay and runtime.overlay.Parent then
        return runtime.overlay
    end

    local overlay = create("Frame", {
        Parent = runtime.screen,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 60,
    })

    local fovRing = create("Frame", {
        Parent = overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(state.aimFov * 2, state.aimFov * 2),
        Visible = false,
        ZIndex = 61,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = state.accent,
            Thickness = 1.3,
            Transparency = 0.15,
        }),
    })
    bindAccent(fovRing.UIStroke, "Color")

    runtime.overlay = overlay
    runtime.overlayFovRing = fovRing
    return overlay
end

local function clearPlayerVisuals()
    for player, bundle in pairs(runtime.playerVisuals) do
        for _, instance in pairs(bundle) do
            if typeof(instance) == "Instance" then
                instance:Destroy()
            end
        end
        runtime.playerVisuals[player] = nil
    end
end

local function ensurePlayerVisualBundle(player)
    local overlay = ensureOverlayRoot()
    local existing = runtime.playerVisuals[player]
    if existing and existing.box and existing.box.Parent then
        return existing
    end

    local bundle = {}

    bundle.box = create("Frame", {
        Parent = overlay,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 62,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = state.accent,
            Thickness = 1.2,
        }),
    })
    bindAccent(bundle.box.UIStroke, "Color")

    bundle.name = create("TextLabel", {
        Parent = overlay,
        BackgroundColor3 = theme.background,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(140, 18),
        Text = "",
        TextColor3 = theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
        ZIndex = 63,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 6),
        }),
    })

    bundle.tracer = create("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(2, 2),
        Visible = false,
        ZIndex = 61,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })
    bindAccent(bundle.tracer, "BackgroundColor3")

    bundle.healthBack = create("Frame", {
        Parent = overlay,
        BackgroundColor3 = theme.inset,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 62,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),
    })

    bundle.healthFill = create("Frame", {
        Parent = bundle.healthBack,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = theme.success,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 63,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),
    })

    runtime.playerVisuals[player] = bundle
    return bundle
end

local function getClosestAimTarget()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil, nil
    end

    local mousePosition = UserInputService:GetMouseLocation()
    local bestPlayer = nil
    local bestPart = nil
    local bestDistance = state.aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if canTargetPlayer(player) then
            local aimPart = getAimPart(player.Character)
            if aimPart then
                local projected, visible = camera:WorldToViewportPoint(aimPart.Position)
                if visible and projected.Z > 0 then
                    local distance = (Vector2.new(projected.X, projected.Y) - mousePosition).Magnitude
                    if distance <= bestDistance then
                        bestDistance = distance
                        bestPlayer = player
                        bestPart = aimPart
                    end
                end
            end
        end
    end

    return bestPlayer, bestPart
end

local function teleportToAimTarget()
    if runtime.lastAimTarget then
        teleportToPlayer(runtime.lastAimTarget)
        return
    end

    notify("后门客", "当前没有锁定目标")
end

local function spectatePlayer(player)
    local camera = workspace.CurrentCamera
    local humanoid = player and getHumanoid(player.Character)
    if not camera or not humanoid then
        notify("后门客", "目标还没加载完成")
        return
    end

    camera.CameraSubject = humanoid
    state.spectating = player.Name
    notify("后门客", "正在观战 " .. player.Name)
end

local function spectateAimTarget()
    if runtime.lastAimTarget then
        spectatePlayer(runtime.lastAimTarget)
        return
    end

    notify("后门客", "先锁定一个目标")
end

local function stopSpectating()
    local camera = workspace.CurrentCamera
    local humanoid = getHumanoid()
    if camera and humanoid then
        camera.CameraSubject = humanoid
    end
    state.spectating = ""
    notify("后门客", "已切回本地视角")
end

local function panicReset()
    if controls.walkSpeed then
        controls.walkSpeed:Set(defaults.walkSpeed, true)
    else
        setWalkSpeed(defaults.walkSpeed)
    end

    if controls.jumpPower then
        controls.jumpPower:Set(defaults.jumpPower, true)
    else
        setJumpPower(defaults.jumpPower)
    end

    if controls.gravity then
        controls.gravity:Set(defaults.gravity, true)
    else
        setGravity(defaults.gravity)
    end

    if controls.fov then
        controls.fov:Set(defaults.fov, true)
    else
        setFov(defaults.fov)
    end

    if controls.flySpeed then
        controls.flySpeed:Set(defaults.flySpeed, true)
    else
        setFlySpeed(defaults.flySpeed)
    end

    if controls.stepAmount then
        controls.stepAmount:Set(defaults.stepAmount, true)
    else
        setStepAmount(defaults.stepAmount)
    end

    if controls.spinSpeed then
        controls.spinSpeed:Set(defaults.spinSpeed, true)
    else
        setSpinSpeed(defaults.spinSpeed)
    end

    if controls.aimFovSlider then
        controls.aimFovSlider:Set(defaults.aimFov, true)
    else
        setAimFov(defaults.aimFov)
    end

    if controls.aimSmoothnessSlider then
        controls.aimSmoothnessSlider:Set(defaults.aimSmoothness, true)
    else
        setAimSmoothness(defaults.aimSmoothness)
    end

    local toggleNames = {
        "flyToggle",
        "noclipToggle",
        "infiniteJumpToggle",
        "espToggle",
        "espBoxesToggle",
        "espNamesToggle",
        "espTracersToggle",
        "espHealthToggle",
        "fullBrightToggle",
        "shiftLockToggle",
        "antiAfkToggle",
        "antiFlingToggle",
        "spinToggle",
        "localAuraToggle",
        "aimbotToggle",
        "aimHoldToggle",
        "targetHeadToggle",
        "teamCheckToggle",
        "chromaToggle",
        "rawCommandLoopToggle",
        "autoBringLoopToggle",
        "autoKillJoinToggle",
        "autoFreezeJoinToggle",
        "autoJailJoinToggle",
        "autoPunishJoinToggle",
        "autoKillLoopToggle",
        "autoFreezeLoopToggle",
        "autoJailLoopToggle",
        "autoPunishLoopToggle",
        "autoSpinLoopToggle",
        "autoSizeLoopToggle",
        "lockdownLoopToggle",
        "chaosLoopToggle",
    }

    for _, name in ipairs(toggleNames) do
        if controls[name] then
            controls[name]:Set(false, true)
        end
    end

    if controls.aimHoldToggle then
        controls.aimHoldToggle:Set(true, true)
    end

    if controls.targetHeadToggle then
        controls.targetHeadToggle:Set(true, true)
    end

    state.savedCFrame = nil
    state.adminTarget = "me"
    state.adminNumber = 100
    state.adminMusicId = "1843529274"
    state.adminVolume = 3
    state.adminTime = 14
    state.adminInterval = 1.5
    state.rawCommand = ";cmds"
    state.autoKillLoop = false
    state.autoFreezeLoop = false
    state.autoJailLoop = false
    state.autoPunishLoop = false
    state.autoBringLoop = false
    state.autoSpinLoop = false
    state.autoSizeLoop = false
    state.rawCommandLoop = false
    state.lockdownLoop = false
    state.chaosLoop = false
    state.autoKillJoin = false
    state.autoJailJoin = false
    state.autoPunishJoin = false
    state.autoFreezeJoin = false
    state.aimbot = false
    state.aimHold = true
    state.targetHead = true
    state.teamCheck = false
    state.antiFling = false
    state.espBoxes = false
    state.espNames = false
    state.espTracers = false
    state.espHealth = false
    state.spectating = ""
    runtime.lastAimTarget = nil
    runtime.rightMouseHeld = false
    runtime.loopTimers = {}
    state.accent = defaults.accent
    refreshAccent()
    safeNotify("后门客", "已重置全部功能")
end

local function destroyRuntime()
    if state.destroyed then
        return
    end

    state.destroyed = true
    clearEsp()
    clearPlayerVisuals()
    setLocalAuraEnabled(false)
    setFullBrightEnabled(false)
    setShiftLockEnabled(false)
    stopSpectating()
    workspace.Gravity = defaults.gravity

    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = defaults.fov
    end

    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = defaults.walkSpeed
        pcall(function()
            humanoid.UseJumpPower = true
        end)
        humanoid.JumpPower = defaults.jumpPower
        humanoid.CameraOffset = Vector3.zero
        humanoid.AutoRotate = true
    end

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if runtime.screen then
        runtime.screen:Destroy()
        runtime.screen = nil
    end

    _G.HouMenKeCyberDestroy = nil
end

_G.HouMenKeCyberDestroy = destroyRuntime

local function dragify(handle, target)
    local dragging = false
    local dragStart
    local startPosition
    local dragInput

    trackConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position

            trackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end))
        end
    end))

    trackConnection(handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end))
end

local parentGui = getGuiParent()
local existingGui = parentGui:FindFirstChild("HouMenKeCyber")
if existingGui then
    existingGui:Destroy()
end

local screen = create("ScreenGui", {
    Name = "HouMenKeCyber",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

if syn and syn.protect_gui then
    pcall(syn.protect_gui, screen)
end

screen.Parent = parentGui
runtime.screen = screen

local notificationHolder = create("Frame", {
    Parent = screen,
    AnchorPoint = Vector2.new(1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.new(0, 320, 0, 240),
})

create("UIListLayout", {
    Parent = notificationHolder,
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

function notify(title, message)
    safeNotify(title, message)

    local toast = create("Frame", {
        Parent = notificationHolder,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = theme.panel,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(1, 0, 0, 64),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 10),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.2,
        }),
    })

    bindAccent(toast.UIStroke, "Color")

    create("Frame", {
        Parent = toast,
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 4, 1, 0),
    })

    create("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -24, 0, 18),
        Text = title,
        TextColor3 = theme.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    create("TextLabel", {
        Parent = toast,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 14, 0, 30),
        Size = UDim2.new(1, -24, 0, 22),
        Text = message,
        TextColor3 = theme.subtext,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    toast.Position = UDim2.new(1, 24, 0, 0)
    TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    task.delay(2.8, function()
        if not toast.Parent then
            return
        end
        local tween = TweenService:Create(toast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 32, 0, 0),
        })
        tween:Play()
        tween.Completed:Wait()
        toast:Destroy()
    end)
end

local main = create("Frame", {
    Parent = screen,
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = theme.background,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 980, 0, 620),
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 16),
    }),
    create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1.6,
        Transparency = 0.1,
    }),
})

bindAccent(main.UIStroke, "Color")

local header = create("Frame", {
    Parent = main,
    BackgroundColor3 = theme.panel,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 76),
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 16),
    }),
})

local headerShade = create("Frame", {
    Parent = header,
    BackgroundColor3 = theme.background,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -16),
    Size = UDim2.new(1, 0, 0, 16),
})

local topLine = create("Frame", {
    Parent = header,
    BackgroundColor3 = state.accent,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 3),
})
bindAccent(topLine, "BackgroundColor3")

local title = create("TextLabel", {
    Parent = header,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack,
    Position = UDim2.new(0, 22, 0, 14),
    Size = UDim2.new(0, 360, 0, 28),
    Text = "后门客 CYBER CORE",
    TextColor3 = theme.text,
    TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local subtitle = create("TextLabel", {
    Parent = header,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Position = UDim2.new(0, 22, 0, 42),
    Size = UDim2.new(0, 420, 0, 16),
    Text = "",
    TextColor3 = theme.subtext,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local headerStats = create("TextLabel", {
    Parent = header,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Position = UDim2.new(0, 470, 0, 25),
    Size = UDim2.new(0, 340, 0, 24),
    Text = string.format("Executor: %s | 玩家: %d | PlaceId: %s", getExecutorName(), #Players:GetPlayers(), tostring(game.PlaceId)),
    TextColor3 = theme.subtext,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
})

local buttonBar = create("Frame", {
    Parent = header,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -148, 0, 18),
    Size = UDim2.new(0, 128, 0, 40),
})

create("UIListLayout", {
    Parent = buttonBar,
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local function makeHeaderButton(symbol, backgroundColor)
    local button = create("TextButton", {
        Parent = buttonBar,
        AutoButtonColor = false,
        BackgroundColor3 = backgroundColor,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0, 36, 0, 36),
        Text = symbol,
        TextColor3 = theme.text,
        TextSize = 16,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })
    return button
end

local minimizeButton = makeHeaderButton("-", theme.panelAlt)
local hudButton = makeHeaderButton("HUD", theme.panelAlt)
local closeButton = makeHeaderButton("X", theme.danger)

local sidebar = create("Frame", {
    Parent = main,
    BackgroundColor3 = theme.panel,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 76),
    Size = UDim2.new(0, 200, 1, -76),
}, {
    create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = theme.line,
        Thickness = 1,
    }),
})

local sidebarPadding = create("UIPadding", {
    Parent = sidebar,
    PaddingTop = UDim.new(0, 16),
    PaddingBottom = UDim.new(0, 16),
    PaddingLeft = UDim.new(0, 14),
    PaddingRight = UDim.new(0, 14),
})

local tabButtonHolder = create("Frame", {
    Parent = sidebar,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, -86),
})

create("UIListLayout", {
    Parent = tabButtonHolder,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local sidebarFooter = create("Frame", {
    Parent = sidebar,
    AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = theme.section,
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 72),
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 12),
    }),
    create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = theme.line,
        Thickness = 1,
    }),
})

bindAccent(create("Frame", {
    Parent = sidebarFooter,
    BackgroundColor3 = state.accent,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(0, 4, 1, 0),
}), "BackgroundColor3")

create("TextLabel", {
    Parent = sidebarFooter,
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Position = UDim2.new(0, 16, 0, 12),
    Size = UDim2.new(1, -24, 0, 18),
    Text = "快捷键",
    TextColor3 = theme.text,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
})

create("TextLabel", {
    Parent = sidebarFooter,
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Position = UDim2.new(0, 16, 0, 32),
    Size = UDim2.new(1, -24, 0, 26),
    Text = "RightCtrl: 显示面板\nWASD / Space / Shift: 飞行",
    TextColor3 = theme.subtext,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
})

local content = create("Frame", {
    Parent = main,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 212, 0, 88),
    Size = UDim2.new(1, -228, 1, -102),
})

local pages = {}
local tabButtons = {}
local activeTab = nil

local function createPage(name)
    local button = create("TextButton", {
        Parent = tabButtonHolder,
        AutoButtonColor = false,
        BackgroundColor3 = theme.section,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(1, 0, 0, 48),
        Text = name,
        TextColor3 = theme.text,
        TextSize = 14,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    local accentBar = create("Frame", {
        Parent = button,
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -10),
        Size = UDim2.new(0, 4, 0, 20),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })
    bindAccent(accentBar, "BackgroundColor3")

    local page = create("ScrollingFrame", {
        Parent = content,
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = theme.line,
        ScrollBarThickness = 4,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    })

    create("UIListLayout", {
        Parent = page,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    create("UIPadding", {
        Parent = page,
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 4),
    })

    local function refreshButton()
        local selected = activeTab == name
        button.BackgroundColor3 = selected and theme.panelAlt or theme.section
        button.TextColor3 = selected and state.accent or theme.text
        button.UIStroke.Color = selected and state.accent or theme.line
        accentBar.Visible = selected
    end

    registerStyleRefresher(refreshButton)

    tabButtons[name] = button
    pages[name] = page
end

local function switchTab(name)
    activeTab = name
    for pageName, page in pairs(pages) do
        page.Visible = pageName == name
    end
    refreshAccent()
end

local function createSection(parent, titleText, bodyText)
    local section = create("Frame", {
        Parent = parent,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.section,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 0),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 14),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    local sectionPadding = create("UIPadding", {
        Parent = section,
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
    })

    local sectionList = create("UIListLayout", {
        Parent = section,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    create("TextLabel", {
        Parent = section,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(1, 0, 0, 18),
        Text = titleText,
        TextColor3 = theme.text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    if bodyText and bodyText ~= "" then
        create("TextLabel", {
            Parent = section,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, 0, 0, 30),
            Text = bodyText,
            TextColor3 = theme.subtext,
            TextSize = 12,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        })
    end

    local body = create("Frame", {
        Parent = section,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
    })

    create("UIListLayout", {
        Parent = body,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    return body
end

local function createInfoCard(parent, titleText, bodyText)
    local card = create("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.panelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 68),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    local dot = create("Frame", {
        Parent = card,
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 14),
        Size = UDim2.new(0, 10, 0, 10),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })
    bindAccent(dot, "BackgroundColor3")

    create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 32, 0, 10),
        Size = UDim2.new(1, -44, 0, 18),
        Text = titleText,
        TextColor3 = theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    create("TextLabel", {
        Parent = card,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 14, 0, 32),
        Size = UDim2.new(1, -28, 0, 24),
        Text = bodyText,
        TextColor3 = theme.subtext,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    return card
end

local function createButton(parent, titleText, bodyText, callback, accentMode)
    local holder = create("TextButton", {
        Parent = parent,
        AutoButtonColor = false,
        BackgroundColor3 = theme.panelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        Text = "",
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    local rail = create("Frame", {
        Parent = holder,
        BackgroundColor3 = accentMode == "danger" and theme.danger or state.accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -12),
        Size = UDim2.new(0, 4, 0, 24),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    if accentMode == "danger" then
        rail.BackgroundColor3 = theme.danger
    else
        bindAccent(rail, "BackgroundColor3")
    end

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(1, -28, 0, 18),
        Text = titleText,
        TextColor3 = theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -28, 0, 18),
        Text = bodyText or "",
        TextColor3 = theme.subtext,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    trackConnection(holder.MouseButton1Click:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = theme.section,
        }):Play()
        task.delay(0.1, function()
            if holder.Parent then
                TweenService:Create(holder, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundColor3 = theme.panelAlt,
                }):Play()
            end
        end)
        callback()
    end))

    return holder
end

local function createToggle(parent, titleText, bodyText, initialValue, callback)
    local value = initialValue
    local holder = create("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.panelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 60),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(1, -96, 0, 18),
        Text = titleText,
        TextColor3 = theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 14, 0, 29),
        Size = UDim2.new(1, -96, 0, 18),
        Text = bodyText or "",
        TextColor3 = theme.subtext,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local button = create("TextButton", {
        Parent = holder,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -74, 0, 12),
        Size = UDim2.new(0, 58, 0, 32),
        Text = "",
    })

    local track = create("Frame", {
        Parent = button,
        BackgroundColor3 = theme.inset,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    local knob = create("Frame", {
        Parent = track,
        BackgroundColor3 = theme.text,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, -11),
        Size = UDim2.new(0, 22, 0, 22),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    local function render()
        track.BackgroundColor3 = value and state.accent or theme.inset
        knob.Position = value and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
    end

    registerStyleRefresher(render)

    local control = {}

    function control:Set(newValue, silent)
        value = not not newValue
        render()
        callback(value, silent)
    end

    function control:Get()
        return value
    end

    trackConnection(button.MouseButton1Click:Connect(function()
        control:Set(not value, false)
    end))

    render()
    return control
end

local function createSlider(parent, titleText, bodyText, minimum, maximum, initialValue, step, callback)
    local value = initialValue
    local dragging = false

    local holder = create("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.panelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 82),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -92, 0, 18),
        Text = titleText,
        TextColor3 = theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -92, 0, 18),
        Text = bodyText or "",
        TextColor3 = theme.subtext,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local valueLabel = create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -76, 0, 16),
        Size = UDim2.new(0, 62, 0, 16),
        Text = "",
        TextColor3 = theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    })

    local bar = create("Frame", {
        Parent = holder,
        BackgroundColor3 = theme.inset,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 1, -24),
        Size = UDim2.new(1, -28, 0, 8),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    local fill = create("Frame", {
        Parent = bar,
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })
    bindAccent(fill, "BackgroundColor3")

    local knob = create("Frame", {
        Parent = bar,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.text,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(1, 0),
        }),
    })

    local dragButton = create("TextButton", {
        Parent = bar,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "",
    })

    local function render()
        local alpha = (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = formatNumber(value)
    end

    local control = {}

    function control:Set(newValue, silent)
        local rounded = roundToStep(clamp(newValue, minimum, maximum), step)
        value = rounded
        render()
        callback(value, silent)
    end

    function control:Get()
        return value
    end

    local function setFromPosition(xPosition)
        local alpha = clamp((xPosition - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local rawValue = minimum + ((maximum - minimum) * alpha)
        control:Set(rawValue, false)
    end

    trackConnection(dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromPosition(input.Position.X)
        end
    end))

    trackConnection(dragButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromPosition(input.Position.X)
        end
    end))

    registerStyleRefresher(render)
    render()
    return control
end

local function createInput(parent, titleText, bodyText, placeholder, callback)
    local holder = create("Frame", {
        Parent = parent,
        BackgroundColor3 = theme.panelAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 94),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 12),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -28, 0, 18),
        Text = titleText,
        TextColor3 = theme.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    create("TextLabel", {
        Parent = holder,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -28, 0, 18),
        Text = bodyText or "",
        TextColor3 = theme.subtext,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local inputFrame = create("Frame", {
        Parent = holder,
        BackgroundColor3 = theme.inset,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 1, -38),
        Size = UDim2.new(1, -118, 0, 28),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 8),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    local box = create("TextBox", {
        Parent = inputFrame,
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = theme.subtext,
        PlaceholderText = placeholder,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Text = "",
        TextColor3 = theme.text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local applyButton = create("TextButton", {
        Parent = holder,
        AutoButtonColor = false,
        BackgroundColor3 = theme.section,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -96, 1, -38),
        Size = UDim2.new(0, 82, 0, 28),
        Text = "执行",
        TextColor3 = theme.text,
        TextSize = 12,
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 8),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.line,
            Thickness = 1,
        }),
    })

    local function submit()
        callback(box.Text)
    end

    trackConnection(box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submit()
        end
    end))

    trackConnection(applyButton.MouseButton1Click:Connect(submit))
    return box
end

local function createHud()
    local hud = create("Frame", {
        Parent = screen,
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = theme.panel,
        BackgroundTransparency = 0.08,
        Position = UDim2.new(1, -18, 0, 18),
        Size = UDim2.new(0, 300, 0, 160),
    }, {
        create("UICorner", {
            CornerRadius = UDim.new(0, 14),
        }),
        create("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.2,
        }),
    })
    bindAccent(hud.UIStroke, "Color")

    create("TextLabel", {
        Parent = hud,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -28, 0, 18),
        Text = "CYBER HUD",
        TextColor3 = theme.text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local line = create("Frame", {
        Parent = hud,
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 34),
        Size = UDim2.new(1, -28, 0, 2),
    })
    bindAccent(line, "BackgroundColor3")

    local list = create("Frame", {
        Parent = hud,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 44),
        Size = UDim2.new(1, -28, 1, -56),
    })

    create("UIListLayout", {
        Parent = list,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local function makeRow(name)
        local label = create("TextLabel", {
            Parent = list,
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, 0, 0, 16),
            Text = name,
            TextColor3 = theme.subtext,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        runtime.hudRows[name] = label
    end

    makeRow("MOVE")
    makeRow("FLAGS")
    makeRow("VISUAL")
    makeRow("ADMIN")
    makeRow("POS")

    return hud
end

local hud = createHud()
runtime.hud = hud

local openChip = create("TextButton", {
    Parent = screen,
    AutoButtonColor = false,
    BackgroundColor3 = theme.panel,
    Font = Enum.Font.GothamBlack,
    Position = UDim2.new(0, 18, 0.5, -24),
    Size = UDim2.new(0, 88, 0, 48),
    Text = "HMK",
    TextColor3 = theme.text,
    TextSize = 18,
    Visible = false,
}, {
    create("UICorner", {
        CornerRadius = UDim.new(0, 14),
    }),
    create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1.2,
    }),
})
bindAccent(openChip.UIStroke, "Color")

dragify(header, main)

local function setPanelVisible(visible)
    state.panelVisible = visible
    main.Visible = visible
    openChip.Visible = not visible
end

trackConnection(openChip.MouseButton1Click:Connect(function()
    setPanelVisible(true)
end))

trackConnection(minimizeButton.MouseButton1Click:Connect(function()
    setPanelVisible(false)
end))

trackConnection(hudButton.MouseButton1Click:Connect(function()
    hud.Visible = not hud.Visible
    notify("后门客", hud.Visible and "HUD 已开启" or "HUD 已关闭")
end))

trackConnection(closeButton.MouseButton1Click:Connect(function()
    destroyRuntime()
end))

createPage("总览")
createPage("移动")
createPage("视觉")
createPage("地图")
createPage("传送")
createPage("管理")
createPage("攻击")
createPage("工具")
createPage("设置")

switchTab("总览")

for name, button in pairs(tabButtons) do
    trackConnection(button.MouseButton1Click:Connect(function()
        switchTab(name)
    end))
end

local dashboardPage = pages["总览"]
local movementPage = pages["移动"]
local visualPage = pages["视觉"]
local mapPage = pages["地图"]
local teleportPage = pages["传送"]
local adminPage = pages["管理"]
local offensePage = pages["攻击"]
local utilityPage = pages["工具"]
local settingsPage = pages["设置"]

local introSection = createSection(dashboardPage, "赛博引导", "这是一个不再依赖外链的单文件版本。面板内的核心动作、视觉模块和传送工具都已经直接写在脚本里。")
createInfoCard(introSection, "作者QQ", "1923455273")
createInfoCard(introSection, "QQ群", "600471372")
createInfoCard(introSection, "复制作者QQ", "3829482016")
createInfoCard(introSection, "复制群号", "641249762")
createInfoCard(introSection, "当前执行器", getExecutorName())
createInfoCard(introSection, "当前玩家", LocalPlayer.Name .. "  |  在线人数 " .. tostring(#Players:GetPlayers()))
createInfoCard(introSection, "快速热键", "RightCtrl 隐藏/唤出主面板；飞行状态下用 WASD / Space / Shift 控方向。")

local dashboardActions = createSection(dashboardPage, "快速动作", "这里放最常用的一键操作。")
createButton(dashboardActions, "保存位置", "记录当前坐标，稍后可一键返回。", saveCurrentPosition)
createButton(dashboardActions, "返回保存点", "把角色拉回刚刚记下的位置。", returnToSavedPosition)
createButton(dashboardActions, "工具箱 BTools", "向背包注入 Hammer / Clone / Grab。", giveBTools)
createButton(dashboardActions, "Panic Reset", "关闭全部开关并恢复默认参数。", panicReset, "danger")

local movementSection = createSection(movementPage, "移动控制", "速度、跳跃、重力、飞行和穿墙都在这里。")
controls.walkSpeed = createSlider(movementSection, "移动速度", "默认 16，可拉到 300。", 0, 300, state.walkSpeed, 1, function(value)
    setWalkSpeed(value)
end)
controls.jumpPower = createSlider(movementSection, "跳跃高度", "默认 50，可拉到 300。", 0, 300, state.jumpPower, 1, function(value)
    setJumpPower(value)
end)
controls.gravity = createSlider(movementSection, "世界重力", "默认跟随地图当前重力。", 0, 400, state.gravity, 1, function(value)
    setGravity(value)
end)
controls.flySpeed = createSlider(movementSection, "飞行速度", "控制自由飞行位移速度。", 1, 12, state.flySpeed, 0.5, function(value)
    setFlySpeed(value)
end)
controls.flyToggle = createToggle(movementSection, "自由飞行", "WASD 平移，Space 上升，Shift 下降。", state.fly, function(value, silent)
    state.fly = value
    if not silent then
        notify("后门客", value and "飞行已开启" or "飞行已关闭")
    end
end)
controls.noclipToggle = createToggle(movementSection, "穿墙", "持续关闭角色零件碰撞。", state.noclip, function(value, silent)
    state.noclip = value
    if not silent then
        notify("后门客", value and "穿墙已开启" or "穿墙已关闭")
    end
end)
controls.infiniteJumpToggle = createToggle(movementSection, "无限跳", "JumpRequest 到来时强行触发跳跃。", state.infiniteJump, function(value, silent)
    state.infiniteJump = value
    if not silent then
        notify("后门客", value and "无限跳已开启" or "无限跳已关闭")
    end
end)
controls.spinSpeed = createSlider(movementSection, "旋转速度", "给角色持续加上旋转，已拉到超高上限。", 5, 100000, state.spinSpeed, 50, function(value)
    setSpinSpeed(value)
end)
controls.spinToggle = createToggle(movementSection, "旋转模式", "适合做炫酷演示和视觉骚操作。", state.spin, function(value, silent)
    state.spin = value
    if not silent then
        notify("后门客", value and "旋转模式已开启" or "旋转模式已关闭")
    end
end)

local visualSection = createSection(visualPage, "视觉模块", "ESP、全亮、FOV、锁视角和个人光环。")
controls.espToggle = createToggle(visualSection, "全员透视", "给其他玩家打上高亮描边。", state.esp, function(value, silent)
    setEspEnabled(value)
    if not silent then
        notify("后门客", value and "ESP 已开启" or "ESP 已关闭")
    end
end)
controls.fullBrightToggle = createToggle(visualSection, "全亮模式", "覆盖 Lighting，抹掉阴影和雾。", state.fullBright, function(value, silent)
    setFullBrightEnabled(value)
    if not silent then
        notify("后门客", value and "全亮已开启" or "全亮已关闭")
    end
end)
controls.shiftLockToggle = createToggle(visualSection, "锁视角", "让角色跟着相机朝向偏肩移动。", state.shiftLock, function(value, silent)
    setShiftLockEnabled(value)
    if not silent then
        notify("后门客", value and "锁视角已开启" or "锁视角已关闭")
    end
end)
controls.localAuraToggle = createToggle(visualSection, "个人霓虹光环", "给自己挂一个赛博高亮外壳。", state.localAura, function(value, silent)
    setLocalAuraEnabled(value)
    if not silent then
        notify("后门客", value and "本地光环已开启" or "本地光环已关闭")
    end
end)
controls.fov = createSlider(visualSection, "视野 FOV", "默认跟相机当前值一致。", 40, 120, state.fov, 1, function(value)
    setFov(value)
end)

local mapInfoSection = createSection(mapPage, "地图情报", "这张图当前就是 HD Admin + Baseplate 的轻量模板，顶层结构和工具都可以直接接进面板。")
createInfoCard(mapInfoSection, "Workspace 顶层", "Camera / HD Admin / Terrain / " .. LocalPlayer.Name .. " / HDAdminWorkspaceFolder")
createInfoCard(mapInfoSection, "已知工具", "Building Tools 在背包和 StarterPack 都存在。")
createInfoCard(mapInfoSection, "已知节点", "可直接跳转到 Terrain.Baseplate 和 HD Admin.Core")

local mapControlSection = createSection(mapPage, "地图控制", "围绕这张图现成节点做快捷控制，少绕路。")
createButton(mapControlSection, "传送到 Baseplate", "跳到 Workspace.Terrain.Baseplate 上方。", teleportToBaseplate)
createButton(mapControlSection, "传送到 HD Admin Core", "跳到 Workspace.HD Admin.Core 上方。", teleportToHDAdminCore)
createButton(mapControlSection, "装备 Building Tools", "把背包里的 Building Tools 直接装到手上。", function()
    equipToolByName("Building Tools")
end)
createButton(mapControlSection, "卸下所有工具", "把当前装备全收回背包。", unequipTools)
createButton(mapControlSection, "复制地图摘要", "把 Workspace 顶层和背包工具信息复制出来。", copyMapSummary)
createInput(mapControlSection, "按名字跳转", "输入 Workspace 里的名字片段，直接跳到匹配实例。", "例如: Baseplate / HD Admin", function(text)
    local query = string.lower(normalizeToken(text, ""))
    if query == "" then
        notify("后门客", "先输入一个实例名片段")
        return
    end

    local found = nil
    if string.find(string.lower("Baseplate"), query, 1, true) then
        local terrain = workspace:FindFirstChild("Terrain")
        found = terrain and terrain:FindFirstChild("Baseplate")
    end

    if not found then
        for _, instance in ipairs(workspace:GetDescendants()) do
            if string.find(string.lower(instance.Name), query, 1, true) then
                found = instance
                break
            end
        end
    end

    if not found then
        notify("后门客", "没找到匹配实例")
        return
    end

    teleportToInstance(found, 6)
    notify("后门客", "已跳转到 " .. found.Name)
end)

local teleportSection = createSection(teleportPage, "坐标与传送", "位置保存、抬升、出生点和玩家传送。")
controls.stepAmount = createSlider(teleportSection, "抬升距离", "控制一键上抬的高度。", 1, 250, state.stepAmount, 1, function(value)
    setStepAmount(value)
end)
createButton(teleportSection, "保存当前位置", "把当前根部件 CFrame 存起来。", saveCurrentPosition)
createButton(teleportSection, "返回保存位置", "没有位置时会直接提示。", returnToSavedPosition)
createButton(teleportSection, "向上抬升", "把角色往上抬指定距离。", stepUp)
createButton(teleportSection, "回出生点", "寻找场景里的 SpawnLocation。", teleportToSpawn)
createButton(teleportSection, "复制坐标", "把当前位置 XYZ 复制到剪贴板。", copyCoordinates)
createButton(teleportSection, "重进服务器", "重新 Teleport 到当前 Place。", rejoinServer)

local playersSection = createSection(teleportPage, "玩家列表", "点谁就传送到谁身边。")
runtime.playerButtonsContainer = playersSection
runtime.playerButtonsLayout = playersSection:FindFirstChildOfClass("UIListLayout")

local adminSection = createSection(adminPage, "HD Admin 控制台", "你现在是 owner 权限，面板直接打 RequestCommand。目标支持 me / all / others / 玩家名。")
createInfoCard(adminSection, "命令前缀", "固定是 ;，原始命令和快捷按钮都会走同一条 HD Admin 控制链。")
createButton(adminSection, "打开命令列表", "执行 ;cmds，拉出这服当前可用命令。", function()
    runHDAdminCommand(";cmds", false)
end)
createButton(adminSection, "目标 = me", "把当前目标快速切回自己。", function()
    state.adminTarget = "me"
    notify("HD Admin", "目标已切到 me")
end)
createButton(adminSection, "目标 = all", "把当前目标快速切到 all。", function()
    state.adminTarget = "all"
    notify("HD Admin", "目标已切到 all")
end)
createButton(adminSection, "目标 = others", "把当前目标快速切到 others。", function()
    state.adminTarget = "others"
    notify("HD Admin", "目标已切到 others")
end)
createInput(adminSection, "原始命令", "直接执行任意 HD Admin 命令。支持写不带前缀的裸命令。", ";cmds", function(text)
    local command = normalizeToken(text, state.rawCommand)
    state.rawCommand = command
    runHDAdminCommand(command, false)
end)
createInput(adminSection, "目标令牌", "可填 me / all / others / 玩家名。", "me", function(text)
    state.adminTarget = normalizeToken(text, "me")
    notify("HD Admin", "目标已设为 " .. state.adminTarget)
end)
createInput(adminSection, "数值参数", "共享给 speed / fly / noclip / spin / size 等按钮。", "100", function(text)
    local value = tonumber(text)
    if not value then
        notify("HD Admin", "这不是数字")
        return
    end
    state.adminNumber = value
    notify("HD Admin", "数值参数 = " .. formatNumber(value))
end)
createInput(adminSection, "Music ID", "给 music 命令用的音频 ID。", state.adminMusicId, function(text)
    state.adminMusicId = normalizeToken(text, state.adminMusicId)
    notify("HD Admin", "Music ID 已更新")
end)
createInput(adminSection, "Time / Volume", "填 14 / 3 这类值，会同时更新 time 和 volume 默认参数。", "14", function(text)
    local value = tonumber(text)
    if not value then
        notify("HD Admin", "这不是数字")
        return
    end
    state.adminTime = value
    state.adminVolume = value
    notify("HD Admin", "time / volume 参数已更新")
end)
createButton(adminSection, "God 目标", "god <target>", function()
    runHDAdminTargeted("god", state.adminTarget)
end)
createButton(adminSection, "Fly 目标", "fly <target> <number>", function()
    runHDAdminTargeted("fly", state.adminTarget, math.floor(state.adminNumber))
end)
createButton(adminSection, "Noclip 目标", "noclip <target> <number>", function()
    runHDAdminTargeted("noclip", state.adminTarget, math.floor(state.adminNumber))
end)
createButton(adminSection, "Speed 目标", "speed <target> <number>", function()
    runHDAdminTargeted("speed", state.adminTarget, math.floor(state.adminNumber))
end)
createButton(adminSection, "Jump 目标", "jump <target>", function()
    runHDAdminTargeted("jump", state.adminTarget)
end)
createButton(adminSection, "Respawn 目标", "respawn <target>", function()
    runHDAdminTargeted("respawn", state.adminTarget)
end)
createButton(adminSection, "Bring 到我身边", "bring <target> me", function()
    runHDAdminCommand("bring " .. normalizeToken(state.adminTarget, "me") .. " me", false)
end)
createButton(adminSection, "View 目标", "view <target>", function()
    runHDAdminTargeted("view", state.adminTarget)
end)
createButton(adminSection, "设置 Time", "time <number>", function()
    runHDAdminCommand("time " .. tostring(math.floor(state.adminTime)), false)
end)
createButton(adminSection, "设置 Volume", "volume <number>", function()
    runHDAdminCommand("volume " .. tostring(math.floor(state.adminVolume)), false)
end)
createButton(adminSection, "播放 Music", "music <audioId>", function()
    runHDAdminCommand("music " .. normalizeToken(state.adminMusicId, "1843529274"), false)
end)
createInput(adminSection, "循环间隔", "常驻压制和命令风暴的节奏，单位秒。", "1.5", function(text)
    local value = tonumber(text)
    if not value or value <= 0 then
        notify("HD Admin", "循环间隔必须大于 0")
        return
    end
    state.adminInterval = value
    notify("HD Admin", "循环间隔 = " .. formatNumber(value) .. "s")
end)
controls.rawCommandLoopToggle = createToggle(adminSection, "原始命令风暴", "按循环间隔反复执行上面的原始命令。", state.rawCommandLoop, function(value, silent)
    state.rawCommandLoop = value
    if not silent then
        notify("HD Admin", value and "原始命令风暴已开启" or "原始命令风暴已关闭")
    end
end)
controls.autoBringLoopToggle = createToggle(adminSection, "持续 Bring", "按循环间隔把目标反复拉到你身边。", state.autoBringLoop, function(value, silent)
    state.autoBringLoop = value
    if not silent then
        notify("HD Admin", value and "持续 Bring 已开启" or "持续 Bring 已关闭")
    end
end)
controls.autoKillJoinToggle = createToggle(adminSection, "新玩家秒杀", "每个新进玩家都会自动吃一发 kill。", state.autoKillJoin, function(value, silent)
    state.autoKillJoin = value
    if not silent then
        notify("HD Admin", value and "新玩家秒杀已开启" or "新玩家秒杀已关闭")
    end
end)
controls.autoFreezeJoinToggle = createToggle(adminSection, "新玩家秒冻", "每个新进玩家都会自动 freeze。", state.autoFreezeJoin, function(value, silent)
    state.autoFreezeJoin = value
    if not silent then
        notify("HD Admin", value and "新玩家秒冻已开启" or "新玩家秒冻已关闭")
    end
end)
controls.autoJailJoinToggle = createToggle(adminSection, "新玩家秒关", "每个新进玩家都会自动 jail。", state.autoJailJoin, function(value, silent)
    state.autoJailJoin = value
    if not silent then
        notify("HD Admin", value and "新玩家秒关已开启" or "新玩家秒关已关闭")
    end
end)
controls.autoPunishJoinToggle = createToggle(adminSection, "新玩家秒罚", "每个新进玩家都会自动 punish。", state.autoPunishJoin, function(value, silent)
    state.autoPunishJoin = value
    if not silent then
        notify("HD Admin", value and "新玩家秒罚已开启" or "新玩家秒罚已关闭")
    end
end)

local offenseSection = createSection(offensePage, "攻击与压制", "这里全是高压按钮。你有 owner 权限，直接打服务端命令。")
createInfoCard(offenseSection, "当前目标", "默认使用上一个管理页里设定的目标令牌。")
createButton(offenseSection, "Kill 目标", "kill <target>", function()
    runHDAdminTargeted("kill", state.adminTarget)
end, "danger")
createButton(offenseSection, "Freeze 目标", "freeze <target>", function()
    runHDAdminTargeted("freeze", state.adminTarget)
end)
createButton(offenseSection, "Jail 目标", "jail <target>", function()
    runHDAdminTargeted("jail", state.adminTarget)
end)
createButton(offenseSection, "Punish 目标", "punish <target>", function()
    runHDAdminTargeted("punish", state.adminTarget)
end, "danger")
createButton(offenseSection, "Control 目标", "control <target>", function()
    runHDAdminTargeted("control", state.adminTarget)
end)
createButton(offenseSection, "Spin 目标", "spin <target> <number>", function()
    runHDAdminTargeted("spin", state.adminTarget, math.floor(state.adminNumber))
end)
createButton(offenseSection, "Size 目标", "size <target> <number>", function()
    runHDAdminTargeted("size", state.adminTarget, math.floor(state.adminNumber))
end)
createButton(offenseSection, "Sit 目标", "sit <target>", function()
    runHDAdminTargeted("sit", state.adminTarget)
end)
controls.autoKillLoopToggle = createToggle(offenseSection, "持续 Kill", "按循环间隔反复 kill 当前目标。", state.autoKillLoop, function(value, silent)
    state.autoKillLoop = value
    if not silent then
        notify("攻击", value and "持续 Kill 已开启" or "持续 Kill 已关闭")
    end
end)
controls.autoFreezeLoopToggle = createToggle(offenseSection, "持续 Freeze", "按循环间隔反复 freeze 当前目标。", state.autoFreezeLoop, function(value, silent)
    state.autoFreezeLoop = value
    if not silent then
        notify("攻击", value and "持续 Freeze 已开启" or "持续 Freeze 已关闭")
    end
end)
controls.autoJailLoopToggle = createToggle(offenseSection, "持续 Jail", "按循环间隔反复 jail 当前目标。", state.autoJailLoop, function(value, silent)
    state.autoJailLoop = value
    if not silent then
        notify("攻击", value and "持续 Jail 已开启" or "持续 Jail 已关闭")
    end
end)
controls.autoPunishLoopToggle = createToggle(offenseSection, "持续 Punish", "按循环间隔反复 punish 当前目标。", state.autoPunishLoop, function(value, silent)
    state.autoPunishLoop = value
    if not silent then
        notify("攻击", value and "持续 Punish 已开启" or "持续 Punish 已关闭")
    end
end)
controls.autoSpinLoopToggle = createToggle(offenseSection, "持续 Spin", "按循环间隔反复 spin 当前目标。", state.autoSpinLoop, function(value, silent)
    state.autoSpinLoop = value
    if not silent then
        notify("攻击", value and "持续 Spin 已开启" or "持续 Spin 已关闭")
    end
end)
controls.autoSizeLoopToggle = createToggle(offenseSection, "持续 Size", "按循环间隔反复 size 当前目标。", state.autoSizeLoop, function(value, silent)
    state.autoSizeLoop = value
    if not silent then
        notify("攻击", value and "持续 Size 已开启" or "持续 Size 已关闭")
    end
end)

local massActionSection = createSection(offensePage, "全图动作", "针对 all / 服务器级的高压操作。慎点，但你自己说了不用担心。")
createButton(massActionSection, "Kill All", "kill all", function()
    runHDAdminCommand("kill all", false)
end, "danger")
createButton(massActionSection, "Freeze All", "freeze all", function()
    runHDAdminCommand("freeze all", false)
end)
createButton(massActionSection, "Jail All", "jail all", function()
    runHDAdminCommand("jail all", false)
end)
createButton(massActionSection, "Punish All", "punish all", function()
    runHDAdminCommand("punish all", false)
end, "danger")
createButton(massActionSection, "Bring All To Me", "bring all me", function()
    runHDAdminCommand("bring all me", false)
end)
createButton(massActionSection, "Shutdown Server", "shutdown", function()
    runHDAdminCommand("shutdown", false)
end, "danger")
controls.lockdownLoopToggle = createToggle(massActionSection, "封服循环", "持续 freeze + jail + bring others me。", state.lockdownLoop, function(value, silent)
    state.lockdownLoop = value
    if not silent then
        notify("攻击", value and "封服循环已开启" or "封服循环已关闭")
    end
end)
controls.chaosLoopToggle = createToggle(massActionSection, "混乱循环", "持续 kill + spin + size + bring others me。", state.chaosLoop, function(value, silent)
    state.chaosLoop = value
    if not silent then
        notify("攻击", value and "混乱循环已开启" or "混乱循环已关闭")
    end
end)
createButton(massActionSection, "封服预设", "立即打一轮 freeze/jail/bring others me。", function()
    runLockdownBurst()
    notify("攻击", "封服预设已触发")
end, "danger")
createButton(massActionSection, "混乱预设", "立即打一轮 kill/spin/size/bring others me。", function()
    runChaosBurst()
    notify("攻击", "混乱预设已触发")
end, "danger")

local utilitySection = createSection(utilityPage, "工具与杂项", "经典功能和杂项操作都在这里。")
controls.antiAfkToggle = createToggle(utilitySection, "防挂机", "玩家 Idle 时自动模拟输入。", state.antiAfk, function(value, silent)
    setAntiAfkEnabled(value)
    if not silent then
        notify("后门客", value and "防挂机已开启" or "防挂机已关闭")
    end
end)
createButton(utilitySection, "发放 BTools", "直接内联创建旧版建造工具。", giveBTools)
createButton(utilitySection, "自杀", "把 Humanoid.Health 设为 0。", suicide, "danger")
createButton(utilitySection, "复制作者 QQ", "3829482016", function()
    copyToClipboard("3829482016", "作者 QQ")
end)
createButton(utilitySection, "复制群号", "641249762", function()
    copyToClipboard("641249762", "群号")
end)
createInput(utilitySection, "自定义传送", "输入玩家名片段，快速锁定目标。", "例如: Builder", function(text)
    local query = string.lower(text or "")
    if query == "" then
        notify("后门客", "先输入一个玩家名片段")
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local nameMatch = string.find(string.lower(player.Name), query, 1, true)
        local displayMatch = string.find(string.lower(player.DisplayName), query, 1, true)
        if player ~= LocalPlayer and (nameMatch or displayMatch) then
            teleportToPlayer(player)
            return
        end
    end
    notify("后门客", "没找到匹配玩家")
end)

local settingsSection = createSection(settingsPage, "赛博主题", "这里调 UI 外观和一些面板级行为。")
controls.chromaToggle = createToggle(settingsSection, "霓虹流光", "让主强调色在青紫色之间循环。", state.chroma, function(value, silent)
    state.chroma = value
    if not value then
        state.accent = defaults.accent
        refreshAccent()
    end
    if not silent then
        notify("后门客", value and "霓虹流光已开启" or "霓虹流光已关闭")
    end
end)
createButton(settingsSection, "主题：赛博青", "把强调色重置为默认赛博青。", function()
    state.chroma = false
    if controls.chromaToggle then
        controls.chromaToggle:Set(false, true)
    end
    state.accent = Color3.fromRGB(0, 255, 225)
    refreshAccent()
    notify("后门客", "已切换到赛博青")
end)
createButton(settingsSection, "主题：霓虹粉", "更艳、更炸。", function()
    state.chroma = false
    if controls.chromaToggle then
        controls.chromaToggle:Set(false, true)
    end
    state.accent = Color3.fromRGB(255, 60, 210)
    refreshAccent()
    notify("后门客", "已切换到霓虹粉")
end)
createButton(settingsSection, "主题：电磁紫", "深色背景下很锐。", function()
    state.chroma = false
    if controls.chromaToggle then
        controls.chromaToggle:Set(false, true)
    end
    state.accent = Color3.fromRGB(145, 90, 255)
    refreshAccent()
    notify("后门客", "已切换到电磁紫")
end)
createButton(settingsSection, "隐藏主面板", "只保留左侧 HMK 唤出按钮。", function()
    setPanelVisible(false)
end)
createButton(settingsSection, "销毁脚本", "清掉 GUI、连接和本地高亮。", destroyRuntime, "danger")

local aboutSection = createSection(settingsPage, "说明", "这个版本已经把原来的外链飞行、锁视角和 BTools 都内联了。要继续堆功能，优先从这个单文件往里加。")
createInfoCard(aboutSection, "当前构成", "移动 / 视觉 / 传送 / 工具 / HUD / 通知 / 赛博主题")
createInfoCard(aboutSection, "继续扩展位", "玩家跟踪、路径可视化、目标标记、阶段脚本、挑战专用宏")

local function wipePage(page)
    for _, child in ipairs(page:GetChildren()) do
        child:Destroy()
    end

    create("UIListLayout", {
        Parent = page,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    create("UIPadding", {
        Parent = page,
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 4),
    })
end

wipePage(adminPage)
wipePage(offensePage)

local adminSection = createSection(adminPage, "瞄准控制", "保留当前这套外壳，把原来的命令套壳改成直接可用的本地目标功能。")
createInfoCard(adminSection, "直开模式", "这一页现在负责视角锁定、目标过滤和快速瞄准动作，不再走旧命令桥。")
controls.aimbotToggle = createToggle(adminSection, "自动锁定", "把镜头拉向 FOV 范围内最近的目标。", state.aimbot, function(value, silent)
    state.aimbot = value
    if not silent then
        notify("后门客", value and "自动锁定已开启" or "自动锁定已关闭")
    end
end)
controls.aimHoldToggle = createToggle(adminSection, "按住右键", "只在按住鼠标右键时进行锁定。", state.aimHold, function(value, silent)
    state.aimHold = value
    if not silent then
        notify("后门客", value and "右键锁定已开启" or "右键锁定已关闭")
    end
end)
controls.targetHeadToggle = createToggle(adminSection, "优先爆头", "优先锁定 Head，找不到就退回 HumanoidRootPart。", state.targetHead, function(value, silent)
    state.targetHead = value
    if not silent then
        notify("后门客", value and "爆头优先已开启" or "爆头优先已关闭")
    end
end)
controls.teamCheckToggle = createToggle(adminSection, "队伍检测", "地图有队伍时自动跳过同队玩家。", state.teamCheck, function(value, silent)
    state.teamCheck = value
    if not silent then
        notify("后门客", value and "队伍检测已开启" or "队伍检测已关闭")
    end
end)
controls.aimFovSlider = createSlider(adminSection, "锁定范围", "鼠标周围的锁定半径。", 40, 300, state.aimFov, 1, function(value)
    setAimFov(value)
end)
controls.aimSmoothnessSlider = createSlider(adminSection, "平滑强度", "数值越高，镜头拉动越慢越顺。", 1, 25, state.aimSmoothness, 1, function(value)
    setAimSmoothness(value)
end)

local offenseSection = createSection(offensePage, "叠层显示", "方框、名字、描线和血条现在都走本地直接叠层。")
createInfoCard(offenseSection, "主高亮", "视觉页里的 ESP 还是控制旧高亮，这里这些开关是在上面再叠一层屏幕显示。")
controls.espBoxesToggle = createToggle(offenseSection, "方框", "在屏幕上投影 2D 玩家方框。", state.espBoxes, function(value, silent)
    state.espBoxes = value
    if not silent then
        notify("后门客", value and "方框显示已开启" or "方框显示已关闭")
    end
end)
controls.espNamesToggle = createToggle(offenseSection, "名字+距离", "在每个投影目标上方显示名字和距离。", state.espNames, function(value, silent)
    state.espNames = value
    if not silent then
        notify("后门客", value and "名字距离已开启" or "名字距离已关闭")
    end
end)
controls.espTracersToggle = createToggle(offenseSection, "描线", "从屏幕底部中心朝目标画线。", state.espTracers, function(value, silent)
    state.espTracers = value
    if not silent then
        notify("后门客", value and "描线显示已开启" or "描线显示已关闭")
    end
end)
controls.espHealthToggle = createToggle(offenseSection, "血条", "在目标方框左侧显示血量条。", state.espHealth, function(value, silent)
    state.espHealth = value
    if not silent then
        notify("后门客", value and "血条显示已开启" or "血条显示已关闭")
    end
end)

local combatActionsSection = createSection(offensePage, "直接动作", "不走命令桥，下面全是即时生效的本地动作。")
controls.antiFlingToggle = createToggle(combatActionsSection, "防甩飞", "压住异常速度尖峰，并拉回最近一次稳定位置。", state.antiFling, function(value, silent)
    state.antiFling = value
    if not silent then
        notify("后门客", value and "防甩飞已开启" or "防甩飞已关闭")
    end
end)
createButton(combatActionsSection, "传送到锁定目标", "直接传送到当前最近的锁定目标身边。", teleportToAimTarget)
createButton(combatActionsSection, "观战锁定目标", "把镜头切到当前锁定目标。", spectateAimTarget)
createButton(combatActionsSection, "停止观战", "把镜头切回你自己的角色。", stopSpectating)

local function rebuildPlayerButtons()
    local container = runtime.playerButtonsContainer
    if not container then
        return
    end

    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createButton(
                container,
                player.DisplayName .. "  @" .. player.Name,
                "点击传送到该玩家身边。",
                function()
                    teleportToPlayer(player)
                end
            )
        end
    end
end

local function hideVisualBundle(bundle)
    bundle.box.Visible = false
    bundle.name.Visible = false
    bundle.tracer.Visible = false
    bundle.healthBack.Visible = false
end

local function renderPlayerOverlays()
    local overlay = ensureOverlayRoot()
    if runtime.overlayFovRing then
        local mousePosition = UserInputService:GetMouseLocation()
        local diameter = state.aimFov * 2
        runtime.overlayFovRing.Visible = state.aimbot
        runtime.overlayFovRing.Size = UDim2.fromOffset(diameter, diameter)
        runtime.overlayFovRing.Position = UDim2.fromOffset(mousePosition.X - state.aimFov, mousePosition.Y - state.aimFov)
    end

    if not hasOverlayVisuals() then
        for _, bundle in pairs(runtime.playerVisuals) do
            hideVisualBundle(bundle)
        end
        return
    end

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local origin = Vector2.new(viewport.X * 0.5, viewport.Y - 28)
    local keep = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if canTargetPlayer(player) then
            local boxData = getProjectedPlayerBox(player)
            if boxData then
                local bundle = ensurePlayerVisualBundle(player)
                keep[player] = true

                bundle.box.Position = UDim2.fromOffset(boxData.left, boxData.top)
                bundle.box.Size = UDim2.fromOffset(boxData.width, boxData.height)
                bundle.box.Visible = state.espBoxes

                local nameText = string.format("%s [%dm]", player.Name, math.floor(boxData.distance + 0.5))
                local nameWidth = math.clamp((#nameText * 7) + 16, 110, 220)
                bundle.name.Text = nameText
                bundle.name.Size = UDim2.fromOffset(nameWidth, 18)
                bundle.name.Position = UDim2.fromOffset(boxData.left + ((boxData.width - nameWidth) * 0.5), boxData.top - 22)
                bundle.name.Visible = state.espNames

                local tracerVector = boxData.center - origin
                local tracerLength = tracerVector.Magnitude
                bundle.tracer.Position = UDim2.fromOffset(origin.X, origin.Y)
                bundle.tracer.Size = UDim2.fromOffset(2, math.max(2, tracerLength))
                bundle.tracer.Rotation = math.deg(math.atan2(tracerVector.Y, tracerVector.X)) + 90
                bundle.tracer.Visible = state.espTracers and tracerLength > 2

                local healthHeight = math.max(8, math.floor(boxData.height))
                bundle.healthBack.Position = UDim2.fromOffset(boxData.left - 8, boxData.top)
                bundle.healthBack.Size = UDim2.fromOffset(4, healthHeight)
                bundle.healthFill.Size = UDim2.new(1, 0, boxData.health, 0)
                bundle.healthFill.BackgroundColor3 = Color3.fromRGB(
                    math.floor(255 * (1 - boxData.health)),
                    math.floor(225 * boxData.health + 30),
                    85
                )
                bundle.healthBack.Visible = state.espHealth
            end
        end
    end

    for player, bundle in pairs(runtime.playerVisuals) do
        if not keep[player] then
            hideVisualBundle(bundle)
        end
    end

    overlay.Visible = true
end

local function applyAimbot(deltaTime)
    if not state.aimbot then
        runtime.lastAimTarget = nil
        return
    end

    if state.aimHold and not runtime.rightMouseHeld then
        runtime.lastAimTarget = nil
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then
        runtime.lastAimTarget = nil
        return
    end

    local targetPlayer, targetPart = getClosestAimTarget()
    runtime.lastAimTarget = targetPlayer
    if not targetPlayer or not targetPart then
        return
    end

    local desired = CFrame.new(camera.CFrame.Position, targetPart.Position)
    local alpha = clamp((deltaTime * 12) / math.max(1, state.aimSmoothness), 0.08, 1)
    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
end

local function updateHud()
    local root = getRootPart()
    local positionText = "?, ?, ?"
    if root then
        local position = root.Position
        positionText = string.format("%.0f, %.0f, %.0f", position.X, position.Y, position.Z)
    end

    if runtime.hudRows.MOVE then
        runtime.hudRows.MOVE.Text = string.format(
            "移动   速度 %s | 跳跃 %s | 重力 %s | 视野 %s",
            formatNumber(state.walkSpeed),
            formatNumber(state.jumpPower),
            formatNumber(state.gravity),
            formatNumber(state.fov)
        )
    end

    if runtime.hudRows.FLAGS then
        runtime.hudRows.FLAGS.Text = string.format(
            "状态   飞行 %s | 穿墙 %s | 无限跳 %s | 旋转 %s",
            state.fly and "开" or "关",
            state.noclip and "开" or "关",
            state.infiniteJump and "开" or "关",
            state.spin and "开" or "关"
        )
    end

    if runtime.hudRows.VISUAL then
        runtime.hudRows.VISUAL.Text = string.format(
            "视觉   透视 %s | 方框 %s | 描线 %s | 血条 %s",
            state.esp and "开" or "关",
            state.espBoxes and "开" or "关",
            state.espTracers and "开" or "关",
            state.espHealth and "开" or "关"
        )
    end

    if runtime.hudRows.ADMIN then
        local targetName = runtime.lastAimTarget and runtime.lastAimTarget.Name or "-"
        runtime.hudRows.ADMIN.Text = string.format(
            "战斗   锁定 %s | 右键 %s | 目标 %s | 防甩 %s",
            state.aimbot and "开" or "关",
            state.aimHold and "开" or "关",
            targetName,
            state.antiFling and "开" or "关"
        )
    end

    if runtime.hudRows.POS then
        runtime.hudRows.POS.Text = "坐标   " .. positionText
    end

    local accentOrSub = state.fly or state.esp or state.noclip or state.fullBright or state.aimbot or hasOverlayVisuals()
    for _, label in pairs(runtime.hudRows) do
        label.TextColor3 = accentOrSub and theme.text or theme.subtext
    end
end

local function ensureEsp()
    if not state.esp then
        return
    end

    local keep = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local existing = runtime.espHighlights[character]
            if not existing or not existing.Parent then
                local highlight = Instance.new("Highlight")
                highlight.Name = "HMK_ESP"
                highlight.FillTransparency = 0.72
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillColor = state.accent
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.Parent = character
                runtime.espHighlights[character] = highlight
            end
            keep[character] = true
        end
    end

    for character, highlight in pairs(runtime.espHighlights) do
        if not keep[character] then
            highlight:Destroy()
            runtime.espHighlights[character] = nil
        end
    end
end

local currentHue = 0
local hudClock = 0
local espClock = 0

trackConnection(RunService.RenderStepped:Connect(function(deltaTime)
    if state.destroyed then
        return
    end

    if state.chroma then
        currentHue = (currentHue + (deltaTime * 0.12)) % 1
        state.accent = Color3.fromHSV(currentHue, 0.75, 1)
        refreshAccent()
    end

    local character = getCharacter()
    local humanoid = getHumanoid(character)
    local root = getRootPart(character)
    local camera = workspace.CurrentCamera

    if state.fullBright then
        Lighting.Brightness = 4
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(180, 195, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(160, 180, 255)
    end

    if state.localAura and runtime.localAura then
        runtime.localAura.FillColor = state.accent
    end

    if state.esp then
        espClock = espClock + deltaTime
        if espClock >= 0.35 then
            espClock = 0
            ensureEsp()
        end

        for _, highlight in pairs(runtime.espHighlights) do
            highlight.FillColor = state.accent
        end
    end

    renderPlayerOverlays()

    if state.noclip and character then
        for _, item in ipairs(character:GetDescendants()) do
            if item:IsA("BasePart") then
                item.CanCollide = false
            end
        end
    end

    if state.shiftLock and humanoid and root and camera then
        humanoid.AutoRotate = false
        humanoid.CameraOffset = Vector3.new(1.75, 0, 0)
        local lookVector = camera.CFrame.LookVector
        local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
        if flatLook.Magnitude > 0.01 then
            root.CFrame = CFrame.new(root.Position, root.Position + flatLook.Unit)
        end
    end

    if state.fly and humanoid and root and camera then
        local direction = Vector3.zero
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector

        if state.moveInput.forward then
            direction = direction + look
        end
        if state.moveInput.back then
            direction = direction - look
        end
        if state.moveInput.left then
            direction = direction - right
        end
        if state.moveInput.right then
            direction = direction + right
        end
        if state.moveInput.up then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if state.moveInput.down then
            direction = direction - Vector3.new(0, 1, 0)
        end

        if direction.Magnitude > 0 then
            direction = direction.Unit
        end

        root.AssemblyLinearVelocity = Vector3.zero
        root.CFrame = CFrame.new(
            root.Position + (direction * (state.flySpeed * 7)),
            root.Position + look
        )
    end

    if state.spin and root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(state.spinSpeed * deltaTime), 0)
    end

    if root then
        if state.antiFling then
            local linear = root.AssemblyLinearVelocity.Magnitude
            local angular = root.AssemblyAngularVelocity.Magnitude
            if linear > 120 or angular > 80 then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                if runtime.lastStableCFrame then
                    root.CFrame = runtime.lastStableCFrame
                end
            else
                runtime.lastStableCFrame = root.CFrame
            end
        else
            runtime.lastStableCFrame = root.CFrame
        end
    end

    applyAimbot(deltaTime)

    local interval = math.max(0.2, tonumber(state.adminInterval) or 1.5)
    if state.rawCommandLoop and shouldPulse("rawCommandLoop", interval) then
        runHDAdminCommand(state.rawCommand, true)
    end
    if state.autoBringLoop and shouldPulse("autoBringLoop", interval) then
        runHDAdminCommand("bring " .. normalizeToken(state.adminTarget, "me") .. " me", true)
    end
    if state.autoKillLoop and shouldPulse("autoKillLoop", interval) then
        runHDAdminTargeted("kill", state.adminTarget)
    end
    if state.autoFreezeLoop and shouldPulse("autoFreezeLoop", interval) then
        runHDAdminTargeted("freeze", state.adminTarget)
    end
    if state.autoJailLoop and shouldPulse("autoJailLoop", interval) then
        runHDAdminTargeted("jail", state.adminTarget)
    end
    if state.autoPunishLoop and shouldPulse("autoPunishLoop", interval) then
        runHDAdminTargeted("punish", state.adminTarget)
    end
    if state.autoSpinLoop and shouldPulse("autoSpinLoop", interval) then
        runHDAdminTargeted("spin", state.adminTarget, math.floor(state.adminNumber))
    end
    if state.autoSizeLoop and shouldPulse("autoSizeLoop", interval) then
        runHDAdminTargeted("size", state.adminTarget, math.floor(state.adminNumber))
    end
    if state.lockdownLoop and shouldPulse("lockdownLoop", interval) then
        runLockdownBurst()
    end
    if state.chaosLoop and shouldPulse("chaosLoop", interval) then
        runChaosBurst()
    end

    hudClock = hudClock + deltaTime
    if hudClock >= 0.12 then
        hudClock = 0
        updateHud()
    end

end))

trackConnection(UserInputService.JumpRequest:Connect(function()
    if state.infiniteJump then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

trackConnection(LocalPlayer.Idled:Connect(function()
    if state.antiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

trackConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.35)
    applyMovementStats()
    setShiftLockEnabled(state.shiftLock)
    setLocalAuraEnabled(state.localAura)
    if state.spectating == "" then
        local camera = workspace.CurrentCamera
        local humanoid = getHumanoid(character)
        if camera and humanoid then
            camera.CameraSubject = humanoid
        end
    end
end))

trackConnection(Players.PlayerAdded:Connect(function(player)
    headerStats.Text = string.format("Executor: %s | 玩家: %d | PlaceId: %s", getExecutorName(), #Players:GetPlayers(), tostring(game.PlaceId))
    rebuildPlayerButtons()
end))

trackConnection(Players.PlayerRemoving:Connect(function()
    headerStats.Text = string.format("Executor: %s | 玩家: %d | PlaceId: %s", getExecutorName(), #Players:GetPlayers(), tostring(game.PlaceId))
    rebuildPlayerButtons()
end))

local keyMap = {
    [Enum.KeyCode.W] = "forward",
    [Enum.KeyCode.S] = "back",
    [Enum.KeyCode.A] = "left",
    [Enum.KeyCode.D] = "right",
    [Enum.KeyCode.Space] = "up",
    [Enum.KeyCode.LeftShift] = "down",
    [Enum.KeyCode.RightShift] = "down",
}

trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if UserInputService:GetFocusedTextBox() then
        return
    end

    if input.KeyCode == Enum.KeyCode.RightControl then
        setPanelVisible(not state.panelVisible)
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        runtime.rightMouseHeld = true
    end

    local mapped = keyMap[input.KeyCode]
    if mapped then
        state.moveInput[mapped] = true
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        runtime.rightMouseHeld = false
    end

    local mapped = keyMap[input.KeyCode]
    if mapped then
        state.moveInput[mapped] = false
    end
end))

applyMovementStats()
rebuildPlayerButtons()
updateHud()
notify("后门客", "赛博霓虹单文件版已加载")
