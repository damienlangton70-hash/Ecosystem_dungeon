class_name Palette
extends RefCounted
## Deepforage house palette — "one warm ember in an ocean of cold glow"
## (see docs/ART_DIRECTION.md). Central tokens so the look stays cohesive and
## the hardcoded-Color migration has a home.

const BG := Color(0.02, 0.025, 0.04)
const AMBIENT := Color(0.16, 0.20, 0.30)
const STONE := Color(0.13, 0.13, 0.15)
const STONE_DARK := Color(0.10, 0.10, 0.12)
const STONE_DEEP := Color(0.05, 0.05, 0.06)

# Cold bioluminescence (teal = near/shallow, violet = deep).
const GLOW_TEAL := Color(0.25, 0.80, 0.85)
const GLOW_BLUE := Color(0.30, 0.55, 0.95)
const GLOW_VIOLET := Color(0.55, 0.35, 0.90)
const GLOW_FUNGUS := Color(0.30, 0.80, 0.60)

# The one warm light, and the hazard red.
const FLAME := Color(1.00, 0.60, 0.25)
const WARN := Color(0.95, 0.35, 0.22)

const WATER := Color(0.10, 0.25, 0.35)
