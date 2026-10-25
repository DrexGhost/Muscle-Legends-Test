local Core, GUI = ...
local RunService = game:GetService("RunService")

local function build()
    local tab = GUI.makeTab("Event 2", 8, "combat")
    local page = GUI.makePage()

    GUI.makeSectionHeader(page, "Auto Race", 1)

    GUI.makeToggle(page, "Auto Race", "Авто-прохождение гонки", Core.settings.autoRace, 2, function(v)
        Core.settings.autoRace = v
        if not v then
            if not Core.settings.event2Farm then Core.stopFarm() end
        end
    end, "autoRace")

    GUI.makeSlider(page, "Race Height", 0, 500, Core.settings.raceHeight or 143, 3, function(v)
        Core.settings.raceHeight = v
    end, "raceHeight")

    GUI.makeSectionHeader(page, "Farm", 4)

    GUI.makeToggle(page, "Farm", "Фарм Event 2", Core.settings.event2Farm, 5, function(v)
        Core.settings.event2Farm = v
        if not v then
            if not Core.settings.autoRace then Core.stopFarm() end
        end
    end, "event2Farm")

    GUI.makeSlider(page, "Farm Height", 0, 500, Core.settings.event2Height or 143, 6, function(v)
        Core.settings.event2Height = v
    end, "event2Height")

    local lastRaceTp, lastFarmTp = 0, 0
    local lastAttack = 0

    RunService.Heartbeat:Connect(function()
        if not Core.HRP or not Core.HRP.Parent or not Core.Hum then return end
        if not Core.settings.autoRace and not Core.settings.event2Farm then return end

        local now = os.clock()

        if Core.settings.autoRace then
            if now - lastRaceTp >= 0.2 then
                lastRaceTp = now
                if not Core.NoclipActive then
                    Core.setNoclip(true)
                    Core.NoclipActive = true
                end
                Core.Hum.PlatformStand = true
                Core.HRP.AssemblyLinearVelocity = Vector3.zero
                Core.HRP.AssemblyAngularVelocity = Vector3.zero
            end
        end

        if Core.settings.event2Farm then
            if now - lastFarmTp >= 0.2 then
                lastFarmTp = now
                if not Core.NoclipActive then
                    Core.setNoclip(true)
                    Core.NoclipActive = true
                end
                Core.Hum.PlatformStand = true
                Core.HRP.AssemblyLinearVelocity = Vector3.zero
                Core.HRP.AssemblyAngularVelocity = Vector3.zero
            end

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