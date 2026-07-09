class_name Recipes
extends RefCounted
## Ingredient registry + meal builder. First-pass slice of the FOOD_WEB flora:
## a handful of fruits and herbs, each mapping to a cooking buff. The Lore agent
## expands this toward the full 10 fruits / 10 herbs with richer effects.
##
## Buff types: "regen" (hp/sec), "stamina" (sta/sec), "defense" (0..1 dmg cut), "warm".

const INGREDIENTS := {
    "emberberry":     {"category": "fruit", "food": 8.0,  "heal": 0.0, "buff": "warm",    "mag": 0.0,  "dur": 0.0,  "display": "Emberberry"},
    "gloomgrape":     {"category": "fruit", "food": 6.0,  "heal": 0.0, "buff": "stamina", "mag": 12.0, "dur": 10.0, "display": "Gloomgrape"},
    "bleedberry":     {"category": "fruit", "food": 6.0,  "heal": 0.0, "buff": "regen",   "mag": 4.0,  "dur": 6.0,  "display": "Bleedberry"},
    "duskfig":        {"category": "fruit", "food": 18.0, "heal": 0.0, "buff": "",        "mag": 0.0,  "dur": 0.0,  "display": "Duskfig"},
    "palethyme":      {"category": "herb",  "food": 0.0,  "heal": 0.0, "buff": "stamina", "mag": 16.0, "dur": 12.0, "display": "Palethyme"},
    "stoneleaf":      {"category": "herb",  "food": 0.0,  "heal": 0.0, "buff": "defense", "mag": 0.4,  "dur": 12.0, "display": "Stoneleaf Rosemary"},
    "deeprootginger": {"category": "herb",  "food": 0.0,  "heal": 4.0, "buff": "regen",   "mag": 3.0,  "dur": 8.0,  "display": "Deeproot Ginger"},
    "marrowmint":     {"category": "herb",  "food": 0.0,  "heal": 0.0, "buff": "warm",    "mag": 0.0,  "dur": 0.0,  "display": "Marrow Mint"},
}

## Build a cooked meal from 1 meat + optional herb + optional fruit.
## Returns { name, food, heal, buffs:[{type,mag,dur}] }.
static func make_meal(herb_id: String, fruit_id: String) -> Dictionary:
    var food := 35.0
    var heal := 8.0
    var buffs: Array = []
    var parts: Array = []
    if fruit_id != "" and INGREDIENTS.has(fruit_id):
        var f: Dictionary = INGREDIENTS[fruit_id]
        food += f["food"]
        heal += f["heal"]
        if f["buff"] != "":
            buffs.append({"type": f["buff"], "mag": f["mag"], "dur": f["dur"]})
        parts.append(f["display"])
    if herb_id != "" and INGREDIENTS.has(herb_id):
        var h: Dictionary = INGREDIENTS[herb_id]
        food += h["food"]
        heal += h["heal"]
        if h["buff"] != "":
            buffs.append({"type": h["buff"], "mag": h["mag"], "dur": h["dur"]})
        parts.append(h["display"])
    var nm := "Roast meat"
    if parts.size() > 0:
        nm += " with " + ", ".join(parts)
    return {"name": nm, "food": food, "heal": heal, "buffs": buffs}
