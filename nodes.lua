---
--- Functions
---

-- Slabs and stairs

local function rotate_and_place(itemstack, placer, pointed_thing)
    local p0 = pointed_thing.under
    local p1 = pointed_thing.above
    local param2 = 0

    local placer_pos = placer:get_pos()
    if placer_pos then
        param2 = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
    end

    local finepos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
    local fpos = finepos.y % 1

    if p0.y - 1 == p1.y or (fpos > 0 and fpos < 0.5)
            or (fpos < -0.5 and fpos > -0.999999999) then
        param2 = param2 + 20
        if param2 == 21 then
            param2 = 23
        elseif param2 == 23 then
            param2 = 21
        end
    end
    return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

local function register_stair_and_slab(node_name)
    local node_def = minetest.registered_nodes[node_name]

    local stair_def = table.copy(node_def)
    -- Add stair specific stuff
    stair_def.groups.stair = 1
    stair_def.description = stair_def.description.." Stair"
    stair_def.drawtype = "mesh"
    stair_def.mesh = "stairs_stair.obj"
    stair_def.selection_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
            {-0.5, 0, 0, 0.5, 0.5, 0.5},
        },
    }
    stair_def.collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
            {-0.5, 0, 0, 0.5, 0.5, 0.5},
        },
    }
    stair_def.on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return node_def.on_place(itemstack, placer, pointed_thing)
        end

        return rotate_and_place(itemstack, placer, pointed_thing)
    end

    minetest.register_node(node_name.."_stair", stair_def)

    local slab_def = table.copy(node_def)
    slab_def.groups.slab = 1
    slab_def.drawtype = "nodebox"
    paramtype2 = "facedir"
    slab_def.node_box = {
                type = "fixed",
                fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
            }
    slab_def.on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return node_def.on_place(itemstack, placer, pointed_thing)
        end

        return rotate_and_place(itemstack, placer, pointed_thing)
    end
    minetest.register_node(node_name.."_slab", slab_def)
end

local function register_cracked(number)
    minetest.register_node("artillery:concrete_cracked_"..number, {
        description = "Cracked Concrete",
        paramtype2 = "facedir",
        tiles = {"concrete.png^crack_"..number..".png"},
        groups = {cracky = 2, level = 2, not_in_creative_inventory = 1},
        drop = "default:gravel 2",
    })
    register_stair_and_slab("artillery:concrete_cracked_"..number)
end

--
-- Concrete | It's as tough as a mixture of sand, gravel, and water!
--

register_cracked(1)
register_cracked(2)
register_cracked(3)

minetest.register_node("artillery:concrete", {
    description = "Concrete",
    tiles = {"concrete.png"},
    paramtype2 = "facedir",
    groups = {cracky = 1, level = 2},
    on_blast = function(pos, intensity)
        local meta = minetest.get_meta(pos)
        local current_node = minetest.get_node(pos).name
        local suffix = (current_node:split("_")[2] and "_"..current_node:split("_")[2] or "")
        if meta:get_int("blast") == 0 then
            meta:set_int("blast", 1)
            return false
        elseif meta:get_int("blast") == 1 then
            meta:set_int("blast", 2)
            return false
        elseif meta:get_int("blast") == 2 then
            minetest.set_node(pos, {name = "artillery:concrete_cracked_"..math.random(1,3)..suffix})
        end
    end,
})

register_stair_and_slab("artillery:concrete")

--
-- SandBags | Bags with sand in them
--

minetest.register_node("artillery:sandbag", {
	description = "Sandbag",
	tiles = {
        "sandbag_top.png",
        "sandbag_bottom.png",
        "sandbag_right.png",
        "sandbag_left.png",
        "sandbag_back.png",
        "sandbag_front.png"
    },
    paramtype2 = "facedir",
    groups = {crumbly = 3},
    on_blast = function(pos, intensity)
		minetest.set_node(pos, {name = "air"})
		minetest.add_item(pos, "default:sand")
	end,
})

register_stair_and_slab("artillery:sandbag")

--
-- Special
--

-- 4 = 180.11
local function register_placer(name, ex, wy, zee)
    local function spawncoolthing(pos, name, dir)
        local rotate = 0
        if dir > 2.3 and dir <= 3.95 then
            rotate = 270
            elseif dir > 3.95 and dir <= 5.45 then
              rotate = 180
            elseif dir > 5.45 and dir <= 6 then
             rotate = 90
        end
        if dir <= 0.80 and dir >= 0 then
            rotate = 90
        end
        
        local path = minetest.get_modpath("artillery") .. "/schematics/"..name..".mts"
        minetest.place_schematic({x=pos.x+ex, y=pos.y+wy, z = pos.z+zee}, path, rotate, nil, true)
    end

    minetest.register_craftitem("artillery:"..name, {
        description = "Rightclick to place: "..name,
        inventory_image = name..".png",
        on_place = function(itemstack, placer, pointed_thing)
            spawncoolthing(pointed_thing.above, name, placer:get_look_horizontal())
        end,
        groups = {force_floor = 1}
    }) 
end

register_placer("bunker_small", 0, -6, 0)
register_placer("small_fort", 0, -1, 0)

--
-- Barbed Wire | Don't touch the pointy things. They hurt
--

minetest.register_node("artillery:barbedwire", {
    description = "Barbed Wire",
    drawtype = "firelike",
    visual_scale = 1.2,
    tiles = {"barbedwire.png"},
    paramtype = "light",
    walkable = false,
    damage_per_second = 3.5,
    groups = {snappy = 1, attached_node = 1},
    on_blast = function(pos, intensity)
        return false
    end
})

--
-- Lights | Things that scare away the darkness
--

local function register_torch_extras(node_name)
    local node_def = minetest.registered_nodes[node_name]

    local wall_def = table.copy(node_def)

    wall_def.drawtype = "mesh"
    wall_def.mesh = string.lower(node_def.description).."_wall.obj"
    wall_def.tiles = {string.lower(node_def.description).."_floor_obj.png"}
    wall_def.paramtype = "light"
    wall_def.paramtype2 = "wallmounted"
    wall_def.sunlight_propagates = true
    wall_def.walkable = false
    wall_def.light_source = 12
    wall_def.groups = {snappy=2, not_in_creative_inventory=1, attached_node=1}
    wall_def.drop = node_name
    wall_def.selection_box = {
        type = "wallmounted",
        wall_side = {-1/2, -1/2, -1/8, -2/8, 3/16, 1/8},
    }

    minetest.register_node(node_name.."_wall", wall_def)

    local ceiling_def = table.copy(node_def)

    ceiling_def.drawtype = "mesh"
    ceiling_def.mesh = string.lower(node_def.description).."_ceiling.obj"
    ceiling_def.tiles = {string.lower(node_def.description).."_floor_obj.png"}
    ceiling_def.paramtype = "light"
    ceiling_def.paramtype2 = "wallmounted"
    ceiling_def.sunlight_propagates = true
    ceiling_def.walkable = false
    ceiling_def.light_source = 12
    ceiling_def.groups = {snappy = 2, not_in_creative_inventory=1, attached_node=1}
    ceiling_def.drop = node_name
    ceiling_def.selection_box = {
        type = "wallmounted",
        wall_top = {-1/8, -1/7, -1/8, 1/8, 0.5, 1/8},
    }

    minetest.register_node(node_name.."_ceiling", ceiling_def)
end

minetest.register_node("artillery:lamp", {
    description = "Lamp",
    drawtype = "mesh",
    mesh = "lamp_floor.obj",
    inventory_image = "lamp.png",
    wield_image = "lamp.png",
    tiles = {"lamp_floor_obj.png"},
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    liquids_pointable = false,
    light_source = 12,
    groups = {snappy=2, attached_node=1},
    drop = "artillery:lamp",
    selection_box = {
        type = "wallmounted",
        wall_bottom = {-1/8, -1/2, -1/8, 1/8, 4/16, 1/8},
    },
    on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_rightclick and
            ((not placer) or (placer and not placer:get_player_control().sneak)) then
            return def.on_rightclick(under, node, placer, itemstack,
                pointed_thing) or itemstack
        end

        local above = pointed_thing.above
        local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
        local fakestack = itemstack
        if wdir == 0 then
            fakestack:set_name("artillery:lamp_ceiling")
        elseif wdir == 1 then
            fakestack:set_name("artillery:lamp")
        else
            fakestack:set_name("artillery:lamp_wall")
        end

        itemstack = minetest.item_place(fakestack, placer, pointed_thing, wdir)
        itemstack:set_name("artillery:lamp")

        return itemstack
    end
})

register_torch_extras("artillery:lamp")