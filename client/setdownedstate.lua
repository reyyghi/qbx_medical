local isEscorted = false
local vehicleDict = "veh@low@front_ps@idle_duck"
local vehicleAnim = "sit"

function PlayUnescortedLastStandAnimation()
    local ped = cache.ped
    if cache.vehicle then
        lib.requestAnimDict(vehicleDict)
        if not IsEntityPlayingAnim(ped, vehicleDict, vehicleAnim, 3) then
            TaskPlayAnim(ped, vehicleDict, vehicleAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    else
        lib.requestAnimDict(LastStandDict)
        if not IsEntityPlayingAnim(ped, LastStandDict, LastStandAnim, 3) then
            TaskPlayAnim(ped, LastStandDict, LastStandAnim, 1.0, 1.0, -1, 1, 0, false, false, false)
        end
    end
end

---@param ped number
local function playEscortedLastStandAnimation(ped)
    if cache.vehicle then
        lib.requestAnimDict(vehicleDict)
        if IsEntityPlayingAnim(ped, vehicleDict, vehicleAnim, 3) then
            StopAnimTask(ped, vehicleDict, vehicleAnim, 3)
        end
    else
        lib.requestAnimDict(LastStandDict)
        if IsEntityPlayingAnim(ped, LastStandDict, LastStandAnim, 3) then
            StopAnimTask(ped, LastStandDict, LastStandAnim, 3)
        end
    end
end

local function playLastStandAnimation()
    if isEscorted then
        playEscortedLastStandAnimation(cache.ped)
    else
        PlayUnescortedLastStandAnimation()
    end
end

exports('playLastStandAnimationDeprecated', playLastStandAnimation)

---@param bool boolean
---TODO: this event name should be changed within qb-policejob to be generic
AddEventHandler('hospital:client:isEscorted', function(bool)
    isEscorted = bool
end)