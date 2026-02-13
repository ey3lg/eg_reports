Bridge = Bridge or {}
local BridgeExport = nil
local HasPermission = false
local UploadConfig = { url = '', field = 'files[]' }

CreateThread(function()
    local attempts = 0
    while not BridgeExport and attempts < 30 do
        local ok, result = pcall(function()
            return exports['community_bridge']:Bridge()
        end)
        if ok and result then
            BridgeExport = result
            print('^2[eg_reports] community_bridge initialized successfully^7')
        else
            attempts = attempts + 1
            if attempts % 10 == 0 then
                print('^3[eg_reports] Waiting for community_bridge... attempt ' .. attempts .. '/30^7')
            end
            Wait(1000)
        end
    end

    if not BridgeExport then
        print('^1[eg_reports] Failed to initialize community_bridge after 30 attempts^7')
        return
    end

    Bridge.RequestPermissionCheck()
end)

function Bridge.GetPlayerData()
    if not BridgeExport then return nil end
    local ok, result = pcall(BridgeExport.Framework.GetPlayerData)
    if ok then return result end
    return nil
end

function Bridge.Notify(message, type)
    if BridgeExport then
        pcall(BridgeExport.Framework.Notify, message, type or 'info', 5000)
    end
end

function Bridge.HasPermission()
    return HasPermission
end

function Bridge.RequestPermissionCheck()
    TriggerServerEvent('eg_reports:server:request_permission')
end

function Bridge.GetUploadConfig()
    return UploadConfig
end

RegisterNetEvent('eg_reports:client:notify', function(message, type)
    Bridge.Notify(message, type)
end)

RegisterNetEvent('eg_reports:client:permission_updated', function(hasPerm)
    HasPermission = hasPerm
    TriggerEvent('eg_reports:client:onPermissionChanged', hasPerm)
end)

RegisterNetEvent('eg_reports:client:set_upload_config', function(config)
    if config then
        UploadConfig = config
    end
end)
