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
##
## --- 64x64 textures (assets/textures/) --------------------------------------
## Real bitmap textures, not flat colour: each surface family below is backed by
## a deterministically-generated 64x64 SVG (viewBox="0 0 64 64") that Godot 4.3
## imports and rasterizes into a genuine 64x64-pixel texture at import time — see
## tools/gen_textures.py for the generator and assets/textures/ for the files.
## SVG (not PNG) because this repo's GitHub integration can't commit raw binary
## image bytes without corruption; SVG is plain text and round-trips cleanly.
## Textures are loaded once and cached in _TEX_CACHE (load() itself also caches
## by resource path, but keeping our own dictionary avoids repeated res:// path
## string formatting and makes the mapping explicit/auditable in one place).
static var _TEX_CACHE := {}

const TEX_STONE := "res://assets/textures/stone_64.svg"
const TEX_BARK := "res://assets/textures/bark_64.svg"
const TEX_FOLIAGE := "res://assets/textures/foliage_64.svg"
const TEX_WATER_RIPPLE := "res://assets/textures/water_ripple_64.svg"
const TEX_HIDE := "res://assets/textures/hide_mottle_64.svg"

## Shared tiling scale for large flat surfaces (floor/wall boxes) so the 64x64
## texture repeats as a mosaic across a big face instead of stretching one copy
## over the whole thing. Callers building very large or very small meshes can
## still override albedo_texture/uv1_scale afterward if a different repeat rate
## reads better on that specific surface.
const TILE_SCALE := Vector3(4.0, 4.0, 1.0)

static func _load_tex(path: String) -> Texture2D:
    if _TEX_CACHE.has(path):
        return _TEX_CACHE[path]
    var tex: Texture2D = load(path)
    _TEX_CACHE[path] = tex
    return tex

## --- Structure / stone -------------------------------------------------------

## Base cavern rock — mottled stone_64 texture over the STONE tint. Used for
## floor slabs, generic rock mass.
static func stone() -> StandardMaterial3D:
    return _matte_textured(Palette.STONE, TEX_STONE)

## Stone that reads as catching glow-bounce (upper mid-tone) — ridge faces, rock
## nearest a glowcap canopy, cover boulders inside a lit clearing.
static func stone_lit() -> StandardMaterial3D:
    return _matte_textured(Palette.STONE_LIT, TEX_STONE)

## Deep-shadow stone — tunnel throats, descent shaft mouth, recesses.
static func stone_dark() -> StandardMaterial3D:
    return _matte_textured(Palette.STONE_DARK, TEX_STONE)

## Wall rock — warmer, drier brown-black bias so walls don't collapse into the
## same grey mass as the floor/ceiling STONE.
static func wall() -> StandardMaterial3D:
    return _matte_textured(Palette.WALL, TEX_STONE)

## Chipped ledge / rock-ridge highlight edges. The only stone token allowed near
## mid-value; still matte, just brighter.
static func ridge() -> StandardMaterial3D:
    return _matte_textured(Palette.RIDGE, TEX_STONE)

## Cavern floor — damp earth and silt, mottled with the same stone_64 texture
## (GROUND sits in the same tonal family per Palette.gd's own grouping).
static func ground() -> StandardMaterial3D:
    return _matte_textured(Palette.GROUND, TEX_STONE)

## Surface-facing entrance stone, floor-1-top only — the one warm-lit memory of
## daylight-warmed rock. Left untextured/flat: a small, rarely-seen surface with
## its own warm tint that doesn't belong to the cold stone_64 family.
static func entrance() -> StandardMaterial3D:
    return _matte(Palette.ENTRANCE)

## --- Water --------------------------------------------------------------------

## Still bioluminescent pool. Low roughness + slight metallic for a soft mirror
## sheen (never a hard chrome reflection), translucent (Palette.WATER carries the
## alpha), and a faint self-glow so it reads as both mirror and light source.
## Textured with water_ripple_64 (subtle WATER_EMISSION bands over the WATER
## base) so pool surfaces read as gently rippled rather than a flat plane.
static func water() -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Palette.WATER
    mat.albedo_texture = _load_tex(TEX_WATER_RIPPLE)
    mat.uv1_scale = TILE_SCALE
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
    mat.rim_enabled = true
    mat.rim = 0.4
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

## Tiling scale for small flora meshes (trunks, cap undersides, canopy clumps).
## These meshes are much smaller than a floor/wall box, so they use a tighter
## repeat than TILE_SCALE — otherwise the 64x64 mottle would barely show one
## partial cell across a thin trunk cylinder.
const FLORA_TILE_SCALE := Vector3(1.5, 1.5, 1.0)

## Living foliage / canopy mass — mottled with foliage_64. `deep` picks the
## shadowed FOLIAGE_DEEP register (cap topside, unlit foliage) instead of the
## lit mid-tone FOLIAGE.
static func foliage(deep := false) -> StandardMaterial3D:
    return _matte_textured(Palette.FOLIAGE_DEEP if deep else Palette.FOLIAGE, TEX_FOLIAGE, FLORA_TILE_SCALE)

## Tree trunk / bark — mottled with bark_64's vertical grain. `dark` picks
## TRUNK_DARK (shadow side, Ironbark heartwood) instead of the lit TRUNK face.
static func trunk(dark := false) -> StandardMaterial3D:
    return _matte_textured(Palette.TRUNK_DARK if dark else Palette.TRUNK, TEX_BARK, FLORA_TILE_SCALE)

## Weeping Palewillow withes — the one soft, pale, low-saturation flora note.
## Left untextured: a thin, pale, almost-white surface where the dark bark/stone
## mottles would just look like dirt smudges rather than a deliberate texture.
static func palewillow() -> StandardMaterial3D:
    return _matte(Palette.PALEWILLOW, 0.85)

## --- Creature coats -----------------------------------------------------------

## Generic reusable "creature coat" mottle (hide_mottle_64) at medium contrast,
## tinted by `tint` (defaults to a neutral white so the texture's own RIDGE /
## STONE_LIT / TRUNK_DARK tones show through unmodified). This is a foundational
## texture — nothing calls it yet, since no creature mesh currently asks
## MaterialLib for a body material (Creature.gd still builds its own
## StandardMaterial3D from a flat body_color, out of this agent's edit scope
## per the team charter) — but it's wired here so future creature/body-texturing
## work has a ready-made, on-brand entry point instead of inventing its own
## mottle. See tools/gen_textures.py's _hide_body(tones=...) for how a second,
## colour-shifted coat variant (e.g. Ashjackal's warmer palette vs. Mosslamb's
## paler one) could be generated later without touching this accessor's shape.
static func hide(tint := Color(1, 1, 1)) -> StandardMaterial3D:
    var mat := _matte_textured(tint, TEX_HIDE, FLORA_TILE_SCALE)
    mat.rim_enabled = true
    mat.rim = 0.4
    return mat

## --- internal ---------------------------------------------------------------

## Shared matte baseline: high roughness, zero metallic, no emission. This is
## the workhorse used by nearly every non-glowing, non-textured surface.
static func _matte(color: Color, rough := 0.95) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mat.metallic = 0.0
    return mat

## Matte baseline PLUS a tiling 64x64 albedo texture — the textured counterpart
## to _matte(), used by every surface family that now ships a real bitmap
## texture instead of flat colour (Step 2/3 of the 64x64 texture upgrade).
## `color` still sets albedo_color: StandardMaterial3D multiplies albedo_color
## by albedo_texture per-pixel, so the Palette tint keeps tinting the mottle
## rather than the mottle replacing it outright — this is what lets stone(),
## stone_lit(), stone_dark(), wall(), ridge() and ground() all share one
## stone_64 texture while still reading as distinct tones.
static func _matte_textured(color: Color, texture_path: String, tile := TILE_SCALE, rough := 0.95) -> StandardMaterial3D:
    var mat := _matte(color, rough)
    mat.albedo_texture = _load_tex(texture_path)
    mat.uv1_scale = tile
    return mat
