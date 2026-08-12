local Catalog = {}

local SPECIES = {
  "ABRA", "ALAKAZAM", "BELLSPROUT", "BUTTERFREE", "CHARMANDER",
  "CHARMELEON", "DRAGONAIR", "DRAGONITE", "DROWZEE", "DUGTRIO",
  "ELECTABUZZ", "EXEGGCUTE", "FEAROW", "GEODUDE", "GOLEM", "GRAVELER",
  "GRIMER", "GROWLITHE", "GYARADOS", "HAUNTER", "HORSEA", "HYPNO",
  "IVYSAUR", "JOLTEON", "JYNX", "KADABRA", "KANGASKHAN", "KOFFING",
  "LAPRAS", "MAGMAR", "MAGNETON", "MAGNEMITE", "MANKEY", "MR_MIME",
  "ODDISH", "OMANYTE", "ONIX", "PARAS", "PERSIAN", "PIKACHU",
  "PINSIR", "POLIWAG", "PONYTA", "PSYDUCK", "RHYDON", "RHYHORN",
  "SANDSLASH", "SCYTHER", "SLOWPOKE", "SNORLAX", "STARMIE", "STARYU",
  "TANGELA", "TAUROS", "VENONAT", "VOLTORB", "VULPIX", "WARTORTLE",
}

local function clone(source, id, name)
  local out = {}
  for key, value in pairs(source) do out[key] = value end
  out.id, out.name = id, name or id
  return out
end

function Catalog.seed(data)
  -- ROM-free SDK fixtures intentionally expose only a tiny catalog. Clone
  -- known-good fixture records under the production IDs used by this mod so
  -- isolated loader suites still validate all references.
  for _, species in ipairs(SPECIES) do
    data.pokemon[species] = clone(data.pokemon.FIXMON_A, species)
  end
  data.trainers.OPP_COOLTRAINER_M = clone(
    data.trainers.OPP_FIX_YOUNGSTER, "OPP_COOLTRAINER_M", "COOLTRAINER")
  data.trainers.OPP_COOLTRAINER_F = clone(
    data.trainers.OPP_FIX_YOUNGSTER, "OPP_COOLTRAINER_F", "COOLTRAINER")
  return data
end

return Catalog
