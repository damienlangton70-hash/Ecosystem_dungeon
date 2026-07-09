class_name SurvivalStats
extends Node
## Foundational survival needs. First pass: hunger drains over time, stamina
## regenerates when not sprinting. The Mechanics agent extends this into the
## full loop: thirst, body temperature (warmth near campfires / magic circles),
## cooked-food buffs, and starvation penalties.

@export var max_hunger := 100.0
@export var max_stamina := 100.0

var hunger := 100.0
var stamina := 100.0
var temperature := 20.0  # degrees C; shelter + fire raise this later

var hunger_drain := 0.5      # per second
var stamina_regen := 15.0    # per second when not sprinting
var stamina_sprint := 25.0   # per second while sprinting

func _process(delta: float) -> void:
    hunger = maxf(hunger - hunger_drain * delta, 0.0)
    if Input.is_physical_key_pressed(KEY_SHIFT):
        stamina = maxf(stamina - stamina_sprint * delta, 0.0)
    else:
        stamina = minf(stamina + stamina_regen * delta, max_stamina)

func feed(amount: float) -> void:
    hunger = minf(hunger + amount, max_hunger)

## Spend stamina for a combat action; returns false if there isn't enough.
func use_stamina(amount: float) -> bool:
    if stamina < amount:
        return false
    stamina -= amount
    return true
