class_name LoreData
extends RefCounted
## Loads the Lore team's data layer (res://data/lore.json) once and indexes it.
## Systems pull identity + ecology from here instead of hardcoding. Everything
## degrades gracefully: if the file is missing/invalid, accessors return {} and
## callers fall back to their own defaults.

const PATH := "res://data/lore.json"

static var _loaded := false
static var _ok := false
static var _creatures := {}
static var _flora := {}
static var _rules := {}

static func _ensure() -> void:
    if _loaded:
        return
    _loaded = true
    if not FileAccess.file_exists(PATH):
        push_warning("LoreData: %s not found — using hardcoded fallbacks." % PATH)
        return
    var f := FileAccess.open(PATH, FileAccess.READ)
    if f == null:
        return
    var txt := f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("LoreData: parse failed — using fallbacks.")
        return
    for c in parsed.get("creatures", []):
        _creatures[str(c.get("id", ""))] = c
    var flora = parsed.get("flora", {})
    for group in ["trees", "fruit", "herbs"]:
        for item in flora.get(group, []):
            _flora[str(item.get("id", ""))] = item
    _rules = parsed.get("over_hunting_rules", {})
    _ok = true

static func loaded() -> bool:
    _ensure()
    return _ok

static func creature(id: String) -> Dictionary:
    _ensure()
    return _creatures.get(id, {})

static func flora(id: String) -> Dictionary:
    _ensure()
    return _flora.get(id, {})

static func keystone_spike() -> float:
    _ensure()
    return float(_rules.get("keystone_kill_hostility_spike", 0.75))
