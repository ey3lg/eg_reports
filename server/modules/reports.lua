
Reports = {}
function Reports.ValidateReportData(data)
    if not data then
        return false, 'No data provided'
    end

    if not data.category or not data.title or not data.description then
        return false, 'Missing required fields'
    end

    if not data.priority then
        data.priority = Config.DefaultPriority or 'medium'
    end

    if type(data.title) ~= 'string' or #data.title < 3 or #data.title > 255 then
        return false, 'Title must be between 3 and 255 characters'
    end

    if type(data.description) ~= 'string' or #data.description < 10 then
        return false, 'Description must be at least 10 characters'
    end

    local validCategories = {}
    for i = 1, #Config.Categories do
        validCategories[Config.Categories[i].id] = true
    end

    if not validCategories[data.category] then
        return false, 'Invalid category'
    end

    local validPriorities = {}
    for i = 1, #Config.Priorities do
        validPriorities[Config.Priorities[i].id] = true
    end

    if not validPriorities[data.priority] then
        return false, 'Invalid priority'
    end

    if data.evidence then
        if type(data.evidence) ~= 'table' then
            return false, 'Evidence must be an array'
        end

        if #data.evidence > Config.UI.MaxEvidenceFiles then
            return false, 'Too many evidence files (max: ' .. Config.UI.MaxEvidenceFiles .. ')'
        end
    end

    return true
end

function Reports.HasPermission(source)
    if not source or source == 0 then return false end
    return Bridge.HasPermission(source)
end

function Reports.CanViewReport(source, report)
    if not source or not report then return false end

    local identifier = Bridge.GetPlayerIdentifier(source)

    if report.reporter_identifier == identifier then
        return true
    end

    if Reports.HasPermission(source) then
        return true
    end

    return false
end

function Reports.CanViewInternalComments(source)
    return Reports.HasPermission(source)
end

function Reports.GetPlayerInfo(source)
    local identifier = Bridge.GetPlayerIdentifier(source)
    local name = Bridge.GetPlayerDisplayName(source)

    return identifier, name
end

function Reports.GetPlayerSourceByIdentifier(identifier)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerIdentifier = Bridge.GetPlayerIdentifier(tonumber(playerId))
        if playerIdentifier == identifier then
            return tonumber(playerId)
        end
    end
    return nil
end

function Reports.NotifyAllStaff(message, type, excludeSource)
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid ~= excludeSource and Bridge.IsStaff(pid) and Bridge.IsOnDuty(pid) then
            Bridge.Notify(pid, message, type or 'info')
        end
    end
end

function Reports.LogAction(source, event, message)
    if not Config.Logging or not Config.Logging.Enabled then return end
    local ok, err = pcall(function()
        lib.logger(source, event, message)
    end)
    if not ok then
        print('^3[eg_reports] Logger error: ' .. tostring(err) .. '^7')
    end
end

return Reports
