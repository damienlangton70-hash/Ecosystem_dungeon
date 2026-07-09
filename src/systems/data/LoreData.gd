class_name LoreData
extends RefCounted
## Loads the data layer once and indexes it:
##   res://data/lore.json   — identity + ecology (Lore team's authoritative file)
##   res://data/combat.json — per-creature combat stats (hp/damage/speed/poise)
## Systems pull from here instead of hardcoding. Everything degrades gracefully:
## if a file is missing/invalid, accessors return {} and callers use their own
## fallbacks (Main.TIER_TUNING for combat).

const LORE_PATH := "res://data/lore.json"
const COMBAT_PATH := "res://data/combat.json"

static var _loaded := false
static var _creatures := {}
static var _flora := {}
static var _combat := {}
static var _rules := {}

static func _ensure() -> void:
    if _loaded:
        return
    _loaded = true
    _load_lore()
    _load_combat()

static func _read_json(path: String):
    if not FileAccess.file_exists(path):
        push_warning("LoreData: %s not found — using fallbacks." % path)
        return null
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return null
    var txt := f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("LoreData: parse failed for %s." % path)
        return null
    return parsed

static func _load_lore() -> void:
    var d = _read_json(LORE_PATH)
    if d == null:
        return
    for c in d.get("creatures", []):
        _creatures[str(c.get("id", ""))] = c
    var flora = d.get("flora", {})
    for group in ["trees", "fruit", "herbs"]:
        for item in flora.get(group, []):
            _flora[str(item.get("id", ""))] = item
    _rules = d.get("over_hunting_rules", {})

static func _load_combat() -> void:
    var d = _read_json(COMBAT_PATH)
    if d == null:
        return
    _combat = d.get("combat", {})

static func creature(id: String) -> Dictionary:
    _ensure()
    return _creatures.get(id, {})

static func flora(id: String) -> Dictionary:
    _ensure()
    return _flora.get(id, {})

static func combat(id: String) -> Dictionary:
    _ensure()
    return _combat.get(id, {})

static func keystone_spike() -> float:
    _ensure()
    return float(_rules.get("keystone_kill_hostility_spike", 0.75))
