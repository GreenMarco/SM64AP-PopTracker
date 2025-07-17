-- this is an example/ default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via thier ids
-- it will also load the AP slot data in the global SLOT_DATA, keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")

CUR_INDEX = -1
SLOT_DATA = nil
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

function onClear(slot_data)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
    end

    Archipelago:Get(data_storage_list)
    print("data storage list", data_storage_list)
    SLOT_DATA = slot_data
    CUR_INDEX = -1

    -- reset locations
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                local obj = Tracker:FindObjectForCode(location)
                if obj then
                    if location:sub(1, 1) == "@" then
                        obj.AvailableChestCount = obj.ChestCount
                    else
                        obj.Active = false
                    end
                end
            end
        end
    end


    -- reset items
    for _, v in pairs(ITEM_MAPPING) do
        if v[1] and v[2] then
            if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: clearing item %s of type %s", v[1], v[2]))
            end
            local obj = Tracker:FindObjectForCode(v[1])
            if obj then
                if v[2] == "toggle" then
                    obj.Active = false
                elseif v[2] == "progressive" then
                    obj.CurrentStage = 0
                    obj.Active = false
                elseif v[2] == "consumable" then
                    obj.AcquiredCount = 0
                elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                    print(string.format("onClear: unknown item type %s for code %s", v[2], v[1]))
                end
            elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
                print(string.format("onClear: could not find object for code %s", v[1]))
            end
        end
    end

    if SLOT_DATA == nil then
            return
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
	TEAM_NUMBER = Archipelago.TeamNumber or 0



        if slot_data["AreaRando"] then
            Tracker:FindObjectForCode("area").Active = slot_data["AreaRando"] ~=0
        end

        if slot_data["StrictMovesRequirements"] then
            Tracker:FindObjectForCode("moves").Active = slot_data["StrictMovesRequirements"]~=0
        end

        if slot_data["StrictCapsRequirements"] then
            Tracker:FindObjectForCode("caps").Active = slot_data["StrictCapsRequirements"]~=0
        end

        if slot_data["StrictCannonsRequirements"] then
            Tracker:FindObjectForCode("cannons").Active = slot_data["StrictCannonsRequirements"]~=0
        end

        if slot_data["enable_coin_stars"] then
            Tracker:FindObjectForCode("100coins").Active = slot_data["enable_coin_stars"]~=0
        end

        if slot_data["1UpMushroom"] then
            Tracker:FindObjectForCode("1upbox").Active = slot_data["1UpMushroom"] ~=0
        end

        if slot_data["Buddy_Checks"] then
            Tracker:FindObjectForCode("pinkbomb").Active = slot_data["Buddy_Checks"]~=0
        end

        if slot_data['MoveRandoVec'] then
            print("slot_data['MoveRandoVec']: " .. slot_data['MoveRandoVec'])
            if slot_data['MoveRandoVec'] == 0 then
                Tracker:FindObjectForCode("tj").Active = 1
                Tracker:FindObjectForCode("lj").Active = 1
                Tracker:FindObjectForCode("bf").Active = 1
                Tracker:FindObjectForCode("sf").Active = 1
                Tracker:FindObjectForCode("wk").Active = 1
                Tracker:FindObjectForCode("dv").Active = 1
                Tracker:FindObjectForCode("gp").Active = 1
                Tracker:FindObjectForCode("kk").Active = 1
                Tracker:FindObjectForCode("cl").Active = 1
                Tracker:FindObjectForCode("lg").Active = 1
            end
        end
    
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	print(item_name, item_id)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
    end
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local v = ITEM_MAPPING[item_id]
    
    if v[1] == "progkey" and not Tracker:FindObjectForCode("basementkey").Active then
        Tracker:FindObjectForCode("basementkey").Active = true
        return
    elseif v[1] == "progkey" and Tracker:FindObjectForCode("basementkey").Active then
        Tracker:FindObjectForCode("topfloorkey").Active = true
        return
    end

    if not v then
        if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: could not find item mapping for id %s", item_id))
        end
        return
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: code: %s, type %s", v[1], v[2]))
    end
    if not v[1] then
        return
    end
    local obj = Tracker:FindObjectForCode(v[1])
    if obj then
        if v[2] == "toggle" then
            obj.Active = true
        elseif v[2] == "progressive" then
            if obj.Active then
                obj.CurrentStage = obj.CurrentStage + 1
            else
                obj.Active = true
            end
        elseif v[2] == "consumable" then
            obj.AcquiredCount = obj.AcquiredCount + obj.Increment
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onItem: unknown item type %s for code %s", v[2], v[1]))
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("onItem: could not find object for code %s", v[1]))
    end

    -- track local items via snes interface
    if is_local then
        if LOCAL_ITEMS[v[1]] then
            LOCAL_ITEMS[v[1]] = LOCAL_ITEMS[v[1]] + 1
        else
            LOCAL_ITEMS[v[1]] = 1
        end
    else
        if GLOBAL_ITEMS[v[1]] then
            GLOBAL_ITEMS[v[1]] = GLOBAL_ITEMS[v[1]] + 1
        else
            GLOBAL_ITEMS[v[1]] = 1
        end
    end
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
        print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
    end
    if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
        -- add snes interface functions here for local item tracking
    end
end

--called when a location gets cleared
function onLocation(location_id, location_name)
	print(location_name, location_id)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onLocation: %s, %s", location_id, location_name))
    end
    local v = LOCATION_MAPPING[location_id]
    if not v then
        print(string.format("onLocation: could not find location mapping for id %s", location_id))
        return
    end
    if not v[1] then
        return
    end
    for _, location in pairs(location_array) do
        local obj = Tracker:FindObjectForCode(location)
        -- print(location, obj)
        if obj then

            if location:sub(1, 1) == "@" then
                obj.AvailableChestCount = obj.AvailableChestCount - 1
            else
                obj.Active = true
            end
        else
            print(string.format("onLocation: could not find object for code %s", location))
        end
    end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
            item_player))
    end
    -- not implemented yet :(
end

-- called when a bounce message is received 
function onBounce(json)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("called onBounce: %s", dump_table(json)))
    end
    -- your code goes here
end

-- auto-map tab

function onNotify(key, value, old_value)
	if value ~= old_value then
		if key == TAB_ID then
		  updateTabs(value)
        end
        if key == EVENT_ID then
            updateEvents(value)
		end
	end
end

function onNotifyLaunch(key, value)
    if key == TAB_ID then
        updateTabs(value)
      end
      if key == EVENT_ID then
          updateEvents(value)
      end
    end

local lastRoomID = nil

function updateTabs(value)
    if value ~= nil then
        print(string.format("updateTabs %x", value))
        local tabswitch = Tracker:FindObjectForCode("tab_switch")
        Tracker:FindObjectForCode("cur_level_id").CurrentStage = value
        if tabswitch.Active then
            if value ~= lastRoomID then
                if TAB_MAPPING[value] then
                    local roomTabs = {}
                    for str in string.gmatch(TAB_MAPPING[value], "([^/]+)") do
                        table.insert(roomTabs, str)
                    end
                    if #roomTabs > 0 then
                        for _, tab in ipairs(roomTabs) do
                            print(string.format("Updating ID %x to Tab %s", value, tab))
                            Tracker:UiHint("ActivateTab", tab)
                        end
                        lastRoomID = value
                    else
                        print(string.format("Failed to find tabs for ID %x", value))
                    end
                else
                    print(string.format("Failed to find Tab ID %x", value))
                end
            else
            end
        end
    end
end

function updateEvents(value)
    if value ~= nil then
      for _, event in pairs(EVENT_FLAG_MAPPING) do
        for _, code in pairs(event.codes) do
          if code.setting == nil or has(code.setting) then
            if code.code == "harbor_mail" then
              Tracker:FindObjectForCode(code.code).Active = Tracker:FindObjectForCode(code.code).Active or value & event.bitmask ~= 0
            else
              Tracker:FindObjectForCode(code.code).Active = value & event.bitmask ~= 0
            end
          end
        end
      end
    end
  end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
Archipelago:AddItemHandler("item handler", onItem)
Archipelago:AddLocationHandler("location handler", onLocation)
Archipelago:AddSetReplyHandler("notify handler", onNotify)
Archipelago:AddRetrievedHandler("notify launch handler", onNotifyLaunch)
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)
