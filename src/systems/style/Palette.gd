class_name Palette
extends RefCounted
## Deepforage — the single source of truth for colour. Reference as Palette.STONE, etc.
## Cold bioluminescence against dark wet stone, one warm amber flame. Art-matched to
## docs/keyart. See docs/ART_DIRECTION.md.
##
## Rule for the whole studio: no new hardcoded Color(...) literals in gameplay/graphics
## code. If a colour isn't here, it belongs here — add it, don't inline it.

# --- Structure / stone ---
const STONE := Color(0.10, 0.11, 0.14)          ## Base cavern rock — near-black, cool blue-grey.
const STONE_DARK := Color(0.045, 0.05, 0.065)   ## Deep shadow recesses, tunnel throats, the descent shaft.
const STONE_LIT := Color(0.16, 0.18, 0.22)      ## Rock faces catching glow-bounce; upper mid-tone read.
const WALL := Color(0.115, 0.10, 0.095)         ## Wall rock with a warmer, drier brown-black bias (contrast to STONE's blue).
const RIDGE := Color(0.20, 0.19, 0.18)          ## Chipped ledges / rock-ridge highlight edges catching light.
const GROUND := Color(0.085, 0.08, 0.075)       ## Cavern floor — damp earth/silt, slightly warm-dark.
const ENTRANCE := Color(0.30, 0.24, 0.16)       ## Surface-facing entrance stone; faint daylight-warmed rock, only ever seen at floor 1's top.

# --- Cold bioluminescence (these double as light colours) ---
const GLOW_TEAL := Color(0.30, 0.95, 0.80)      ## Glowcap cap rim / gill-glow — the coldest, brightest accent.
const GLOW_BLUE := Color(0.35, 0.60, 0.95)      ## Mid-register cap glow and water reflection tint.
const GLOW_VIOLET := Color(0.55, 0.40, 0.90)    ## Deep cap glow, distant canopy, floor-3+ dominant hue.
const GLOW_FUNGUS := Color(0.45, 0.90, 0.65)    ## Ground glow-fungus clusters — greener, warmer-cool than cap glow.
const GLOW_DIM := Color(0.18, 0.30, 0.32)       ## Unlit / background bioluminescence — same family, desaturated, for far background caps.

# --- Warmth ---
const FLAME := Color(1.00, 0.62, 0.20)          ## The lantern/campfire flame core — the ONE warm light in the world.
const EMBER := Color(0.85, 0.35, 0.10)          ## Coals, dying fire, cooked-meat sear marks.
const WARN := Color(0.95, 0.22, 0.12)           ## Descent-lip warning glow — hot red-orange, reads as danger not comfort.

# --- Water ---
const WATER := Color(0.12, 0.22, 0.24, 0.75)    ## Still bioluminescent pools; alpha < 1 for translucency over GROUND.
const WATER_EMISSION := Color(0.25, 0.55, 0.55) ## Faint self-glow / canopy-mirror sheen on pool surfaces.

# --- Flora ---
const TRUNK := Color(0.42, 0.36, 0.30)          ## Glowcap pillar-tree stalk / Ironbark bark, lit face.
const TRUNK_DARK := Color(0.20, 0.17, 0.15)     ## Trunk shadow side; Ironbark's near-black heartwood.
const FOLIAGE := Color(0.20, 0.45, 0.38)        ## Living cap underside / canopy foliage, mid-tone.
const FOLIAGE_DEEP := Color(0.10, 0.22, 0.22)   ## Shadowed foliage / cap topside where glow doesn't reach.
const PALEWILLOW := Color(0.72, 0.78, 0.72)     ## Weeping Palewillow withes — pale, waterside, the one "soft" flora note.

# --- Atmosphere ---
const FOG := Color(0.08, 0.10, 0.13, 0.55)      ## Volumetric haze/fog tint for depth cueing; teal-leaning, never neutral grey.
const AMBIENT := Color(0.05, 0.07, 0.09)        ## Baseline ambient/ WorldEnvironment fill — deliberately dark; glow does the lighting.

# --- Ingredient accents (keyed to Recipes.INGREDIENTS ids) ---
const INGREDIENT := {
    "emberberry": Color(0.90, 0.32, 0.14),      # warming — warm red/orange, kin to FLAME/EMBER
    "gloomgrape": Color(0.52, 0.34, 0.72),       # stamina — violet, kin to GLOW_VIOLET
    "bleedberry": Color(0.55, 0.06, 0.14),       # healing — deep crimson, darker/richer than WARN
    "duskfig": Color(0.32, 0.22, 0.28),          # calories — dusky purple-brown
    "palethyme": Color(0.62, 0.78, 0.58),        # pale culinary green
    "stoneleaf": Color(0.44, 0.52, 0.42),        # grey-green rosemary, kin to STONE + FOLIAGE
    "deeprootginger": Color(0.80, 0.58, 0.26),   # golden tan
    "marrowmint": Color(0.35, 0.72, 0.68),       # mint teal-green, kin to GLOW_TEAL
}

## Accent colour for a forageable/ingredient id, with a sensible fallback.
static func ingredient_color(id: String, fallback := Color(0.7, 0.7, 0.6)) -> Color:
    return INGREDIENT.get(id, fallback)
