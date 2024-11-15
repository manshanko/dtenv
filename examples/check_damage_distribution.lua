--[[
List all damage profiles targets where damage dealt to cleaved targets
incorrectly scales up instead of down.

We also check finesse scaling by comparing the damage increase from
finesse_modifier_bonus in cleaved targets.

Display format is:
    damage_profile
        target_index
            armor
                hit
]]--

local ArmorSettings = require("scripts/settings/damage/armor_settings")
local Breeds = require("scripts/settings/breed/breeds")
local DamageCalculation = require("scripts/utilities/attack/damage_calculation")
local DamageProfile = require("scripts/utilities/attack/damage_profile")
local DamageProfileTemplates = require("scripts/settings/damage/damage_profile_templates")
local PowerLevelSettings = require("scripts/settings/damage/power_level_settings")

local lerp_values = {
    current_target_settings_lerp_values = {}
}
local charge_level = 1.0
local hit_shield = nil
local is_backstab = nil
local is_flanking = nil
local dropoff_scalar = nil
local target_stat_buffs = {}
local target_buff_extension = nil
local armor_penetrating = nil
local target_health_extension = nil
local target_toughness_extension = nil
local target_unit = nil
local stagger_count = 0
local num_triggered_staggers = 0
local is_attacked_unit_suppressed = nil
local distance = 0
local auto_completed_action = nil
local stagger_impact = nil

local breed_or_nil = nil
local attacker_breed_or_nil = nil

local damage_type = "burning"
local power_level = PowerLevelSettings.default_power_level

local armor_types = ArmorSettings.types
local armors = {
    { "unarmored",              armor_types.unarmored },--Breeds.chaos_newly_infected },
    { "armored",                armor_types.armored },--Breeds.renegade_assault },
    { "super_armor",            armor_types.super_armor },--Breeds.chaos_ogryn_executor },
    { "resistant",              armor_types.resistant },--Breeds.chaos_spawn },
    { "berserker",              armor_types.berserker },--Breeds.cultist_berzerker },
    { "disgustingly_resilient", armor_types.disgustingly_resilient },--Breeds.chaos_poxwalker },
    --{ "player",                 Breeds.human },
}
local armor_order = {}
for i, v in pairs(armors) do
    armor_order[v[1]] = i
end

-- 800% finesse bonus (1.0 + 8.0)
local high_finesse = { finesse_modifier_bonus = 9.0 }
local no_stat_buffs = {}

local hit_order = {
    { crit = false, weak = false, name = "base" },
    { crit = false, weak = true,  name = "weak" },
    { crit = true,  weak = false, name = "crit" },
    { crit = true,  weak = true,  name = "weakcrit" },
}
local hit_order_name = {
    "base",
    "weak",
    "crit",
    "weakcrit",
    "CANARY",
    "weak (finesse)",
    "crit (finesse)",
    "weakcrit (finesse)",
}
local num_hit_order = #hit_order
local num_hit_order_name = #hit_order_name
local all_finesse    = {}
local all_no_finesse = {}

function calc_damage(
    damage_profile,
    target_settings,
    armor_type,
    is_critical_strike,
    hit_weakspot,
    attacker_stat_buffs
)
    local hit_zone = nil
    if hit_weakspot then
        hit_zone = "head"
    end
    local damage, efficiency = DamageCalculation.calculate(
        damage_profile,
        damage_type,
        target_settings,
        lerp_values,
        hit_zone,
        power_level,
        charge_level,
        Breeds.chaos_newly_infected,--{ armor_type = armor_type },--breed_or_nil,
        attacker_breed_or_nil,
        is_critical_strike,
        hit_weakspot,
        hit_shield,
        is_backstab,
        is_flanking,
        dropoff_scalar,
        attack_type,
        attacker_stat_buffs,
        target_stat_buffs,
        target_buff_extension,
        armor_penetrating,
        target_health_extension,
        target_toughness_extension,
        armor_type,
        stagger_count,
        num_triggered_staggers,
        is_attacked_unit_suppressed,
        distance,
        target_unit,
        auto_completed_action,
        stagger_impact
    )
    return damage
end

local check_damage_profiles = table.clone(DamageProfileTemplates)

-- skip these damage profiles since it looks intentional that they deal
-- increased damage to cleaved targets based on the source
check_damage_profiles.default_flamer_assault = nil
check_damage_profiles.default_warpfire_assault = nil

local errors = {}
for key, damage_profile in pairs(check_damage_profiles) do
    local num_targets = #damage_profile.targets + 1

    for _i, v in ipairs(armors) do
        local armor_key = v[1]
        local armor = v[2]

        local prev_hit = {
            nil,
            nil,
            nil,
            nil,
        }
        local prev_hit_diff = {
            nil,
            nil,
            nil,
            nil,
        }
        for target = 1, num_targets do
            local t = target
            if t > #damage_profile.targets then
                t = "(default)"
            end

            local target_settings = DamageProfile.target_settings(damage_profile, target)
            for i, hit in pairs(hit_order) do
                local prev = prev_hit[i]
                local damage = calc_damage(damage_profile, target_settings, armor, hit.crit, hit.weak, no_stat_buffs)
                if prev ~= nil and damage > prev then
                    errors[key] = errors[key] or {}
                    errors[key][t] = errors[key][t] or {}
                    errors[key][t][armor_key] = errors[key][t][armor_key] or {}
                    errors[key][t][armor_key][i] = true
                end
                prev_hit[i] = damage

                if hit.crit or hit.weak then
                    local damage_finesse = calc_damage(damage_profile, target_settings, armor, hit.crit, hit.weak, high_finesse)
                    local diff = damage_finesse - damage
                    if diff < 0.0 then
                        error("unexpected damage decrease with finesse")
                    end

                    local prev = prev_hit_diff[i]
                    if prev ~= nil and diff > prev then
                        errors[key] = errors[key] or {}
                        errors[key][t] = errors[key][t] or {}
                        errors[key][t][armor_key] = errors[key][t][armor_key] or {}
                        errors[key][t][armor_key][num_hit_order + i] = true
                    end
                    prev_hit_diff[i] = diff
                end
            end
        end
    end
end

local keys = table.keys(errors)
table.sort(keys)

if #keys == 0 then
    print("found no damage profiles with incorrect damage distribution")
    return
end

-- format results to print
for i, key in ipairs(keys) do
    if i == 1 then
        print("damage profiles with incorrect damage distribution:")
    end

    local dp_errors = errors[key]

    local dd_target = {}
    -- check for dedupe armors
    for target, armors in pairs(dp_errors) do
        for _armor, hits in pairs(armors) do
            dd_target[target] = dd_target[target] or {}
            for hit in pairs(hits) do
                dd_target[target][hit] = dd_target[target][hit] or 0
                dd_target[target][hit] = dd_target[target][hit] + 1
            end
        end
    end

    -- dedupe armors
    for target, hits in pairs(dd_target) do
        local all_armor = true
        for _k, hit in pairs(hits) do
            if hit < #armors then
                all_armor = false
            end
        end

        if all_armor then
            dp_errors[target] = {
                ["all armors"] = hits,
            }
        end
    end

    -- dedup hits
    for target, armors in pairs(dp_errors) do
        for armor, hits in pairs(armors) do
            local num_hits = #table.keys(hits)
            if num_hits == num_hit_order then
                local has_finesse = false
                for k, v in pairs(hits) do
                    if k > num_hit_order then
                        has_finesse = true
                    end
                end
                if not has_finesse then
                    armors[armor] = all_no_finesse
                end
            elseif num_hits == num_hit_order_name - 1 then
                armors[armor] = all_finesse
            end
        end
    end

    print("    " .. key)
    local targets = table.keys(dp_errors)
    table.sort(targets, function(a, b)
        if type(a) == type(b) then
            return a < b
        else
            return type(a) == "number"
        end
    end)
    for _i, target in ipairs(targets) do
        local group = dp_errors[target]
        print("        " .. target)

        local armors = table.keys(group)
        table.sort(armors, function(a, b)
            a = armor_order[a] or 0
            b = armor_order[b] or 0
            return a < b
        end)
        for _i, armor in ipairs(armors) do
            print("            " .. armor)
            local hits = group[armor]
            if hits == all_finesse then
                print("                all hits")
            elseif hits == all_no_finesse then
                print("                all hits (no finesse)")
            else
                local order = table.keys(hits)
                table.sort(order)
                for i, hit in ipairs(order) do
                    print("                " .. hit_order_name[hit])
                end
            end
        end
    end
end
