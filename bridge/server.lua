Bridge = {}
local BridgeExport = exports['community_bridge']:Bridge()
local PlayerPermissions = {}

function Bridge.GetPlayer(source)
    if BridgeExport and BridgeExport.Framework and BridgeExport.Framework.GetPlayer then
        return BridgeExport.Framework.GetPlayer(source)
    end
    return nil
end

function Bridge.GetPlayerIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return identifiers[1]
end

function Bridge.GetPlayerName(source)
    return GetPlayerName(source)
end

function Bridge.Notify(source, message, type)
    TriggerClientEvent('eg_reports:client:notify', source, message, type or 'info')
end

function Bridge.CheckPermission(source)
    if BridgeExport and BridgeExport.Framework and BridgeExport.Framework.GetIsFrameworkAdmin then
        return BridgeExport.Framework.GetIsFrameworkAdmin(source)
    end
    return false
end

function Bridge.HasPermission(source)
    if PlayerPermissions[source] == nil then
        PlayerPermissions[source] = Bridge.CheckPermission(source)
    end
    return PlayerPermissions[source]
end

function Bridge.RefreshPermission(source)
    local oldPerm = PlayerPermissions[source]
    local newPerm = Bridge.CheckPermission(source)
    PlayerPermissions[source] = newPerm
    if oldPerm ~= newPerm then
        TriggerClientEvent('eg_reports:client:permission_updated', source, newPerm)
    end
    return newPerm
end

function Bridge.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    return GetEntityCoords(ped)
end

AddEventHandler('playerDropped', function()
    PlayerPermissions[source] = nil
end)

CreateThread(function()
    while true do
        Wait(5000)
        for _, playerId in ipairs(GetPlayers()) do
            Bridge.RefreshPermission(tonumber(playerId))
        end
    end
end)

RegisterNetEvent('eg_reports:server:request_permission', function()
    local src = source
    TriggerClientEvent('eg_reports:client:permission_updated', src, Bridge.RefreshPermission(src))
end)

RegisterNetEvent('community_bridge:Server:OnPlayerJobChange', function(src)
    Bridge.RefreshPermission(src)
end)

AddEventHandler('txAdmin:events:adminAuth', function(data)
    if data and data.netid then
        Bridge.RefreshPermission(data.netid)
    end
end)
