Config = {}

Config.Language = 'en'

Config.Database = {
    CleanupOldReports = true,
    CleanupDays = 90,
}

Config.Performance = {
    CachePermissions = true,
    CacheTimeout = 300,
}

Config.Categories = {
    { id = 'rdm', label = 'RDM (Random Deathmatch)', icon = 'pi pi-bolt', severity = 'danger' },
    { id = 'vdm', label = 'VDM (Vehicle Deathmatch)', icon = 'pi pi-car', severity = 'danger' },
    { id = 'bug', label = 'Bug Report', icon = 'pi pi-bug', severity = 'warning' },
    { id = 'staff', label = 'Staff Report', icon = 'pi pi-shield', severity = 'danger' },
    { id = 'suggestion', label = 'Suggestion', icon = 'pi pi-lightbulb', severity = 'info' },
    { id = 'other', label = 'Other', icon = 'pi pi-question-circle', severity = 'info' },
}

Config.Priorities = {
    { id = 'low', label = 'Low', color = 'success' },
    { id = 'medium', label = 'Medium', color = 'warning' },
    { id = 'high', label = 'High', color = 'danger' },
    { id = 'critical', label = 'Critical', color = 'danger' },
}

Config.Statuses = {
    { id = 'open', label = 'Open', color = 'info' },
    { id = 'in_progress', label = 'In Progress', color = 'warning' },
    { id = 'pending', label = 'Pending Response', color = 'secondary' },
    { id = 'resolved', label = 'Resolved', color = 'success' },
    { id = 'archived', label = 'Archived', color = 'secondary' },
}

Config.AutoAssignment = {
    Enabled = false,
    MinStaffOnline = 2,
}

Config.BlockAdminReports = false
Config.MaxOpenReports = 1