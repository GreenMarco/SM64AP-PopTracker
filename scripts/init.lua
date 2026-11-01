ScriptHost:LoadScript("scripts/autotracking.lua")
ScriptHost:LoadScript("scripts/logic.lua")

Tracker:AddItems("items/1ups.json")
Tracker:AddItems("items/buddies.json")
Tracker:AddItems("items/cannons.json")
Tracker:AddItems("items/items.json")
-- Tracker:AddItems("items/keys.json")
Tracker:AddItems("items/moves.json")
Tracker:AddItems("items/painting.json")
Tracker:AddItems("items/settings.json")
Tracker:AddItems("items/stars.json")
Tracker:AddItems("items/switches.json")
Tracker:AddItems("items/entrances.json")
Tracker:AddItems("items/doors.json")



Tracker:AddLayouts("layouts/grids.json")

local variant = Tracker.ActiveVariantUID
if variant == "horizontal" then
    Tracker:AddLayouts("layouts/layout_horizontal.json")
    Tracker:AddLayouts("layouts/broadcast_layout_horizontal.json")
elseif variant == "vertical-complete" then
    Tracker:AddLayouts("layouts/layout_vertical_complete.json")
    Tracker:AddLayouts("layouts/broadcast_layout_vertical_complete.json")
elseif variant == "horizontal-complete" then
    Tracker:AddLayouts("layouts/layout_horizontal_complete.json")
    Tracker:AddLayouts("layouts/broadcast_layout_horizontal_complete.json")
elseif variant == "exp" then
    Tracker:AddLayouts("layouts/layout_exp.json")
    Tracker:AddLayouts("layouts/broadcast_layout_horizontal.json")
else -- "vertical"
    Tracker:AddLayouts("layouts/layout.json")
    Tracker:AddLayouts("layouts/broadcast_layout.json")
end



