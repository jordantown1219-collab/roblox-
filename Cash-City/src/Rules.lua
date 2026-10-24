-- Pure functions: no client can set stage, damage, health, or team victory.
local Rules = {}
function Rules.canEnter(stage, doorStage, playerTeam, doorTeam, downed, phase)
    return phase == "Match" and not downed and playerTeam == doorTeam and doorStage == stage + 1
end
function Rules.damage(base, strength)
    return math.max(1, math.floor(base * strength + 0.5))
end
function Rules.allFinished(roster, stages)
    local count = 0
    for _, member in pairs(roster) do
        if member.required then
            count = count + 1
            if not member.connected or member.stage ~= stages or not member.extracted or member.downed then
                return false
            end
        end
    end
    return count > 0
end
function Rules.canTakeArmor(playerId, playerTeam, stage, ownerId, ownerTeam, armorStage, ownerActive)
    return ownerActive and stage == armorStage and (playerId == ownerId or playerTeam ~= ownerTeam)
end
function Rules.absorbDamage(armor, amount)
    local absorbed = math.min(math.max(0, armor), math.max(0, amount))
    return math.max(0, armor - absorbed), math.max(0, amount - absorbed)
end
return Rules
