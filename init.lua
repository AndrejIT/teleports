teleports = {}

minetest.register_node("teleports:teleport", {
	description = "Teleport",
	drawtype = "glasslike",
	tiles = {"teleports_teleport_top.png"},
	is_ground_content = false,
	light_source = LIGHT_MAX,
	groups = {cracky=1, level=3},
	drop = 'default:diamond',
	sounds = default.node_sound_stone_defaults(),
})
--redefine diamond
minetest.register_node(":default:diamondblock", {
	description = "Diamond Block",
	tiles = {"default_diamond_block.png"},
	is_ground_content = true,
	groups = {cracky=1,level=3},
	sounds = default.node_sound_stone_defaults(),
	on_place = function(itemstack, placer, pointed_thing)
		local stack = ItemStack("default:diamondblock")
		local pos = pointed_thing.above
		if
			minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z+1}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z-1}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z+1}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z-1}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x,y=pos.y,z=pos.z+1}).name=="default:diamondblock" and
			minetest.get_node({x=pos.x,y=pos.y,z=pos.z-1}).name=="default:diamondblock"
		then
			stack = ItemStack("teleports:teleport")
		end
		local ret = minetest.item_place(stack, placer, pointed_thing)
		if ret==nil then
			return itemstack
		else
			return ItemStack("default:diamondblock "..itemstack:get_count()-(1-ret:get_count()))
		end
	end,
})

minetest.register_abm({
	nodenames = {"teleports:teleport"},
	interval = 10,
	chance = 1,
	action = function(pos)
		local objectsnear=minetest.get_objects_inside_radius({x=pos.x,y=pos.y+0.5,z=pos.z}, 0.52)
		local r=80
		if #objectsnear>0 then
			local player = objectsnear[1]
			if player:is_player() then
				local power = minetest.find_nodes_in_area(
					{x=pos.x-1, y=pos.y, z=pos.z-1},
					{x=pos.x+1, y=pos.y, z=pos.z+1},
					{"default:diamondblock"})
				r=r+#power*20	--diamond blocks around teleport increase its range
				local positions = minetest.find_nodes_in_area(
					{x=pos.x-r, y=pos.y-r, z=pos.z-r},
					{x=pos.x+r, y=pos.y+r, z=pos.z+r},
					{"teleports:teleport"})
				while #positions>1 do
					local key = math.random(1, #positions)
					local pos2 = positions[key]	--choose teleport randomly
					if  (pos.x == pos2.x and pos.y == pos2.y and pos.z == pos2.z) or	-- any better way to compare?
						minetest.get_node({x=pos2.x,y=pos2.y+1,z=pos2.z}).name~="air" or
						minetest.get_node({x=pos2.x,y=pos2.y+2,z=pos2.z}).name~="air"
					then
						table.remove(positions, key)
					else
						minetest.after(0.2, function()
							if player ~= nil and player:is_player() then --still is player, just in case
								player:setpos({x=pos2.x,y=pos2.y+0.5,z=pos2.z})
								minetest.log("info", "Player teleported from "..pos.x..","..pos.y..","..pos.z.." to "..pos2.x..","..pos2.y..","..pos2.z)
							end
						end)
						break
					end
				end
			end
		end
	end,
})

