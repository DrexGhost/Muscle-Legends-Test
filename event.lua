local Core, GUI = ...
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local function build()
    local tab = GUI.makeTab("Event", 6, "combat")
    local page = GUI.makePage()

    GUI.makeSectionHeader(page, "Teleport", 1)
    GUI.makeActionButton(page, "Halloween Gym", "blue", 2, function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(5558, 85, 5838)
        end
    end)

    GUI.makeSectionHeader(page, "Event Farm", 3)

    local char, hrp, hum
    local savedCollide = {}
    local noclipActive = false
    local RETURN_POS = Vector3.new(-16.9, 36.3, -1243.5)

    local function bindChar(c)
        char = c
        hrp = c:WaitForChild("HumanoidRootPart")
        hum = c:WaitForChild("Humanoid")
        savedCollide = {}
        noclipActive = false
    end
    if LocalPlayer.Character then bindChar(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(bindChar)

    local function setNoclip(enabled)
        local c = LocalPlayer.Character
        if not c then return end
        if enabled then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    if savedCollide[p] == nil then savedCollide[p] = p.CanCollide end
                    p.CanCollide = false
                end
            end
        else
            for part, state in pairs(savedCollide) do
                if part and part.Parent then part.CanCollide = state end
            end
            savedCollide = {}
        end
    end

    local function findGroundPos(fromPos)
        local c = LocalPlayer.Character
        if not c then return nil end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { c }
        local result = workspace:Raycast(fromPos + Vector3.new(0, 5, 0), Vector3.new(0, -2000, 0), params)
        if result then return result.Position + Vector3.new(0, 3.5, 0) end
        return nil
    end

    local function stopFarm()
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not root or not h then return end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        local target = findGroundPos(root.Position) or findGroundPos(RETURN_POS) or RETURN_POS
        root.CFrame = CFrame.new(target)

        if noclipActive then
            setNoclip(false)
            noclipActive = false
        end

        h.PlatformStand = false
        h.AutoRotate = true
    end

    local function returnToBase()
        local c = LocalPlayer.Character
        if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then return end

        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero

        local target = findGroundPos(RETURN_POS) or RETURN_POS
        root.CFrame = CFrame.new(target)
    end

    local function anyBossEnabled()
        for _, bName in ipairs(Core.EVENT_BOSS_ORDER) do
            if Core.settings.eventBosses[bName] then return true end
        end
        return false
    end

    local bNames = {"EXTREME", "HARD", "MEDIUM", "EASY"}
    local order = 4
    for _, bName in ipairs(bNames) do
        local isActive = Core.settings.eventBosses[bName] or false
        GUI.makeToggle(page, bName, "Фармить " .. bName, isActive, order, function(v)
            Core.settings.eventBosses[bName] = v
            Core.saveSetting("eventBosses", Core.settings.eventBosses)
            if v then
                Core.settings.autoEventFarm = true
            else
                if not anyBossEnabled() then
                    Core.settings.autoEventFarm = false
                    stopFarm()
                end
            end
        end, "boss_" .. bName)
        order = order + 1
    end

    Core.settings.autoEventFarm = anyBossEnabled()

    local lastAttack, lastSearchTime = 0, 0
    local currentBossModel, currentBossPart, bossWasAlive = nil, nil, false

    local function getBoss()
        for _, name in ipairs(Core.EVENT_BOSS_ORDER) do
            if Core.settings.eventBosses[name] then
                local b = Core.EVENT_BOSSES[name]
                local model = workspace:FindFirstChild(b.model)
                if model then
                    local part = model:FindFirstChild(b.part)
                    if part and part.Position.Y > 0 then
                        return model, part
                    end
                end
            end
        end
        return nil
    end

    RunService.Heartbeat:Connect(function()
        if not Core.settings.autoEventFarm then return end
        if not hrp or not hrp.Parent or not hum then return end

        local now = os.clock()

        if currentBossPart then
            if not currentBossPart.Parent or currentBossPart.Position.Y <= 0 then
                if bossWasAlive then returnToBase() end
                currentBossModel, currentBossPart, bossWasAlive = nil, nil, false
            else
                local hp = currentBossModel:GetAttribute("Health") or currentBossPart:GetAttribute("Health")
                if hp and hp > 0 then
                    bossWasAlive = true
                elseif hp and hp <= 0 then
                    if bossWasAlive then
                        returnToBase()
                        currentBossModel, currentBossPart, bossWasAlive = nil, nil, false
                    end
                end
            end
        end

        if not currentBossPart then
            if now - lastSearchTime >= 2 then
                lastSearchTime = now
                local bModel, bPart = getBoss()
                if bModel then
                    currentBossModel, currentBossPart, bossWasAlive = bModel, bPart, true
                end
            end
            if not currentBossPart then return end
        end

        if not noclipActive then
            setNoclip(true)
            noclipActive = true
        end

        hum.AutoRotate = false
        hum.PlatformStand = true
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        local height = Core.BOSS_HEIGHTS[currentBossModel.Name] or 143
        local targetPos = Vector3.new(currentBossPart.Position.X, height, currentBossPart.Position.Z)
        local lookTarget = currentBossPart.Position

        if (targetPos - lookTarget).Magnitude < 1 then
            lookTarget = targetPos + Vector3.new(0, 0, -1)
        end
        hrp.CFrame = CFrame.lookAt(targetPos, lookTarget)

        if now - lastAttack >= 0.4 then
            lastAttack = now
            Core.punch()
        end
    end)

    tab.Button.MouseButton1Click:Connect(function() GUI.switchTab(tab, page) end)
    return tab, page
end
return build
