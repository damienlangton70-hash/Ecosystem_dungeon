class_name Ecosystem
extends Node
## First-pass predator-prey model and the over-hunting consequence system.
##
## The design pillar: if the player over-hunts one species, the whole dungeon
## reacts. Predators that lose their prey grow hungrier and roam wider; the
## global hostility rises so every animal is more aggressive and notices the
## player from further away. The Mechanics + Lore agents flesh this into a
## ticking population simulation with migration, starvation and booms/busts.

signal hostility_changed(value: float)

var species: Dictionary = {}     # id -> Species
var global_hostility: float = 0.0  # 0 = calm dungeon, 1 = everything hunts you

func register_species(s: Species) -> void:
    species[s.id] = s

func record_kill(species_id: String, amount: int = 1) -> void:
    if not species.has(species_id):
        return
    var s: Species = species[species_id]
    s.population = maxi(s.population - amount, 0)
    _recompute_hostility()

## Crude first pass: hostility rises as species fall below a third of capacity.
func _recompute_hostility() -> void:
    var pressure := 0.0
    var count := maxi(species.size(), 1)
    for key in species:
        var s: Species = species[key]
        var threshold: int = s.carrying_capacity / 3
        if threshold > 0 and s.population < threshold:
            pressure += float(threshold - s.population) / float(threshold)
    var new_value := clampf(pressure / float(count), 0.0, 1.0)
    if not is_equal_approx(new_value, global_hostility):
        global_hostility = new_value
        hostility_changed.emit(global_hostility)

## Multipliers other systems read to scale aggression / detection.
func aggression_multiplier() -> float:
    return 1.0 + global_hostility * 2.0

func awareness_multiplier() -> float:
    return 1.0 + global_hostility * 1.5
