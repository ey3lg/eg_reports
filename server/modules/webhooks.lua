Webhooks = {}

function Webhooks.Send(webhookType, data)
    if not ServerConfig.Webhooks.Enabled then return end

    local url = ServerConfig.Webhooks.URLs[webhookType]
    if not url or url == '' then return end

    local embed = Webhooks.BuildEmbed(webhookType, data)

    PerformHttpRequest(url, function(statusCode, response, headers)
    end, 'POST', json.encode(embed), {
        ['Content-Type'] = 'application/json'
    })
end

function Webhooks.BuildEmbed(webhookType, data)
    local color = 3447003 -- Blue default
    local title = 'Report System Event'
    local description = ''
    local fields = {}

    if webhookType == 'NewReport' then
        color = 15105570 -- Orange
        title = '📋 New Report Created'
        fields = {
            { name = 'Report ID', value = '#' .. tostring(data.id), inline = true },
            { name = 'Category', value = data.category or 'N/A', inline = true },
            { name = 'Priority', value = data.priority or 'N/A', inline = true },
            { name = 'Reporter', value = data.reporter_name or 'Unknown', inline = false },
            { name = 'Title', value = data.title or 'No title', inline = false },
        }

    elseif webhookType == 'Claimed' then
        color = 15844367 -- Gold
        title = '👤 Report Claimed'
        fields = {
            { name = 'Report ID', value = '#' .. tostring(data.id), inline = true },
            { name = 'Claimed By', value = data.assigned_to_name or 'Unknown', inline = true },
        }

    elseif webhookType == 'Closed' then
        color = 3066993 -- Green
        title = '✅ Report Resolved'
        fields = {
            { name = 'Report ID', value = '#' .. tostring(data.id), inline = true },
            { name = 'Closed By', value = data.closed_by_name or 'Unknown', inline = true },
        }

    elseif webhookType == 'Escalated' then
        color = 15158332 -- Red
        title = '🚨 High Priority Report'
        fields = {
            { name = 'Report ID', value = '#' .. tostring(data.id), inline = true },
            { name = 'Priority', value = data.priority or 'High', inline = true },
            { name = 'Category', value = data.category or 'N/A', inline = true },
            { name = 'Title', value = data.title or 'No title', inline = false },
        }

    elseif webhookType == 'StaffReport' then
        color = 10038562 -- Dark red
        title = '⚠️ Staff Report Filed'
        fields = {
            { name = 'Report ID', value = '#' .. tostring(data.id), inline = true },
            { name = 'Reporter', value = data.reporter_name or 'Unknown', inline = true },
            { name = 'Priority', value = data.priority or 'N/A', inline = true },
            { name = 'Title', value = data.title or 'No title', inline = false },
        }

    elseif webhookType == 'Deleted' then
        color = 9807270 -- Grey
        title = '🗑️ Report Deleted'
        fields = {
            { name = 'Report ID', value = '#' .. tostring(data.id), inline = true },
            { name = 'Deleted By', value = data.deleted_by_name or 'Unknown', inline = true },
        }
    end

    local embed = {
        embeds = {
            {
                title = title,
                color = color,
                fields = fields,
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
                footer = {
                    text = 'eg_reports | egtebex.tebex.io'
                }
            }
        }
    }

    return embed
end

return Webhooks
