class_name Species
extends Resource
## Data definition for one animal species in the dungeon food-web.
## Authored entries live in the Lore agent's bestiary; this Resource is the
## runtime shape the Ecosystem simulation consumes.

@export var id: String = ""
@export var display_name: String = ""
@export var tier: int = 1               # 1 = base grazer ... 5 = apex predator
@export var diet: Array[String] = []    # species ids this animal eats
@export var population: int = 100       # current head-count on the floor
@export var carrying_capacity: int = 100
@export var base_aggression: float = 0.2  # 0 = passive, 1 = attacks on sight
@export var awareness: float = 0.3        # detection radius scalar
@export var edible := true                # can the player cook/eat it
