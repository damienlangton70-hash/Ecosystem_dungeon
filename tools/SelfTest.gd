extends Node
## Headless self-test for the survival / cooking / foraging loop. Runs like the
## real game and drives the interaction methods directly.
## Run:  godot --headless --path . res://tools/SelfTest.tscn
## Prints "SELFTEST: PASS" (exit 0) or "SELFTEST: FAIL" (exit 1).

func _ready() -> void:
    var eco = load("res://src/systems/ecosystem/Ecosystem.gd").new()
    eco.add_to_group("ecosystem")
    add_child(eco)

    var player = load("res://src/player/Player.gd").new()
    add_child(player)
    player.global_position = Vector3.ZERO

    # Butcher a dropped raw-meat pickup.
    var pk = load("res://src/items/Pickup.gd").new()
    pk.item_id = "raw_meat"
    pk.amount = 2
    add_child(pk)
    pk.global_position = Vector3(0, 0, 1)
    player._collect()
    var ok_butcher: bool = int(player.inventory.get("raw_meat", 0)) == 2

    # Let the freed pickup actually leave the tree before foraging.
    await get_tree().process_frame

    # Forage an herb.
    var fo = load("res://src/items/Forageable.gd").new()
    fo.item_id = "palethyme"
    fo.display_name = "Palethyme"
    add_child(fo)
    fo.global_position = Vector3(0, 0, 1)
    player._collect()
    var ok_forage: bool = int(player.inventory.get("palethyme", 0)) == 1

    # Build a campfire and cook meat + herb into a meal.
    player._build_campfire()
    var ok_fire: bool = get_tree().get_nodes_in_group("campfires").size() >= 1
    player._cook()
    var ok_cook: bool = player.meals.size() == 1 \
        and int(player.inventory.get("raw_meat", 0)) == 1 \
        and int(player.inventory.get("palethyme", 0)) == 0

    # Eat the meal -> hunger restored + a buff applied.
    player.survival.hunger = 40.0
    player._eat()
    var ok_eat: bool = player.survival.hunger > 40.0 \
        and player.meals.size() == 0 \
        and player.active_buffs.size() >= 1

    # Combat: a heavy hit breaks poise and staggers a predator.
    var cr = load("res://src/creatures/Creature.gd").new()
    cr.is_predator = true
    cr.max_health = 40.0
    cr.max_poise = 30.0
    add_child(cr)
    cr.global_position = Vector3(4, 0, 0)
    var hp0: float = cr.health
    cr.take_damage(32.0, 45.0)
    var ok_combat: bool = cr.health < hp0 and cr.state == Creature.State.STAGGER

    print("SELFTEST butcher=%s forage=%s fire=%s cook=%s eat=%s combat=%s" % [ok_butcher, ok_forage, ok_fire, ok_cook, ok_eat, ok_combat])
    var passed: bool = ok_butcher and ok_forage and ok_fire and ok_cook and ok_eat and ok_combat
    print("SELFTEST: %s" % ("PASS" if passed else "FAIL"))
    get_tree().quit(0 if passed else 1)
