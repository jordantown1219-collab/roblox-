-- Lobby/match adapter. Existing server combat, gates and balance remain authoritative.
local Mode={}
function Mode.new(rules)
 assert(type(rules)=="table" and type(rules.allFinished)=="function","Extraction rules required")
 return {
  id="Extraction", allowsRespawn=true,
  teamFinished=function(required,stages) return rules.allFinished(required,stages) end,
 }
end
return Mode
