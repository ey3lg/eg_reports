lib.callback.register('eg_reports:server:get_upload_config', function(source)
    return {
        url = ServerConfig.Screenshot and ServerConfig.Screenshot.UploadURL or '',
        field = ServerConfig.Screenshot and ServerConfig.Screenshot.FieldName or 'files[]'
    }
end)

lib.callback.register('eg_reports:server:create_report', function(source, data)
    if Config.BlockAdminReports and Reports.HasPermission(source) then
        Bridge.Notify(source, 'Admins are not allowed to create reports', 'error')
        return false
    end

    local valid, error = Reports.ValidateReportData(data)
    if not valid then
        Bridge.Notify(source, error, 'error')
        return false
    end

    local identifier, name = Reports.GetPlayerInfo(source)
    if not identifier then
        Bridge.Notify(source, _('error_unknown'), 'error')
        return false
    end

    if Config.MaxOpenReports and Config.MaxOpenReports > 0 then
        local openCount = Database.GetOpenReportCount(identifier)
        if openCount >= Config.MaxOpenReports then
            Bridge.Notify(source, 'You already have ' .. openCount .. ' open report(s). Please wait until it is resolved.', 'error')
            return false
        end
    end

    if Config.ReportCooldown and Config.ReportCooldown > 0 then
        local cooldownCheck = Database.CheckCooldown(identifier, Config.ReportCooldown)
        if cooldownCheck and cooldownCheck > 0 then
            Bridge.Notify(source, 'Please wait ' .. cooldownCheck .. ' seconds before creating another report.', 'error')
            return false
        end
    end

    local reportId = Database.CreateReport({
        identifier = identifier,
        name = name,
        category = data.category,
        priority = data.priority,
        title = data.title,
        description = data.description,
        location = data.location,
        evidence = data.evidence or {}
    })

    if reportId then
        Webhooks.Send('NewReport', {
            id = reportId,
            category = data.category,
            priority = data.priority,
            reporter_name = name,
            title = data.title
        })

        if data.priority == 'high' or data.priority == 'critical' then
            Webhooks.Send('Escalated', { id = reportId, priority = data.priority, category = data.category, title = data.title })
        end

        if data.category == 'staff' then
            Webhooks.Send('StaffReport', { id = reportId, reporter_name = name, priority = data.priority, title = data.title })
        end

        Bridge.Notify(source, _('report_created'), 'success')
        return reportId
    end

    Bridge.Notify(source, _('report_failed'), 'error')
    return false
end)

lib.callback.register('eg_reports:server:get_my_reports', function(source)
    local identifier = Reports.GetPlayerInfo(source)
    if not identifier then return {} end
    return Database.GetReportsByReporter(identifier)
end)

lib.callback.register('eg_reports:server:get_report_details', function(source, reportId)
    if not reportId then return nil end

    local report = Database.GetReportById(reportId)
    if not report then return nil end

    if not Reports.CanViewReport(source, report) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return nil
    end

    return {
        report = report,
        comments = Database.GetComments(reportId, Reports.CanViewInternalComments(source)),
        history = Database.GetHistory(reportId)
    }
end)

lib.callback.register('eg_reports:server:claim_report', function(source, reportId)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end
    if not reportId then return false end

    local identifier, name = Reports.GetPlayerInfo(source)
    local success = Database.ClaimReport(reportId, identifier, name)

    if success then
        Webhooks.Send('Claimed', { id = reportId, assigned_to_name = name })
        Bridge.Notify(source, _('report_claimed'), 'success')
    else
        Bridge.Notify(source, _('report_claim_failed'), 'error')
    end
    return success
end)

lib.callback.register('eg_reports:server:update_status', function(source, reportId, newStatus)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end
    if not reportId or not newStatus then return false end

    local identifier, name = Reports.GetPlayerInfo(source)
    local success = Database.UpdateReport(reportId, { status = newStatus }, identifier, name)
    if success then Bridge.Notify(source, _('report_updated'), 'success') end
    return success
end)

lib.callback.register('eg_reports:server:close_report', function(source, reportId)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end
    if not reportId then return false end

    local identifier, name = Reports.GetPlayerInfo(source)
    local success = Database.CloseReport(reportId, identifier, name)

    if success then
        Webhooks.Send('Closed', { id = reportId, closed_by_name = name })
        Bridge.Notify(source, _('report_closed'), 'success')
    else
        Bridge.Notify(source, _('report_close_failed'), 'error')
    end
    return success
end)

lib.callback.register('eg_reports:server:get_admin_reports', function(source, filters)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return {}
    end
    return Database.GetAllReports(filters or {})
end)

lib.callback.register('eg_reports:server:get_statistics', function(source)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return nil
    end
    return Database.GetStatistics()
end)

lib.callback.register('eg_reports:server:add_comment', function(source, reportId, content, isInternal)
    if not reportId or not content or #content < 1 then return false end

    local report = Database.GetReportById(reportId)
    if not report then return false end

    if not Reports.CanViewReport(source, report) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end

    local identifier, name = Reports.GetPlayerInfo(source)
    local isStaff = Reports.HasPermission(source)
    if isInternal and not isStaff then isInternal = false end

    local success = Database.AddComment(reportId, identifier, name, content, isInternal, isStaff)

    if success and isStaff and not isInternal then
        local reporterSource = Reports.GetPlayerSourceByIdentifier(report.reporter_identifier)
        if reporterSource and reporterSource ~= source then
            Bridge.Notify(reporterSource, 'Staff replied to your report #' .. reportId, 'info')
        end
    end

    Bridge.Notify(source, success and _('comment_added') or _('comment_failed'), success and 'success' or 'error')
    return success
end)

lib.callback.register('eg_reports:server:delete_report', function(source, reportId)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end
    if not reportId then return false end

    local identifier, name = Reports.GetPlayerInfo(source)
    local success = Database.DeleteReport(reportId, identifier, name)

    if success then
        Webhooks.Send('Deleted', { id = reportId, deleted_by_name = name })
        Bridge.Notify(source, _('report_deleted'), 'success')
    else
        Bridge.Notify(source, _('report_delete_failed'), 'error')
    end
    return success
end)

lib.callback.register('eg_reports:server:bring_to_reporter', function(source, reportId)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end

    local report = Database.GetReportById(reportId)
    if not report then
        Bridge.Notify(source, _('report_not_found'), 'error')
        return false
    end

    local reporterSource = Reports.GetPlayerSourceByIdentifier(report.reporter_identifier)
    if not reporterSource then
        Bridge.Notify(source, _('player_not_online'), 'error')
        return false
    end

    local coords = Bridge.GetPlayerCoords(reporterSource)
    return { x = coords.x, y = coords.y, z = coords.z }
end)

lib.callback.register('eg_reports:server:goto_location', function(source, reportId)
    if not Reports.HasPermission(source) then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end

    local report = Database.GetReportById(reportId)
    if not report or not report.location then
        Bridge.Notify(source, _('location_not_available'), 'error')
        return false
    end

    return json.decode(report.location)
end)

lib.callback.register('eg_reports:server:has_permission', function(source)
    return {
        hasPermission = Reports.HasPermission(source),
        identifier = Bridge.GetPlayerIdentifier(source)
    }
end)

lib.callback.register('eg_reports:server:get_reporter_source', function(source, reportId)
    if not Reports.HasPermission(source) then return nil end

    local report = Database.GetReportById(reportId)
    if not report then return nil end

    return Reports.GetPlayerSourceByIdentifier(report.reporter_identifier)
end)

lib.callback.register('eg_reports:server:rate_report', function(source, reportId, rating)
    if not reportId or not rating then return false end

    local report = Database.GetReportById(reportId)
    if not report then return false end

    local identifier = Reports.GetPlayerInfo(source)
    if report.reporter_identifier ~= identifier then
        Bridge.Notify(source, _('no_permission'), 'error')
        return false
    end

    if rating < 1 or rating > 5 then return false end

    local success = Database.RateReport(reportId, rating)
    if success then
        Bridge.Notify(source, _('rating_submitted') or 'Rating submitted', 'success')
    end
    return success
end)

lib.callback.register('eg_reports:server:get_admin_stats', function(source)
    if not Reports.HasPermission(source) then return nil end
    return Database.GetAdminStats()
end)

lib.callback.register('eg_reports:server:notify_reporter', function(source, reportId, message)
    if not Reports.HasPermission(source) then return false end

    local report = Database.GetReportById(reportId)
    if not report then return false end

    local reporterSource = Reports.GetPlayerSourceByIdentifier(report.reporter_identifier)
    if reporterSource then
        Bridge.Notify(reporterSource, message, 'info')
        return true
    end
    return false
end)

lib.callback.register('eg_reports:server:get_my_stats', function(source)
    local identifier = Reports.GetPlayerInfo(source)
    if not identifier then return nil end
    return Database.GetMyStats(identifier)
end)

lib.callback.register('eg_reports:server:get_admin_self_stats', function(source)
    if not Reports.HasPermission(source) then return nil end
    local identifier = Reports.GetPlayerInfo(source)
    if not identifier then return nil end
    return Database.GetAdminSelfStats(identifier)
end)
