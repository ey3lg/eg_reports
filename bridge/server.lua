Bridge = Bridge or {}
local BridgeExport = nil
local PlayerPermissions = {}
local StaffOnDuty = {}

CreateThread(function()
    local attempts = 0
    while not BridgeExport and attempts < 30 do
        local ok, result = pcall(function()
            return exports['community_bridge']:Bridge()
        end)
        if ok and result then
            BridgeExport = result
            print('^2[eg_reports] community_bridge initialized on server^7')
        else
            attempts = attempts + 1
            if attempts % 10 == 0 then
                print('^3[eg_reports] Waiting for community_bridge on server... attempt ' .. attempts .. '/30^7')
            end
            Wait(1000)
        end
    end

    if not BridgeExport then
        print('^1[eg_reports] Failed to initialize community_bridge on server after 30 attempts^7')
    end
end)

function Bridge.GetPlayer(source)
    if not BridgeExport then return nil end
    local ok, result = pcall(BridgeExport.Framework.GetPlayer, source)
    if ok then return result end
    return nil
end

function Bridge.GetPlayerIdentifier(source)
    if not BridgeExport then return nil end
    local ok, result = pcall(BridgeExport.Framework.GetPlayerIdentifier, source)
    if ok then return result end
    return nil
end

function Bridge.GetPlayerName(source)
    if not BridgeExport then return GetPlayerName(source) or 'Unknown' end
    local ok, firstName, lastName = pcall(BridgeExport.Framework.GetPlayerName, source)
    if ok and firstName and lastName then
        return firstName .. ' ' .. lastName
    end
    return GetPlayerName(source) or 'Unknown'
end

function Bridge.GetPlayerDisplayName(source)
    local name = GetPlayerName(source) or 'Unknown'
    return name .. ' [' .. tostring(source) .. ']'
end

function Bridge.Notify(source, message, type)
    TriggerClientEvent('eg_reports:client:notify', source, message, type or 'info')
end

function Bridge.CheckPermission(source)
    if ServerConfig.AdminGroups and #ServerConfig.AdminGroups > 0 then
        for _, ace in ipairs(ServerConfig.AdminGroups) do
            if IsPlayerAceAllowed(tostring(source), ace) then
                return true
            end
        end
    end

    if BridgeExport then
        local ok, isAdmin = pcall(BridgeExport.Framework.GetIsFrameworkAdmin, source)
        if ok and isAdmin then return true end
    end

    return false
end

function Bridge.HasPermission(source)
    if not source or source == 0 then return false end

    if Config.StaffDuty and Config.StaffDuty.Enabled then
        if StaffOnDuty[source] == false then
            return false
        end
    end

    if PlayerPermissions[source] == nil then
        PlayerPermissions[source] = Bridge.CheckPermission(source)
    end
    return PlayerPermissions[source]
end

function Bridge.IsStaff(source)
    if not source or source == 0 then return false end
    if PlayerPermissions[source] == nil then
        PlayerPermissions[source] = Bridge.CheckPermission(source)
    end
    return PlayerPermissions[source]
end

function Bridge.RefreshPermission(source)
    local oldPerm = PlayerPermissions[source]
    local newPerm = Bridge.CheckPermission(source)
    PlayerPermissions[source] = newPerm

    if Config.StaffDuty and Config.StaffDuty.Enabled then
        if newPerm and StaffOnDuty[source] == nil then
            StaffOnDuty[source] = Config.StaffDuty.DefaultOnDuty ~= false
        end
    end

    if oldPerm ~= newPerm then
        local effectivePerm = newPerm
        if Config.StaffDuty and Config.StaffDuty.Enabled and StaffOnDuty[source] == false then
            effectivePerm = false
        end
        TriggerClientEvent('eg_reports:client:permission_updated', source, effectivePerm)
    end
    return newPerm
end

function Bridge.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return vector3(0, 0, 0) end
    return GetEntityCoords(ped)
end

function Bridge.GetPlayerStaffRank(source)
    if not Config.StaffRanks then return nil end

    local srcStr = tostring(source)
    for i = #Config.StaffRanks, 1, -1 do
        local rank = Config.StaffRanks[i]
        if rank.groups then
            for _, ace in ipairs(rank.groups) do
                if IsPlayerAceAllowed(srcStr, ace) then
                    return rank
                end
            end
        end
    end

    return nil
end

function Bridge.ToggleOnDuty(source)
    if not Config.StaffDuty or not Config.StaffDuty.Enabled then return false end
    if not Bridge.IsStaff(source) then return false end

    local current = StaffOnDuty[source]
    if current == nil then
        current = Config.StaffDuty.DefaultOnDuty ~= false
    end

    StaffOnDuty[source] = not current
    local effectivePerm = StaffOnDuty[source] and Bridge.IsStaff(source)
    TriggerClientEvent('eg_reports:client:permission_updated', source, effectivePerm)
    return StaffOnDuty[source]
end

function Bridge.IsOnDuty(source)
    if not Config.StaffDuty or not Config.StaffDuty.Enabled then return true end
    if StaffOnDuty[source] == nil then
        return Config.StaffDuty.DefaultOnDuty ~= false
    end
    return StaffOnDuty[source]
end

function Bridge.SendUploadConfig(source)
    TriggerClientEvent('eg_reports:client:set_upload_config', source, {
        url = ServerConfig.Screenshot and ServerConfig.Screenshot.UploadURL or '',
        field = ServerConfig.Screenshot and ServerConfig.Screenshot.FieldName or 'files[]'
    })
end

AddEventHandler('playerDropped', function()
    PlayerPermissions[source] = nil
    StaffOnDuty[source] = nil
end)

CreateThread(function()
    Wait(5000)
    while true do
        for _, playerId in ipairs(GetPlayers()) do
            local pid = tonumber(playerId)
            Bridge.RefreshPermission(pid)
        end
        Wait(5000)
    end
end)

RegisterNetEvent('eg_reports:server:request_permission', function()
    local src = source
    local perm = Bridge.RefreshPermission(src)
    local effectivePerm = perm
    if Config.StaffDuty and Config.StaffDuty.Enabled and StaffOnDuty[src] == false then
        effectivePerm = false
    end
    TriggerClientEvent('eg_reports:client:permission_updated', src, effectivePerm)
    Bridge.SendUploadConfig(src)
end)

RegisterNetEvent('community_bridge:Server:OnPlayerJobChange', function(src)
    Bridge.RefreshPermission(src)
end)

AddEventHandler('txAdmin:events:adminAuth', function(data)
    if data and data.netid then
        Bridge.RefreshPermission(data.netid)
    end
end)
