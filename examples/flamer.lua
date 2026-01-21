local ArmorSettings = require("scripts/settings/damage/armor_settings")
local BuffTemplates = require("scripts/settings/buff/buff_templates")
local Breeds = require("scripts/settings/breed/breeds")
local DamageCalculation = require("scripts/utilities/attack/damage_calculation")
local DamageProfile = require("scripts/utilities/attack/damage_profile")
local DamageProfileTemplates = require("scripts/settings/damage/damage_profile_templates")
local MinionDifficultySettings = require("scripts/settings/difficulty/minion_difficulty_settings")

local lerp_values = {
    current_target_settings_lerp_values = {}
}
local hit_zone = nil
local charge_level = 1
local is_critical_strike = nil
local hit_weakspot = nil
local hit_shield = nil
local is_backstab = nil
local is_flanking = nil
local dropoff_scalar = nil
local attacker_stat_buffs = {}
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

local attacker_buff_extension = nil
local stagger_impact_bonus = nil
local attacking_unit_or_nil = nil
local attacking_unit_owner_unit_or_nil = nil
local attacker_owner_buff_extension = nil
local target_index = nil

local armor_type = ArmorSettings.types.player
local damage_type = "burning"
local breed = Breeds.human
local attacker_breed = Breeds.cultist_flamer

function calc_damage(damage_profile, power_level)
    local target_settings = DamageProfile.target_settings(damage_profile, 0)
    local damage, efficiency = DamageCalculation.calculate(
        damage_profile,
        damage_type,
        target_settings,
        lerp_values,
        hit_zone,
        power_level,
        charge_level,
        breed_or_nil,
        attacker_owner_breed_or_nil,
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
        attacker_buff_extension,
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
        stagger_impact,
        stagger_impact_bonus,
        attacking_unit_or_nil,
        attacking_unit_owner_unit_or_nil,
        attacker_owner_buff_extension,
        target_index
    )
    return damage
end

-- flamer debuff
do
    local damage_profile = DamageProfileTemplates.grenadier_liquid_fire_burning
	local power_level_table = MinionDifficultySettings.power_level.renegade_flamer_on_hit_fire
    local power_level = power_level_table[5]

    local damage = calc_damage(damage_profile, power_level)
    print("grenadier_liquid_fire_burning (damage):")
    print("  " .. damage)
    print()
end

-- flamer liquid
do
    local damage_profile = DamageProfileTemplates.renegade_flamer_liquid_fire_burning
	local power_level_table = MinionDifficultySettings.power_level.renegade_flamer_fire
    local power_level = power_level_table[5]

    print("renegade_flamer_liquid_fire_burning (tick - damage):")
    for i, mult in ipairs(BuffTemplates.cultist_flamer_in_fire_liquid.power_level_scale_per_tick) do
        local damage = calc_damage(damage_profile, power_level * mult)
        print("  " .. i .. " - " .. damage)
    end
    print()
end
