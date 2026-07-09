extends Node
## Headless self-test for the survival/cooking loop. Runs like the real game
## (normal scene tree), drives the interaction methods directly, and asserts.
## Run:  godot --headless --path . res://tools/SelfTest.tscn
## Prints "SELFTEST: PASS" (exit 0) or "SELFTEST: FAIL" (exit 1).

func _ready() -> void:
    var eco = load("res://src/systems/ecosystem/Ecosystem.gd").new()
    eco.add_to_group("ecosystem")
    add_child(eco)

    var player = load("res://src/player/Player.gd").new()
    add_child(player)                     # _ready() runs synchronously
    player.global_position = Vector3.ZERO

    var pk = load("res://src/items/Pickup.gd").new()
    pk.item_id = "raw_meat"
    pk.amount = 2
    add_child(pk)
    pk.global_position = Vector3(0, 0, 1)

    player._collect()
    var ok_collect: bool = int(player.inventory.get("raw_meat", 0)) == 2

    player._build_campfire()
    var ok_fire: bool = get_tree().get_nodes_in_group("campfires").size() >= 1

    player._cook()
    var ok_cook: bool = int(player.inventory.get("cooked_meat", 0)) == 1 and int(player.inventory.get("raw_meat", 0)) == 1

    player.survival.hunger = 40.0
    player._eat()
    var ok_eat: bool = player.survival.hunger > 40.0 and int(player.inventory.get("cooked_meat", 0)) == 0

    print("SELFTEST collect=%s fire=%s cook=%s eat=%s" % [ok_collect, ok_fire, ok_cook, ok_eat])
    var passed: bool = ok_collect and ok_fire and ok_cook and ok_eat
    print("SELFTEST: %s" % ("PASS" if passed else "FAIL"))
    get_tree().quit(0 if passed else 1)
