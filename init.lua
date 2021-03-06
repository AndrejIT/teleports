teleports = {}
teleports.teleports = {}
teleports.lastplayername =""
teleports.filename = minetest.get_worldpath() .. "/teleports.txt"

function teleports:save()
    local datastring = minetest.serialize(self.teleports)
    if not datastring then
        return
    end
    local file, err = io.open(self.filename, "w")
    if err then
        return
    end
    file:write(datastring)
    file:close()
end
function teleports:load()
    local file, err = io.open(self.filename, "r")
    if err then
        self.teleports = {}
        return
    end
    self.teleports = minetest.deserialize(file:read("*all"))
    if type(self.teleports) ~= "table" then
        self.teleports = {}
    end
    file:close()
end
function teleports:find_nearby(pos, count)
    local nearby = {}
    for i = #teleports.teleports, 1, -1 do
        local EachTeleport = teleports.teleports[i]
        if not vector.equals(EachTeleport.pos, pos) and vector.distance(EachTeleport.pos, pos) < 260 then
            table.insert(nearby, EachTeleport)
            if #nearby>count then
                break
            end
        end
    end
    return nearby
end
function teleports.animate(pos, playername)
    minetest.add_particlespawner({
    	amount = 80,
    	time = 5,
    	minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
    	maxpos = {x=pos.x+1, y=pos.y+3, z=pos.z+1},
    	minvel = {x=0, y=-1, z=0},
    	maxvel = {x=0, y=1, z=0},
    	minacc = {x=0, y=-1, z=0},
    	maxacc = {x=0, y=1, z=0},
    	minexptime = 1,
    	maxexptime = 1,
    	minsize = 0.5,
    	maxsize = 2,
    	collisiondetection = false,
    	vertical = true,
    	texture = "default_diamond.png",
    	playername = playername,
    })
    minetest.add_particlespawner({
    	amount = 20,
    	time = 5,
    	minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
    	maxpos = {x=pos.x+1, y=pos.y+3, z=pos.z+1},
    	minvel = {x=0, y=-1, z=0},
    	maxvel = {x=0, y=1, z=0},
    	minacc = {x=0, y=-1, z=0},
    	maxacc = {x=0, y=1, z=0},
    	minexptime = 1,
    	maxexptime = 1,
    	minsize = 0.5,
    	maxsize = 2,
    	collisiondetection = false,
    	vertical = true,
    	texture = "default_diamond.png",
    })
end
function teleports.teleportate(parameters)
    local pos1,pos2,playername = parameters[1],parameters[2],parameters[3]

    local player = minetest.get_player_by_name(playername)
    if player and player:is_player() and playername~=teleports.lastplayername then
        local pos = player:getpos()
        if vector.distance(pos, {x=pos1.x,y=pos1.y+0.5,z=pos1.z}) < 0.52 then
            if math.random(1, 100) > 5 then
                teleports.lastplayername = playername
                player:setpos({x=pos2.x,y=pos2.y+0.5,z=pos2.z})
            else
                player:setpos({x=pos2.x-5+math.random(1, 10),y=pos2.y+3,z=pos2.z-5+math.random(1, 10)})
            end
        end
    end
end
function teleports.do_teleporting(pos1, pos2, playername)
    teleports.animate(pos1, playername)
    minetest.after(3.0, teleports.teleportate, {pos1, pos2, playername})
end
teleports.set_formspec = function(pos)
	local meta = minetest.get_meta(pos)
	local node = minetest.get_node(pos)

    local buttons = "";
    for i, EachTeleport in ipairs( teleports:find_nearby(pos, 5) ) do
        if EachTeleport["name"] then
            buttons = buttons.."button_exit[3,"..(i)..";4,0.5;tp"..i..";GO>"..minetest.formspec_escape(EachTeleport.name).."]";
        else
            buttons = buttons.."button_exit[3,"..(i)..";4,0.5;tp"..i..";GO>"..EachTeleport.pos.x..","..EachTeleport.pos.y..","..EachTeleport.pos.z.."]";
        end

    end

	meta:set_string("formspec", "size[8,10;]"
		.."label[0,0;" .. 'Go to available teleports! Use mossy cobble as fuel!' .. "]"
        .."list[current_name;price;0,1;1,1;]"

        ..buttons

		.."button_exit[1,5;2,0.5;cancel;Cancel]"
        .."list[current_player;main;0,6;8,4;]")
end
teleports.on_receive_fields = function(pos, formname, fields, player)
    local meta = minetest.env:get_meta(pos);
	local inv = meta:get_inventory();
    local price = {name="default:mossycobble", count=1, wear=0, metadata=""}
    if fields.tp1 or fields.tp2 or fields.tp3 or fields.tp4 or fields.tp5 or fields.tp6 then
        if inv:contains_item("price", price) then
            inv:remove_item("price", price);
            teleports.lastplayername = ""
            local available = teleports:find_nearby(pos, 5)
            if player ~= nil and player:is_player() then
                local playerpos = player:getpos()
                if fields.tp1 and #available>0 then
                    teleports.do_teleporting(playerpos, available[1].pos, player:get_player_name())
                elseif fields.tp2 and #available>1 then
                    teleports.do_teleporting(playerpos, available[2].pos, player:get_player_name())
                elseif fields.tp3 and #available>2 then
                    teleports.do_teleporting(playerpos, available[3].pos, player:get_player_name())
                elseif fields.tp4 and #available>3 then
                    teleports.do_teleporting(playerpos, available[4].pos, player:get_player_name())
                elseif fields.tp5 and #available>4 then
                    teleports.do_teleporting(playerpos, available[5].pos, player:get_player_name())
                elseif fields.tp6 and #available>5 then
                    teleports.do_teleporting(playerpos, available[6].pos, player:get_player_name())
                end
            end

            teleports.set_formspec(pos)
        end
    end
end
teleports.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
    if listname=="price" and stack:get_name()=="default:mossycobble" then
        return 99
    else
        return 0
    end
end
teleports.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
	return 0
end

teleports:load()


minetest.register_node("teleports:teleport", {
	description = "Teleport",
	drawtype = "glasslike",
	tiles = {"teleports_teleport_top.png"},
	is_ground_content = false,
	light_source = LIGHT_MAX,
	groups = {cracky=1, level=3},
	drop = 'default:diamond',
	sounds = default.node_sound_stone_defaults(),
    after_place_node = function(pos, placer)
        if placer and placer:is_player() then
            local meta = minetest.env:get_meta(pos)
            local inv = meta:get_inventory()
            inv:set_size("price", 1)
            local initialcharge = {name="default:mossycobble", count=30, wear=0, metadata=""}
            inv:add_item("price", initialcharge)
            teleports.set_formspec(pos)
            local sign_pos = minetest.find_node_near(pos, 1, "default:sign_wall_wood")
            if sign_pos then
                local sign_meta = minetest.env:get_meta(sign_pos)
                local sign_text = sign_meta:get_string("text")
                local secret_name = sign_text:sub(0, 16)
                table.insert(teleports.teleports, {pos=vector.round(pos), name=secret_name})
            else
                table.insert(teleports.teleports, {pos=vector.round(pos)})
            end
            teleports:save()
        end
    end,
    on_destruct = function(pos)
        for i, EachTeleport in ipairs(teleports.teleports) do
            if vector.equals(EachTeleport.pos, pos) then
                table.remove(teleports.teleports, i)
                teleports:save()
            end
        end
    end,
    on_receive_fields = teleports.on_receive_fields,
    allow_metadata_inventory_put = teleports.allow_metadata_inventory_put,
    allow_metadata_inventory_take = teleports.allow_metadata_inventory_take,
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
	interval = 3,
	chance = 1,
	action = function(pos)
		local objectsnear=minetest.get_objects_inside_radius({x=pos.x,y=pos.y+0.5,z=pos.z}, 0.52);
		if #objectsnear>0 then
			local player = objectsnear[1];
            -- check only first two objekts then give up
            if #objectsnear>1 and not player:is_player() then
                player = objectsnear[2];
            end
			if player:is_player() and player:get_player_name()~=teleports.lastplayername then
				local positions = teleports:find_nearby(pos, 10)
				if #positions>0 then
					local key = math.random(1, #positions)
                    local dir, dirmag;
                    local view = player:get_look_dir();
                    local dist, distmin; distmin = 99;
                    for i=1,#positions do -- find teleport closest to where player is looking
                    	dir = {x=positions[i].pos.x-pos.x,y=positions[i].pos.y-pos.y,z=positions[i].pos.z-pos.z};
                    	dirmag = math.sqrt(dir.x*dir.x+dir.y*dir.y+dir.z*dir.z); if dirmag == 0 then dirmag = 1 end
                    	dir.x=dir.x/dirmag;dir.y=dir.y/dirmag;dir.z=dir.z/dirmag;
                    	dir.x = view.x-dir.x;dir.y = view.y-dir.y;dir.z = view.z-dir.z;
                    	dist = math.sqrt(dir.x*dir.x+dir.y*dir.y+dir.z*dir.z);
                    	if dist<distmin then distmin = dist; key = i end
                    end

                    local pos2 = positions[key].pos
                    teleports.do_teleporting(pos, pos2, player:get_player_name())
                end
            else
                teleports.lastplayername = ""
			end
		end
	end,
})
