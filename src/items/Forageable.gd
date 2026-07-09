class_name Forageable
extends Node3D
## A harvestable plant (berry bush or herb). The player gathers it with the
## interact key; it regrows after a delay, so foraging is sustainable — over-
## harvesting just means waiting (a gentle echo of the ecosystem theme).
##
## Visual: a real low-poly plant from Flora.gd (berry bush for fruit, herb
## clump for herb) rather than a placeholder sphere — see src/world/Flora.gd
## and docs/ART_DIRECTION.md §5.2. Gameplay API/behaviour is unchanged.

@export var item_id := "emberberry"
@export var display_name := "Emberberry"
@export var yield_amount := 1
@export var color := Color(0.75, 0.25, 0.30)
@export var regrow_time := 25.0

var harvested := false
var _timer := 0.0
var _visual: Node3D

func _ready() -> void:
    add_to_group("forageables")
    var category: String = Recipes.INGREDIENTS.get(item_id, {}).get("category", "fruit")
    _visual = Flora.forageable_visual(item_id, category)
    if _visual != null:
        add_child(_visual)

func harvest() -> int:
    if harvested:
        return 0
    harvested = true
    _timer = regrow_time
    if _visual != null:
        _visual.visible = false
    return yield_amount

func _process(delta: float) -> void:
    if harvested:
        _timer -= delta
        if _timer <= 0.0:
            harvested = false
            if _visual != null:
                _visual.visible = true
