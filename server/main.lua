---@class PlayerStatus
---@field limbs BodyParts
---@field isBleeding number

---@type table<source, PlayerStatus>
local playerStatus = {}

---@type table<source, number[]> weapon hashes
local playerWeaponWounds = {}

local triggerEventHooks = require 'modules.hooks.server'

---@param data number[] weapon hashes
lib.callback.register('qbx_medical:server:setWeaponWounds', function(source, data)
	playerWeaponWounds[source] = data
end)

lib.callback.register('qbx_medical:server:clearWeaponWounds', function(source)
	playerWeaponWounds[source] = nil
end)

---@param player table|number
local function revivePlayer(player)
	if type(player) == "number" then
		player = exports.qbx_core:GetPlayer(player)
	end
	player.Functions.SetMetaData("isdead", false)
	player.Functions.SetMetaData("inlaststand", false)
	playerWeaponWounds[source] = nil
	TriggerClientEvent('qbx_medical:client:playerRevived', player.PlayerData.source)
end

---Compatibility with txAdmin Menu's heal options.
---This is an admin only server side event that will pass the target player id or -1.
---@class EventData
---@field id number
---@param eventData EventData
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
	if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
		return
	end

	revivePlayer(eventData.id)
	lib.callback('qbx_medical:client:heal', eventData.id, false, "full")
end)

---@param data PlayerStatus
lib.callback.register('qbx_medical:server:syncInjuries', function(source, data)
	playerStatus[source] = data
end)

---@param limbs BodyParts
---@return BodyParts
local function getDamagedBodyParts(limbs)
	local bodyParts = {}
	for bone, bodyPart in pairs(limbs) do
		if bodyPart.isDamaged then
			bodyParts[bone] = bodyPart
		end
	end
	return bodyParts
end

---@param playerId number
lib.callback.register('hospital:GetPlayerStatus', function(_, playerId)
	local playerSource = exports.qbx_core:GetPlayer(playerId).PlayerData.source

	---@class PlayerDamage
	---@field damagedBodyParts BodyParts
	---@field bleedLevel number
	---@field weaponWounds number[]

	---@type PlayerDamage
	local damage = {
		damagedBodyParts = {},
		bleedLevel = 0,
		weaponWounds = {}
	}
	if not playerSource then
		return damage
	end

	local playerInjuries = playerStatus[playerSource]
	if playerInjuries then
		damage.bleedLevel = playerInjuries.isBleeding or 0
		damage.damagedBodyParts = getDamagedBodyParts(playerInjuries.limbs)
	end

	damage.weaponWounds = playerWeaponWounds[playerSource] or {}
	return damage
end)

RegisterNetEvent('qbx_medical:server:playerDied', function()
	if GetInvokingResource() then return end
	local src = source
	local player = exports.qbx_core:GetPlayer(src)
	if not player then return end
	player.Functions.SetMetaData("isdead", true)
end)

RegisterNetEvent('qbx_medical:server:onPlayerLaststand', function()
	if GetInvokingResource() then return end
	local player = exports.qbx_core:GetPlayer(source)
	player.Functions.SetMetaData("inlaststand", true)
end)

RegisterNetEvent('qbx_medical:server:onPlayerLaststandEnd', function()
	if GetInvokingResource() then return end
	local player = exports.qbx_core:GetPlayer(source)
	player.Functions.SetMetaData("inlaststand", false)
end)

---@param amount number
lib.callback.register('qbx_medical:server:setArmor', function(source, amount)
	local player = exports.qbx_core:GetPlayer(source)
	player.Functions.SetMetaData("armor", amount)
end)

local function resetHungerAndThirst(player)
	if type(player == 'number') then
		player = exports.qbx_core:GetPlayer(player)
	end

	player.Functions.SetMetaData('hunger', 100)
	player.Functions.SetMetaData('thirst', 100)
	TriggerClientEvent('hud:client:UpdateNeeds', player.PlayerData.source, 100, 100)
end

lib.callback.register('qbx_medical:server:resetHungerAndThirst', resetHungerAndThirst)

lib.addCommand('revive', {
    help = Lang:t('info.revive_player_a'),
	restricted = "admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		TriggerClientEvent('ox_lib:notify', source, { description = Lang:t('error.not_online'), type = 'error' })
		return
	end
	revivePlayer(args.id)
end)

lib.addCommand('kill', {
    help =  Lang:t('info.kill'),
	restricted = "admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		TriggerClientEvent('ox_lib:notify', source, { description = Lang:t('error.not_online'), type = 'error' })
		return
	end
	lib.callback('qbx_medical:client:killPlayer', args.id)
end)

lib.addCommand('aheal', {
    help =  Lang:t('info.heal_player_a'),
	restricted = "admin",
	params = {
        { name = 'id', help = Lang:t('info.player_id'), type = 'playerId', optional = true },
    }
}, function(source, args)
	if not args.id then args.id = source end
	local player = exports.qbx_core:GetPlayer(tonumber(args.id))
	if not player then
		TriggerClientEvent('ox_lib:notify', source, { description = Lang:t('error.not_online'), type = 'error' })
		return
	end
	lib.callback('qbx_medical:client:heal', args.id, false, "full")
end)

lib.callback.register('qbx_medical:server:respawn', function(source)
	if not triggerEventHooks('respawn', source) then return false end
	TriggerEvent('qbx_medical:server:playerRespawned', source)
	return true
end)
