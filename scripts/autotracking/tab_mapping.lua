-- Maps SM64 location IDs to tracker tabs.
-- IDs follow the same format as EntranceMapper: level * 10 + area (e.g. 91 = BOB area 1).
-- Values are "Parent/Child" tab titles; each level is activated in order.

-- Exact level+area IDs, for levels whose areas go to different tabs
TAB_MAPPING = {
    [61]  = "Castle/Main Floor",
    [62]  = "Castle/Upper Floors",
    [63]  = "Castle/Basement",
    [161] = "Castle/Grounds",
    [261] = "Castle/Courtyard",
}

-- Fallback by level number only (ID // 10), for levels where every area shares a tab
LEVEL_TAB_MAPPING = {
    [9]  = "Courses/BOB",
    [24] = "Courses/WF",
    [12] = "Courses/JRB",
    [5]  = "Courses/CCM",
    [4]  = "Courses/BBH",
    [7]  = "Courses/HMC",
    [22] = "Courses/LLL",
    [8]  = "Courses/SSL",
    [23] = "Courses/DDD",
    [10] = "Courses/SL",
    [11] = "Courses/WDW",
    [36] = "Courses/TTM",
    [13] = "Courses/THI",
    [14] = "Courses/TTC",
    [15] = "Courses/RR",

    [27] = "Secrets/PSS",
    [20] = "Secrets/SA",
    [31] = "Secrets/WMotR",
    [29] = "Secrets/TotWC",
    [28] = "Secrets/CotMC",
    [18] = "Secrets/VCutM",

    [17] = "Bowser/BitDW",
    [30] = "Bowser/BitDW",
    [19] = "Bowser/BitFS",
    [33] = "Bowser/BitFS",
    [21] = "Bowser/BitS",
    [34] = "Bowser/BitS",
}

function getTabsForID(id)
    local path = TAB_MAPPING[id] or LEVEL_TAB_MAPPING[id // 10]
    if path == nil then
        return nil
    end
    local tabs = {}
    for str in string.gmatch(path, "([^/]+)") do
        table.insert(tabs, str)
    end
    return tabs
end
