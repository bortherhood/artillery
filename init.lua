dofile(minetest.get_modpath("artillery").."/nodes.lua")
dofile(minetest.get_modpath("artillery").."/turrets.lua")
dofile(minetest.get_modpath("artillery").."/guns.lua")
dofile(minetest.get_modpath("artillery").."/heavy.lua")

-- Log
if minetest.settings:get_bool("log_mods") then
	minetest.log("action", "[Artillery] Loaded.")
end