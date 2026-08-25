local default_is_protected = minetest.is_protected

minetest.is_protected = function(pos, player)

    -- Explosions call minetest.is_protected() with an empty player name.
    -- Allow explosions to destroy normal player faction claims,
    -- but keep Safezones and Warzones protected.
    if player == "" then
        local parcelpos = factions.get_parcel_pos(pos)
        local parcel = factions.parcels.get(parcelpos)

        -- Nothing claimed: use normal protection.
        if not parcel then
            return default_is_protected(pos, player)
        end

        -- Safezones remain completely protected from explosions.
        if parcel.safezone then
            return true
        end

        -- Warzones remain completely protected from explosions.
        if parcel.warzone then
            return true
        end

        -- Normal player faction claim:
        -- allow the explosion to destroy the block.
        return false
    end

    if minetest.check_player_privs(player, "protection_bypass") then
        return default_is_protected(pos, player)
    end

    local y = pos.y

    if factions_config.protection_depth_height_limit
        and (pos.y < factions_config.protection_max_depth
        or pos.y > factions_config.protection_max_height) then
        return default_is_protected(pos, player)
    end

    local parcelpos = factions.get_parcel_pos(pos)
    local parcel_faction, parcel_fac_name = factions.get_parcel_faction(parcelpos)

    local player_faction
    local player_fac_name

    if player then
        player_faction, player_fac_name = factions.get_player_faction(player)
    end

    -- No faction claim.
    if not parcel_faction then
        return default_is_protected(pos, player)

    elseif player_faction then

        if parcel_faction.name == player_faction.name then

            if factions.has_permission(parcel_fac_name, player, "pain_build") then
                local p = minetest.get_player_by_name(player)
                p:set_hp(p:get_hp() - 0.5)
            end

            return not (
                factions.has_permission(parcel_fac_name, player, "build")
                or factions.has_permission(parcel_fac_name, player, "pain_build")
            )

        elseif parcel_faction.allies[player_faction.name] then

            if factions.has_permission(player_fac_name, player, "pain_build") then
                local p = minetest.get_player_by_name(player)
                p:set_hp(p:get_hp() - 0.5)
            end

            return not (
                factions.has_permission(player_fac_name, player, "build")
                or factions.has_permission(player_fac_name, player, "pain_build")
            )

        else
            return true
        end

    else
        return true
    end

    return default_is_protected(pos, player)
end
-- Prevent non-members from opening doors on normal faction claims.
-- Safezones and warzones are left alone.

minetest.register_on_mods_loaded(function()

    for nodename, def in pairs(minetest.registered_nodes) do

        if def.groups and def.groups.door and def.on_rightclick then

            local old_rightclick = def.on_rightclick

            minetest.override_item(nodename, {
                on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)

                    if clicker and clicker:is_player() then
                        local player_name = clicker:get_player_name()

                        local parcelpos = factions.get_parcel_pos(pos)
                        local parcel = factions.parcels.get(parcelpos)

                        -- Only restrict normal faction claims.
                        -- Safezones and warzones are completely ignored.
                        if parcel
                        and parcel.faction
                        and not parcel.safezone
                        and not parcel.warzone then

                            local player_faction = factions.get_player_faction(player_name)

                            -- Player isn't in a faction.
                            if not player_faction then
                                minetest.record_protection_violation(pos, player_name)
                                return itemstack
                            end

                            -- Player belongs to a different faction.
                            if player_faction.name ~= parcel.faction then
                                minetest.record_protection_violation(pos, player_name)
                                return itemstack
                            end
                        end
                    end

                    -- Allow the original Mineclonia door behavior.
                    return old_rightclick(pos, node, clicker, itemstack, pointed_thing)
                end
            })
        end
    end
end)
