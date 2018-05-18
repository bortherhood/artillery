local function check(obj, pos)
	local node = minetest.get_node(pos)
	if node.name ~= "air" and node.name ~= "artillery:barbed_wire" then
		if node.name == "artillery:concrete" then
			obj.object:remove()
			tnt.boom(pos, {radius = 2, damage_radius = 2})
			elseif node.name == "artillery:concrete_cracked_1" or 
				node.name == "artillery:concrete_cracked_2" or 
				node.name == "artillery:concrete_cracked_3" then
				obj.object:remove()
				tnt.boom(pos, {radius = 2, damage_radius = 3})
			else
				obj.object:remove()
				tnt.boom(pos, {radius = 3, damage_radius = 5})
		end
	end
end

local time_since_spawned = 0

local bomb_entity = {
	physical = true,
	timer = 0,
	visual = "cube",
	visual_size = {x=0.2, y=0.2,},
	textures = {'default_stone.png', 'default_stone.png', 'default_stone.png', 'default_stone.png', 'default_stone.png', 'default_stone.png'},
	collisionbox = {4, 4, 4, 4, 4, 4},
	on_step = function(self, dtime)
		local pos = self.object:getpos()
		check(self, pos)
	end
}

local grenade_entity = {
	physical = true,
	timer = 0,
	visual = "mesh",
	mesh = "gwenade.obj",
	visual_size = {x=1.5, y=1.5, z=1.5},
	textures = {'default_stone.png'},
	collisionbox = {10, 10, 10, 10, 10, 10},
	on_step = function(self, dtime)
		local pos = self.object:getpos()
		local node = minetest.get_node(pos)
		time_since_spawned = time_since_spawned + dtime

		if time_since_spawned > 4.5 or node.name ~= "air" then
			time_since_spawned = 0
			tnt.boom({x=pos.x, y=pos.y+1.2, z=pos.z}, {radius = 1, damage_radius = 6})
			self.object:remove()
		end
	end
}

minetest.register_entity("artillery:bomb", bomb_entity)
minetest.register_entity("artillery:grenadey", grenade_entity)

function fire_bomb(name, radius, pos, distance, direction)
	local dir = minetest.facedir_to_dir(direction)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+1, z=pos.z+dir.z}, name) --Adds bomb one node above starting node

	obj:set_velocity({x=dir.x*(distance/2), y=20, z=dir.z*(distance/2)}) --Starting velocity
	obj:setacceleration({x=dir.x*(distance/2), y=-30, z=dir.z*(distance/2)}) --Acceleration after the bomb starts moving. Negative numbers slow it down
end

function throw_grenade(name, pos, direction)
	local dir = direction
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+1.3, z=pos.z+dir.z}, name)

	obj:set_velocity({x=dir.x*5, y=5, z=dir.z*5}) --Starting velocity
	obj:setacceleration({x=dir.x, y=-10, z=dir.z}) --Acceleration after the bomb starts moving
end

minetest.register_craftitem("artillery:shell", {
	description = "Explosive Shell",
	image = "shell.png",
})

minetest.register_node("artillery:mortar", {
	description = "Mortar launcher",
	drawtype = "mesh",
	tiles = {"default_stone.png"},
	groups = {oddly_breakable_by_hand = 3, attached_node = 1, force_floor = 1},
	mesh = "mortar.obj",
	paramtype2 = "facedir",
	force_floor,
	selection_box = {
		type = "fixed",
		fixed = {0.6, -0.3, 0.6, -0.6, -0.5, -0.6},
		},
	collision_box = {
		type = "fixed",
		fixed = {0.6, -0.3, 0.6, -0.6, -0.5, -0.6},
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
			meta:set_int("distance", 15)
			meta:set_int("cooldown", 0)
			meta:set_string("formspec",
				"size[3,2.2]" ..
				"bgcolor[#080808BB;true]" ..
				"background[5,5;1,1;gui_formbg.png;true]" ..
				"label[0,-0.3;Mortar Configuration]" ..
				"field[0.5,1;2.5,1;distance; Power(distance);"..meta:get_int("distance").."]" ..
				"button_exit[0,1.5;3,1;save;Save Configuration]")
	end,

	on_receive_fields = function(pos, formname, fields, player)
	local meta = minetest.get_meta(pos)
		if fields.save and fields.distance ~= "" then
			--Prevent user from putting in disallowed characters or values
			local function limity(input, limit)
				local inputy = tonumber(input)
				if inputy == nil then
					return(5)
				end
				if inputy > limit then
					return(limit)
					elseif inputy < 5 then
						return(5)
					else
						return(inputy)
				end
			end

			meta:set_int("distance", limity(fields.distance, 40))
			meta:set_string("formspec",
				"size[3,2.2]" ..
				"bgcolor[#080808BB;true]" ..
				"background[5,5;1,1;gui_formbg.png;true]" ..
				"label[0,-0.3;Mortar Configuration]" ..
				"field[0.5,1;2.5,1;distance; Power(distance);"..meta:get_int("distance").."]" ..
				"button_exit[0,1.5;3,1;save;Save Configuration]")
		end
	end,

	on_punch = function(pos, node, puncher, pointed_thing)
		local nodey = minetest.get_node(pos)
		local inv = puncher:get_inventory()
		local itemstack = puncher:get_wielded_item()
		local meta = minetest.get_meta(pos)
		if meta:get_int("cooldown") == 0 then
			if itemstack:get_name() ~= "artillery:shell" then
				return itemstack
			end
			if not minetest.setting_getbool("creative_mode") then
				inv:remove_item("main", "artillery:shell")
			end
			fire_bomb("artillery:bomb", 5, pos, meta:get_int("distance"), nodey.param2)
			meta:set_int("cooldown", 1)
			meta:set_string("infotext", "Mortar Launcher is cooling down")
			minetest.after(2.5, function()
				meta:set_int("cooldown", 0)
				meta:set_string("infotext", "")
			end)
		end
	end,
})


--Grenade

minetest.register_node("artillery:grenade", {
	drawtype = "mesh",
	mesh = "gwenade.obj",
	description = "Grenade (Right-Click to pull pin, Left-Click to throw",
	tiles = "default_stone.png^default_diamond.png",--"grenade.png",
	stack_max = 1,
	range = 0,
	on_secondary_use = function(itemstack, user, pointed_thing)
		local player = user:get_player_name()
		local meta = itemstack:get_meta()
		local inv = user:get_inventory()

		if player ~= nil and meta:get_int("active") == 0 then
			meta:set_int("active", 1)
			minetest.after(5, function()
				if inv:contains_item("main", "artillery:grenade") then
					tnt.boom(user:get_pos(), {radius = 1, damage_radius = 4})
					if not minetest.setting_getbool("creative_mode") then
						inv:remove_item("main", "artillery:grenade")
					end
				end
			end)
			return itemstack
		end
	end,
	on_use = function(itemstack, placer, pointed_thing)
		local player = placer:get_player_name()
		local meta = itemstack:get_meta()
		local inv = placer:get_inventory()

		if player ~= nil and meta:get_int("active") == 1 then
			throw_grenade("artillery:grenadey", placer:get_pos(), placer:get_look_dir())
			if not minetest.setting_getbool("creative_mode") then
				inv:remove_item("main", "artillery:grenade")
			end
		end
	end,
})

minetest.register_craft({
	output = "artillery:grenade",
	recipe = {
	{"", "default:steel_ingot", ""},
	{"default:steel_ingot", "tnt:tnt", "default:steel_ingot"},
	{"", "default:steel_ingot", ""}
	},
	})