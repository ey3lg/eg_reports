Database = {
    Cache = {
        Permissions = {},
        LastCleanup = 0
    }
}
function Database.CreateReport(data)
    local query = [[
        INSERT INTO eg_reports
        (reporter_identifier, reporter_name, category, priority, title, description, location, evidence, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'open')
    ]]

    local result = MySQL.insert.await(query, {
        data.identifier,
        data.name,
        data.category,
        data.priority,
        data.title,
        data.description,
        data.location,
        json.encode(data.evidence or {})
    })

    if result then
        Database.AddHistory(result, 'created', data.identifier, data.name, 'Report created')
    end

    return result
end

function Database.GetReportById(id)
    local query = "SELECT * FROM eg_reports WHERE id = ? LIMIT 1"
    local result = MySQL.query.await(query, { id })

    if result and result[1] then
        local report = result[1]
        if report.evidence and report.evidence ~= '' then
            local decoded = json.decode(report.evidence)
            if type(decoded) == 'table' and #decoded > 0 then
                report.evidence = decoded
            else
                report.evidence = {}
            end
        else
            report.evidence = {}
        end
        return report
    end

    return nil
end

function Database.GetReportsByReporter(identifier)
    local query = [[
        SELECT r.*,
            (SELECT COUNT(*) FROM eg_report_comments c
             WHERE c.report_id = r.id AND c.is_staff = 1 AND c.is_internal = 0
            ) as admin_replies
        FROM eg_reports r
        WHERE r.reporter_identifier = ?
        ORDER BY r.created_at DESC
        LIMIT 100
    ]]

    local results = MySQL.query.await(query, { identifier })

    if results then
        for i = 1, #results do
            if results[i].evidence then
                results[i].evidence = json.decode(results[i].evidence)
            end
            results[i].has_admin_response = (results[i].admin_replies or 0) > 0
            results[i].admin_replies = nil
        end
    end

    return results or {}
end

function Database.GetAllReports(filters)
    local query = "SELECT * FROM eg_reports WHERE 1=1"
    local params = {}

    if filters.status then
        query = query .. " AND status = ?"
        params[#params + 1] = filters.status
    end

    if filters.category then
        query = query .. " AND category = ?"
        params[#params + 1] = filters.category
    end

    if filters.priority then
        query = query .. " AND priority = ?"
        params[#params + 1] = filters.priority
    end

    if filters.assigned_to then
        query = query .. " AND assigned_to = ?"
        params[#params + 1] = filters.assigned_to
    end

    if filters.search then
        query = query .. " AND (title LIKE ? OR description LIKE ?)"
        local searchTerm = "%" .. filters.search .. "%"
        params[#params + 1] = searchTerm
        params[#params + 1] = searchTerm
    end

    query = query .. " ORDER BY created_at DESC LIMIT 100"

    local results = MySQL.query.await(query, params)

    if results then
        for i = 1, #results do
            if results[i].evidence then
                results[i].evidence = json.decode(results[i].evidence)
            end
        end
    end

    return results or {}
end

function Database.UpdateReport(id, data, actorIdentifier, actorName)
    local updates = {}
    local params = {}

    for key, value in pairs(data) do
        updates[#updates + 1] = key .. " = ?"
        params[#params + 1] = value
    end

    if #updates == 0 then return false end

    params[#params + 1] = id

    local query = "UPDATE eg_reports SET " .. table.concat(updates, ", ") .. " WHERE id = ?"
    local result = MySQL.update.await(query, params)

    if result then
        Database.AddHistory(id, 'updated', actorIdentifier, actorName, json.encode(data))
    end

    return result > 0
end

function Database.ClaimReport(reportId, identifier, name)
    local success = Database.UpdateReport(reportId, {
        assigned_to = identifier,
        assigned_to_name = name,
        status = 'in_progress'
    }, identifier, name)

    if success then
        Database.AddHistory(reportId, 'claimed', identifier, name, 'Report claimed')
    end

    return success
end

function Database.CloseReport(reportId, identifier, name)
    local success = Database.UpdateReport(reportId, {
        status = 'resolved',
        closed_at = os.date('%Y-%m-%d %H:%M:%S')
    }, identifier, name)

    if success then
        Database.AddHistory(reportId, 'closed', identifier, name, 'Report closed')
    end

    return success
end

function Database.DeleteReport(id, actorIdentifier, actorName)
    local report = Database.GetReportById(id)
    if report then
        local archiveQuery = [[
            INSERT INTO eg_reports_archived 
            (original_report_id, reporter_identifier, reporter_name, category, priority, status, 
             title, description, location, evidence, assigned_to, assigned_to_name, rating, 
             created_at, updated_at, closed_at, deleted_by, deleted_by_name)
            SELECT id, reporter_identifier, reporter_name, category, priority, status,
                   title, description, location, evidence, assigned_to, assigned_to_name, rating,
                   created_at, updated_at, closed_at, ?, ?
            FROM eg_reports WHERE id = ?
        ]]
        MySQL.insert.await(archiveQuery, { actorIdentifier, actorName, id })
    end
    local query = "DELETE FROM eg_reports WHERE id = ?"
    local result = MySQL.query.await(query, { id })

    return result and result.affectedRows > 0
end

function Database.AddComment(reportId, authorIdentifier, authorName, content, isInternal, isStaff)
    local query = [[
        INSERT INTO eg_report_comments
        (report_id, author_identifier, author_name, content, is_internal, is_staff)
        VALUES (?, ?, ?, ?, ?, ?)
    ]]

    local result = MySQL.insert.await(query, {
        reportId,
        authorIdentifier,
        authorName,
        content,
        isInternal and 1 or 0,
        isStaff and 1 or 0
    })

    if result then
        Database.AddHistory(reportId, 'commented', authorIdentifier, authorName, isInternal and 'Internal comment added' or 'Comment added')
    end

    return result
end

function Database.GetComments(reportId, includeInternal)
    local query = "SELECT * FROM eg_report_comments WHERE report_id = ?"

    if not includeInternal then
        query = query .. " AND is_internal = 0"
    end

    query = query .. " ORDER BY created_at ASC"

    local results = MySQL.query.await(query, { reportId })
    return results or {}
end

function Database.AddHistory(reportId, action, actorIdentifier, actorName, details)
    local query = [[
        INSERT INTO eg_report_history
        (report_id, action, actor_identifier, actor_name, details)
        VALUES (?, ?, ?, ?, ?)
    ]]

    MySQL.insert(query, {
        reportId,
        action,
        actorIdentifier,
        actorName,
        details or ''
    })
end

function Database.GetHistory(reportId)
    local query = [[
        SELECT * FROM eg_report_history
        WHERE report_id = ?
        ORDER BY created_at ASC
    ]]

    local results = MySQL.query.await(query, { reportId })
    return results or {}
end

function Database.GetStatistics()
    local stats = {}

    local totalResult = MySQL.query.await("SELECT COUNT(*) as count FROM eg_reports")
    stats.total = totalResult and totalResult[1] and totalResult[1].count or 0

    local byStatusResult = MySQL.query.await([[
        SELECT status, COUNT(*) as count
        FROM eg_reports
        GROUP BY status
    ]])

    stats.byStatus = {}
    if byStatusResult then
        for i = 1, #byStatusResult do
            stats.byStatus[byStatusResult[i].status] = byStatusResult[i].count
        end
    end

    local byCategoryResult = MySQL.query.await([[
        SELECT category, COUNT(*) as count
        FROM eg_reports
        GROUP BY category
    ]])

    stats.byCategory = {}
    if byCategoryResult then
        for i = 1, #byCategoryResult do
            stats.byCategory[byCategoryResult[i].category] = byCategoryResult[i].count
        end
    end

    local byPriorityResult = MySQL.query.await([[
        SELECT priority, COUNT(*) as count
        FROM eg_reports
        GROUP BY priority
    ]])

    stats.byPriority = {}
    if byPriorityResult then
        for i = 1, #byPriorityResult do
            stats.byPriority[byPriorityResult[i].priority] = byPriorityResult[i].count
        end
    end

    local recentResult = MySQL.query.await([[
        SELECT COUNT(*) as count
        FROM eg_reports
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ]])

    stats.recentCount = recentResult and recentResult[1] and recentResult[1].count or 0

    local todayResult = MySQL.query.await([[
        SELECT COUNT(*) as count
        FROM eg_reports
        WHERE DATE(created_at) = CURDATE()
    ]])

    stats.todayCount = todayResult and todayResult[1] and todayResult[1].count or 0

    return stats
end

function Database.CleanupOldReports()
    if not Config.Database.CleanupOldReports then return end

    local now = os.time()
    if now - Database.Cache.LastCleanup < 86400 then return end

    local query = [[
        UPDATE eg_reports
        SET status = 'archived'
        WHERE status = 'resolved'
        AND closed_at IS NOT NULL
        AND closed_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]]

    local result = MySQL.update.await(query, { Config.Database.CleanupDays })
    Database.Cache.LastCleanup = now
end

function Database.RateReport(reportId, rating)
    local query = "UPDATE eg_reports SET rating = ? WHERE id = ?"
    local result = MySQL.update.await(query, { rating, reportId })
    return result and result > 0
end

function Database.GetAdminStats()
    local query = [[
        SELECT
            assigned_to as identifier,
            assigned_to_name as name,
            COUNT(*) as total_reports,
            SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved_reports,
            AVG(rating) as average_rating,
            COUNT(rating) as rated_reports
        FROM eg_reports
        WHERE assigned_to IS NOT NULL
        GROUP BY assigned_to, assigned_to_name
        ORDER BY total_reports DESC
    ]]

    local results = MySQL.query.await(query)
    return results or {}
end

function Database.UpdateReportScreenshot(reportId, screenshotUrl)
    local report = Database.GetReportById(reportId)
    if not report then return false end

    local evidence = report.evidence or {}
    evidence[#evidence + 1] = screenshotUrl

    local query = "UPDATE eg_reports SET evidence = ? WHERE id = ?"
    local result = MySQL.update.await(query, { json.encode(evidence), reportId })
    return result and result > 0
end

function Database.GetOpenReportCount(identifier)
    local query = "SELECT COUNT(*) as count FROM eg_reports WHERE reporter_identifier = ? AND status NOT IN ('resolved', 'archived')"
    local result = MySQL.query.await(query, { identifier })
    return result and result[1] and result[1].count or 0
end

function Database.CheckCooldown(identifier, cooldownSeconds)
    local query = [[
        SELECT GREATEST(0, ? - TIMESTAMPDIFF(SECOND, created_at, NOW())) as remaining
        FROM eg_reports
        WHERE reporter_identifier = ?
        ORDER BY created_at DESC
        LIMIT 1
    ]]
    local result = MySQL.query.await(query, { cooldownSeconds, identifier })
    if result and result[1] then
        return result[1].remaining or 0
    end
    return 0
end

function Database.GetMyStats(identifier)
    local stats = {}

    local totalResult = MySQL.query.await(
        "SELECT COUNT(*) as count FROM eg_reports WHERE reporter_identifier = ?",
        { identifier }
    )
    stats.total = totalResult and totalResult[1] and totalResult[1].count or 0

    local byStatusResult = MySQL.query.await([[
        SELECT status, COUNT(*) as count
        FROM eg_reports
        WHERE reporter_identifier = ?
        GROUP BY status
    ]], { identifier })

    stats.open = 0
    stats.in_progress = 0
    stats.resolved = 0
    if byStatusResult then
        for i = 1, #byStatusResult do
            local row = byStatusResult[i]
            if row.status == 'open' then stats.open = row.count
            elseif row.status == 'in_progress' then stats.in_progress = row.count
            elseif row.status == 'resolved' then stats.resolved = row.count
            end
        end
    end

    local avgRatingResult = MySQL.query.await([[
        SELECT AVG(rating) as avg_rating, COUNT(rating) as rated_count
        FROM eg_reports
        WHERE reporter_identifier = ? AND rating IS NOT NULL
    ]], { identifier })

    stats.avgRating = avgRatingResult and avgRatingResult[1] and avgRatingResult[1].avg_rating or 0
    stats.ratedCount = avgRatingResult and avgRatingResult[1] and avgRatingResult[1].rated_count or 0

    return stats
end

function Database.GetAdminSelfStats(identifier)
    local stats = {}

    local claimedResult = MySQL.query.await([[
        SELECT COUNT(*) as count FROM eg_reports WHERE assigned_to = ?
    ]], { identifier })
    stats.totalClaimed = claimedResult and claimedResult[1] and claimedResult[1].count or 0

    local closedResult = MySQL.query.await([[
        SELECT COUNT(*) as count FROM eg_report_history
        WHERE actor_identifier = ? AND action = 'closed'
    ]], { identifier })
    stats.totalClosed = closedResult and closedResult[1] and closedResult[1].count or 0

    local ratingResult = MySQL.query.await([[
        SELECT AVG(rating) as avg_rating, COUNT(rating) as rated_count
        FROM (
            SELECT rating FROM eg_reports WHERE assigned_to = ? AND rating IS NOT NULL
            UNION ALL
            SELECT rating FROM eg_reports_archived WHERE assigned_to = ? AND rating IS NOT NULL
        ) AS all_ratings
    ]], { identifier, identifier })
    stats.avgRating = ratingResult and ratingResult[1] and ratingResult[1].avg_rating or 0
    stats.ratedCount = ratingResult and ratingResult[1] and ratingResult[1].rated_count or 0

    local ratingDist = MySQL.query.await([[
        SELECT rating, COUNT(*) as count
        FROM (
            SELECT rating FROM eg_reports WHERE assigned_to = ? AND rating IS NOT NULL
            UNION ALL
            SELECT rating FROM eg_reports_archived WHERE assigned_to = ? AND rating IS NOT NULL
        ) AS all_ratings
        GROUP BY rating
        ORDER BY rating ASC
    ]], { identifier, identifier })
    stats.ratingDistribution = { 0, 0, 0, 0, 0 }
    if ratingDist then
        for i = 1, #ratingDist do
            local r = ratingDist[i]
            local rating = tonumber(r.rating)
            if rating and rating >= 1 and rating <= 5 then
                stats.ratingDistribution[rating] = r.count
            end
        end
    end

    local recentResult = MySQL.query.await([[
        SELECT id, title, category, priority, status, rating, assigned_to_name, created_at, closed_at
        FROM eg_reports
        WHERE assigned_to = ?
        ORDER BY updated_at DESC
        LIMIT 20
    ]], { identifier })
    stats.recentReports = recentResult or {}

    local dailyResult = MySQL.query.await([[
        SELECT DATE(h.created_at) as day, COUNT(*) as count
        FROM eg_report_history h
        WHERE h.actor_identifier = ? AND h.action IN ('claimed', 'closed')
        AND h.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
        GROUP BY DATE(h.created_at)
        ORDER BY day ASC
    ]], { identifier })
    stats.dailyActivity = dailyResult or {}

    local dayOfWeekRating = MySQL.query.await([[
        SELECT 
            DAYOFWEEK(created_at) - 1 as day_of_week,
            AVG(rating) as avg_rating,
            COUNT(rating) as rating_count
        FROM (
            SELECT created_at, rating FROM eg_reports WHERE assigned_to = ? AND rating IS NOT NULL
            UNION ALL
            SELECT created_at, rating FROM eg_reports_archived WHERE assigned_to = ? AND rating IS NOT NULL
        ) AS all_reports
        GROUP BY DAYOFWEEK(created_at)
        ORDER BY day_of_week ASC
    ]], { identifier, identifier })
    
    stats.ratingByDayOfWeek = { 0, 0, 0, 0, 0, 0, 0 }
    stats.ratingCountByDay = { 0, 0, 0, 0, 0, 0, 0 }
    if dayOfWeekRating then
        for i = 1, #dayOfWeekRating do
            local row = dayOfWeekRating[i]
            local dayIdx = tonumber(row.day_of_week) or 0
            if dayIdx >= 0 and dayIdx <= 6 then
                stats.ratingByDayOfWeek[dayIdx + 1] = tonumber(row.avg_rating) or 0
                stats.ratingCountByDay[dayIdx + 1] = tonumber(row.rating_count) or 0
            end
        end
    end

    return stats
end

return Database
