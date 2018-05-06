function kaboom(pos, radius)
		tnt.boom(pos, {radius = radius, damage_radius = radius})
end
-- Shell entity
local shell_ent = {
	physical = true,
	timer = 10,
	visual = "cube",
	visual_size = {x=0.2, y=0.2,},
	textures = {'default_stone.png', 'default_stone.png', 'default_stone.png', 'default_stone.png', 'default_stone.png', 'default_stone.png'},
	collisionbox = {1, 1, 1, 1, 1, 1},
}

--Registering the entity
minetest.register_entity("artillery:shellent", shell_ent)

--This is where the cool stuff starts
function fire_bomb(name, radius, pos, distance, direction)

  	local dir = minetest.facedir_to_dir(direction)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+1, z=pos.z+dir.z}, name) --Spawn bomb

	obj:set_velocity({x=dir.x*(distance/2), y=20, z=dir.z*(distance/2)}) --Starting velocity
	obj:setacceleration({x=dir.x*(distance/2), y=-25, z=dir.z*(distance/2)}) --Acceleration after the bomb starts moving

	shell_ent.on_step = function(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:getpos()

	if self.timer > 0.12 then
		local objs = minetest.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 1)
		for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= "artillery:shellent" and obj:get_luaentity().name ~= "__builtin:item" then
					kaboom(obj:get_pos(), radius)
					self.object:remove()
				end
			else
				kaboom(obj:get_pos(), radius)
				self.object:remove()
			end

--Prevent bomb from exploding when inside air and removing it when it hits water
			local node = minetest.get_node(obj:get_pos())
			if minetest.get_node(obj:get_pos()) then
				if node.name == "default:water_source" or node.name == "default:water_flowing" then
					self.object:remove()
						elseif node.name == "air" then
							return
						else
							kaboom(obj:get_pos(), radius)
							self.object:remove()
							end
		end
	end
end
end
end

minetest.register_craftitem("artillery:shell", { --kind of like a turtle shell with high explosive and phosphorus
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
    	if fields.save and fields.distance ~= "" and fields.height ~= "" and fields.direction ~= "" then
    		--Prevent user from putting in disallowed characters or values

			local function limity(input, limit)
    	    	local inputy = tonumber(input)
    	    	if inputy == nil then
    	    		return(0)
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
	local node = minetest.get_node(pos)
		local inv = puncher:get_inventory()
		local itemstack = puncher:get_wielded_item()
		local meta = minetest.get_meta(pos)
		if meta:get_int("cooldown") == 0 then
			if itemstack:get_name() ~= "artillery:shell" then
				return itemstack
			end
			if not minetest.setting_getbool("creative_mode") then --Won't lose the Explosive Shell if you are in creative mode
				inv:remove_item("main", "artillery:shell")
			end
			fire_bomb("artillery:shellent", 5, pos, meta:get_int("distance"), node.param2)
			meta:set_int("cooldown", 1)
			meta:set_string("infotext", "Mortar Launcher is cooling down")
			minetest.after(2.5, function()
				meta:set_int("cooldown", 0)
				meta:set_string("infotext", "")
			end)
		end
	end,
})
