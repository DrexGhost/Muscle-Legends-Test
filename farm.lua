local Core, GUI = ...
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local function build()
    local tab = GUI.makeTab("Farm", 3, "farm")
    local page = GUI.makePage()

    local char, hrp, hum
    local savedCollide = {}
    local noclipActive = false

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

    local function resetCharState()
        if noclipActive then
            setNoclip(false)
            noclipActive = false
        end
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then
                h.PlatformStand = false
                h.AutoRotate = true
            end
        end
    end

    GUI.makeSectionHeader(page, "Boss Farm", 1)
    GUI.makeToggle(page, "Boss Farm", "Фарм боссов", Core.settings.bossFarm, 2, function(v)
        Core.settings.bossFarm = v
        if not v and not Core.settings.collectChest then resetCharState() end
    end, "bossFarm")

    GUI.makeSectionHeader(page, "Chest", 3)
    GUI.makeToggle(page, "Collect Chest", "Сбор сундуков", Core.settings.collectChest, 4, function(v)
        Core.settings.collectChest = v
        if not v and not Core.settings.bossFarm then resetCharState() end
    end, "collectChest")

    local lastAttack, lastSearchTime, lastChestTime = 0, 0, 0
    local currentBossModel, currentBossPart, bossWasAlive = nil, nil, false
    local chestIndex = 1
    local RETURN_POS = Vector3.new(-16.9, 36.3, -1243.5)

    local function getBoss()
        local events = workspace:FindFirstChild("Events")
        local arena = events and events:FindFirstChild("BossArena")
        if not arena then return nil end
        for _, model in ipairs(arena:GetChildren()) do
            local part = model:FindFirstChild("Boss")
            if part and part:IsA("BasePart") then
                local hp = model:GetAttribute("Health") or part:GetAttribute("Health") or 100
                if hp > 0 and part.Position.Y > 0 then
                    return model, part
                end
            end
        end
        return nil
    end

    RunService.Heartbeat:Connect(function()
        if not Core.settings.collectChest and not Core.settings.bossFarm then return end
        if not hrp or not hrp.Parent or not hum then return end

        local now = os.clock()

        if Core.settings.collectChest and not currentBossPart then
            if now - lastChestTime > 2 then
                lastChestTime = now
                if not noclipActive then setNoclip(true); noclipActive = true end
                hum.PlatformStand = true
                local chest = Core.CHESTS[chestIndex]
                if chest then hrp.CFrame = CFrame.new(chest.coords + Vector3.new(0, 3, 0)) end
                chestIndex = chestIndex + 1
                if chestIndex > #Core.CHESTS then chestIndex = 1 end
            end
        end

        if Core.settings.bossFarm then
            if currentBossPart then
                if not currentBossPart.Parent or currentBossPart.Position.Y <= 0 then
                    if bossWasAlive then hrp.CFrame = CFrame.new(RETURN_POS) end
                    currentBossModel, currentBossPart, bossWasAlive = nil, nil, false
                else
                    local hp = currentBossModel:GetAttribute("Health") or currentBossPart:GetAttribute("Health")
                    if hp and hp > 0 then
                        bossWasAlive = true
                    elseif hp and hp <= 0 then
                        if bossWasAlive then
                            hrp.CFrame = CFrame.new(RETURN_POS)
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
        end
    end)

    tab.Button.MouseButton1Click:Connect(function() GUI.switchTab(tab, page) end)
    return tab, page
end
return build
