class_name MaterialLib
extends RefCounted
## Deepforage — the shared material language, vended from `Palette` tokens.
##
## Everyone building a mesh (world assembly, flora, items) asks MaterialLib for a
## material instead of constructing a StandardMaterial3D inline. This keeps every
## surface in the game speaking the same visual rules from docs/ART_DIRECTION.md §2:
##   - structure/earth is matte (roughness ~0.95, metallic 0)
##   - water is the one surface allowed low roughness + slight metallic + faint emission
##   - emission is reserved for things that are alive-and-luminous, on fire, or dangerous
##   - anything emissive should read like it casts real light, not just a paint job
##
## StandardMaterial3D is the reliable, headless-safe baseline — no custom shader is
## required for the look to hold together, since the whole language *is* the tuned
## albedo/roughness/emission recipe below, consistently applied.

## --- Structure / stone -------------------------------------------------------

## Base cavern rock — unlit matte stone. Used for floor slabs, generic rock mass.
static func stone() -> StandardMaterial3D:
    return _matte(Palette.STONE)

## Stone that reads as catching glow-bounce (upper mid-tone) — ridge faces, rock
## nearest a glowcap canopy, cover boulders inside a lit clearing.
static func stone_lit() -> StandardMaterial3D:
    return _matte(Palette.STONE_LIT)

## Deep-shadow stone — tunnel throats, descent shaft mouth, recesses.
static func stone_dark() -> StandardMaterial3D:
    return _matte(Palette.STONE_DARK)

## Wall rock — warmer, drier brown-black bias so walls don't collapse into the
## same grey mass as the floor/ceiling STONE.
static func wall() -> StandardMaterial3D:
    return _matte(Palette.WALL)

## Chipped ledge / rock-ridge highlight edges. The only stone token allowed near
## mid-value; still matte, just brighter.
static func ridge() -> StandardMaterial3D:
    return _matte(Palette.RIDGE)

## Cavern floor — damp earth and silt.
static func ground() -> StandardMaterial3D:
    return _matte(Palette.GROUND)

## Surface-facing entrance stone, floor-1-top only — the one warm-lit memory of
## daylight-warmed rock.
static func entrance() -> StandardMaterial3D:
    return _matte(Palette.ENTRANCE)

## --- Water --------------------------------------------------------------------

## Still bioluminescent pool. Low roughness + slight metallic for a soft mirror
## sheen (never a hard chrome reflection), translucent (Palette.WATER carries the
## alpha), and a faint self-glow so it reads as both mirror and light source.
static func water() -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Palette.WATER
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.roughness = 0.12
    mat.metallic = 0.25
    mat.emission_enabled = true
    mat.emission = Palette.WATER_EMISSION
    mat.emission_energy_multiplier = 0.6
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

## --- Glow / emissive -------------------------------------------------------

## Generic emissive glow material — glow flora, glow-fungus clusters, warning
## markers. `energy` tunes how hot the emission reads; the caller is expected to
## also add a matching OmniLight3D so the glow casts real light, not just paint.
static func glow(color: Color, energy := 2.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.6
    mat.metallic = 0.0
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = energy
    return mat

## Small emissive accent — ingredient berries, pickup glints, UI-adjacent props.
## Softer default energy than glow() since these are usually tiny surface area.
static func accent(color: Color, emissive := true) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.55
    mat.metallic = 0.0
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 0.6
    return mat

## The one warm light source in the game — lantern/campfire flame core.
static func flame() -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Palette.FLAME
    mat.roughness = 0.4
    mat.metallic = 0.0
    mat.emission_enabled = true
    mat.emission = Palette.FLAME
    mat.emission_energy_multiplier = 3.0
    return mat

## --- Flora ---------------------------------------------------------------

## Living foliage / canopy mass. `deep` picks the shadowed FOLIAGE_DEEP register
## (cap topside, unlit foliage) instead of the lit mid-tone FOLIAGE.
static func foliage(deep := false) -> StandardMaterial3D:
    return _matte(Palette.FOLIAGE_DEEP if deep else Palette.FOLIAGE)

## Tree trunk / bark. `dark` picks TRUNK_DARK (shadow side, Ironbark heartwood)
## instead of the lit TRUNK face.
static func trunk(dark := false) -> StandardMaterial3D:
    return _matte(Palette.TRUNK_DARK if dark else Palette.TRUNK)

## Weeping Palewillow withes — the one soft, pale, low-saturation flora note.
static func palewillow() -> StandardMaterial3D:
    return _matte(Palette.PALEWILLOW, 0.85)

## --- internal ---------------------------------------------------------------

## Shared matte baseline: high roughness, zero metallic, no emission. This is
## the workhorse used by nearly every non-glowing surface in the game.
static func _matte(color: Color, rough := 0.95) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mat.metallic = 0.0
    return mat
