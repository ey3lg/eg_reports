RegisterNUICallback("close", function(_, cb)
    UI.Close()
    cb('ok')
end)

RegisterNUICallback("create_report", function(data, cb)
    if not data.location then
        data.location = Reports.GetPlayerCoords()
    end
    local result = lib.callback.await('eg_reports:server:create_report', false, data)
    if result then UI.Close() end
    cb(result)
end)

RegisterNUICallback("get_my_reports", function(_, cb)
    cb(lib.callback.await('eg_reports:server:get_my_reports', false) or {})
end)

RegisterNUICallback("get_report_details", function(reportId, cb)
    if not reportId then cb(nil) return end
    cb(lib.callback.await('eg_reports:server:get_report_details', false, reportId))
end)

RegisterNUICallback("claim_report", function(reportId, cb)
    if not reportId then cb(false) return end
    cb(lib.callback.await('eg_reports:server:claim_report', false, reportId))
end)

RegisterNUICallback("update_status", function(data, cb)
    if not data.reportId or not data.status then cb(false) return end
    cb(lib.callback.await('eg_reports:server:update_status', false, data.reportId, data.status))
end)

RegisterNUICallback("close_report", function(reportId, cb)
    if not reportId then cb(false) return end
    cb(lib.callback.await('eg_reports:server:close_report', false, reportId))
end)

RegisterNUICallback("get_admin_reports", function(filters, cb)
    cb(lib.callback.await('eg_reports:server:get_admin_reports', false, filters or {}) or {})
end)

RegisterNUICallback("get_statistics", function(_, cb)
    cb(lib.callback.await('eg_reports:server:get_statistics', false))
end)

RegisterNUICallback("add_comment", function(data, cb)
    if not data.reportId or not data.content or #data.content < 1 then cb(false) return end
    cb(lib.callback.await('eg_reports:server:add_comment', false, data.reportId, data.content, data.isInternal or false))
end)

RegisterNUICallback("delete_report", function(reportId, cb)
    if not reportId then cb(false) return end
    cb(lib.callback.await('eg_reports:server:delete_report', false, reportId))
end)

RegisterNUICallback("bring_to_reporter", function(reportId, cb)
    if not reportId then cb(false) return end
    local coords = lib.callback.await('eg_reports:server:bring_to_reporter', false, reportId)
    if coords then
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
        Bridge.Notify('Teleported to reporter', 'success')
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback("goto_location", function(reportId, cb)
    if not reportId then cb(false) return end
    local location = lib.callback.await('eg_reports:server:goto_location', false, reportId)
    if location then
        SetEntityCoords(PlayerPedId(), location.x, location.y, location.z, false, false, false, true)
        Bridge.Notify('Teleported to location', 'success')
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback("notify_new_comment", function(data, cb)
    if data and data.message then
        Bridge.Notify(data.message, 'info')
    end
    cb('ok')
end)

RegisterNUICallback("spectate_reporter", function(reportId, cb)
    if not reportId then cb(false) return end
    local targetSource = lib.callback.await('eg_reports:server:get_reporter_source', false, reportId)
    if not targetSource then
        Bridge.Notify('Player is not online', 'error')
        cb(false)
        return
    end

    if targetSource == GetPlayerServerId(PlayerId()) then
        Bridge.Notify('You cannot spectate yourself', 'error')
        cb(false)
        return
    end

    UI.Close()
    cb(true)

    Wait(500)

    local targetPlayer = GetPlayerFromServerId(targetSource)
    if targetPlayer == -1 then
        Bridge.Notify('Player not found nearby', 'error')
        return
    end

    local targetPed = GetPlayerPed(targetPlayer)
    if not targetPed or not DoesEntityExist(targetPed) then
        Bridge.Notify('Player not found', 'error')
        return
    end

    local coords = GetEntityCoords(targetPed)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityVisible(PlayerPedId(), false, false)

    Wait(200)
    NetworkSetInSpectatorMode(true, targetPed)
    Bridge.Notify('Spectating player - Press E to stop', 'info')

    CreateThread(function()
        while NetworkIsInSpectatorMode() do
            Wait(0)
            if IsControlJustPressed(0, 38) then
                NetworkSetInSpectatorMode(false, targetPed)
                FreezeEntityPosition(PlayerPedId(), false)
                SetEntityVisible(PlayerPedId(), true, false)
                Bridge.Notify('Stopped spectating', 'info')
                break
            end
        end
    end)
end)

RegisterNUICallback("take_screenshot", function(_, cb)
    local config = lib.callback.await('eg_reports:server:get_upload_config', false)
    if not config or not config.url or config.url == '' then
        cb(nil)
        return
    end

    exports['screenshot-basic']:requestScreenshotUpload(config.url, config.field, {
        encoding = 'png'
    }, function(data)
        if not data then
            cb(nil)
            return
        end

        local response = json.decode(data)
        if response and response.attachments and response.attachments[1] then
            cb(response.attachments[1].url)
        else
            cb(nil)
        end
    end)
end)

RegisterNUICallback("rate_report", function(data, cb)
    if not data.reportId or not data.rating then cb(false) return end
    cb(lib.callback.await('eg_reports:server:rate_report', false, data.reportId, data.rating))
end)

RegisterNUICallback("get_my_stats", function(_, cb)
    cb(lib.callback.await('eg_reports:server:get_my_stats', false))
end)

RegisterNUICallback("get_admin_self_stats", function(_, cb)
    cb(lib.callback.await('eg_reports:server:get_admin_self_stats', false))
end)
