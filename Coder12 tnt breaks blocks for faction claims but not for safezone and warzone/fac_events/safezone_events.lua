local function is_safezone(pos)
	if not pos then
		return false
	end

	local parcelpos = factions.get_parcel_pos(pos)
	return factions.is_safezone(parcelpos)
end

local function is_warzone(pos)
	if not pos then
		return false
	end

	local parcelpos = factions.get_parcel_pos(pos)
	return factions.is_warzone(parcelpos)
end

local function is_protected_zone(pos)
	return is_safezone(pos) or is_warzone(pos)
end


-- Disable fire and explosion damage in safezones and warzones.
-- PvP is disabled only in safezones.
minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if hp_change >= 0 then
		return hp_change
	end

	local pos = player:get_pos()

	local safezone = is_safezone(pos)
	local warzone = is_warzone(pos)

	if not safezone and not warzone then
		return hp_change
	end

	-- Safezones prevent ALL damage.
	if safezone then
		return 0
	end

	-- Warzones prevent fire and explosion damage.
	if reason and reason.type == "node_damage" then
		local node = reason.node

		if node and (
			node == "fire:basic_flame" or
			node == "fire:permanent_flame" or
			node == "mcl_fire:fire"
		) then
			return 0
		end
	end

	-- Explosion damage.
	if reason and reason.custom_type then
		if string.find(reason.custom_type, "explosion", 1, true) then
			return 0
		end
	end

	return hp_change
end, true)