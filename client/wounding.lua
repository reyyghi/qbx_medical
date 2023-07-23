local function getWorstInjury()
    local level = 0
    for _, injury in pairs(Injuries) do
        if injury.severity > level then
            level = injury.severity
        end
    end

    return level
end

CreateThread(function()
    while true do
        if #Injuries > 0 then
            local level = getWorstInjury()
            SetPedMoveRateOverride(cache.ped, Config.MovementRate[level])
            Wait(5)
        else
            Wait(1000)
        end
    end
end)

local function makePlayerBlackout()
    local ped = cache.ped
    SetFlash(0, 0, 100, 7000, 100)

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08) -- change this float to increase/decrease camera shake
        SetPedToRagdollWithFall(ped, 7500, 9000, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    end

    Wait(1500)
    DoScreenFadeIn(1000)
end

exports('makePlayerBlackout', makePlayerBlackout)

local function makePlayerFadeOut()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    DoScreenFadeIn(500)
end

exports('makePlayerFadeOut', makePlayerFadeOut)

exports('handleBloodLossEffectsDeprecated', function()
    if FadeOutTimer + 1 == Config.FadeOutTimer then
        if BlackoutTimer + 1 == Config.BlackoutTimer then
            makePlayerBlackout()
            BlackoutTimer = 0
        else
            makePlayerFadeOut()
            BlackoutTimer += BleedLevel > 3 and 2 or 1
        end

        FadeOutTimer = 0
    else
        FadeOutTimer += 1
    end
end)