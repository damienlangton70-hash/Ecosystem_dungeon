class_name HUD
extends CanvasLayer
## Deepforage — the real in-game HUD, re-skinned per docs/ART_DIRECTION.md §6: a
## restrained hand-inked field-journal register, not a game engine's default
## overlay — and not the dark/monospace "match the reference image" look this
## HUD briefly wore. Damien chose the parchment-journal vision as canon, so
## this is that vision applied to the same data/layout (§6.2 step 1: "re-skin
## first, restructure never" — panel POSITIONS and every data binding are
## unchanged from the previous pass; only colour/typography/frame changed).
##
## Warm parchment/cream panel tint + ink-dark (kin to Palette.WALL, not pure
## black) linework and text; Palette tokens are reserved for sparing,
## meaningful accents only — the HP/STA/HUNGER bars and ingredient swatches,
## exactly as §6.1's colour rule specifies — never a rainbow of arbitrary
## panel borders (that was itself the "vector-flat corporate" look §6 warns
## against, so this pass drops it). Hand-lettered/brush system font for
## headers, a clean serif for body/stat text — "journal marginalia, not a HUD
## font," zero rune/blackletter fantasy-generic type. Built entirely from
## StyleBoxFlat + SystemFont, same no-binary-asset constraint as everywhere
## else.
##
## Owns every HUD control node and its own _process(delta) reading live
## player/ecosystem state. Main.gd just constructs one of these and calls
## bind() once both _player and _ecosystem exist.
##
## Binds ONLY to fields that are real today (verified against Main.gd/Player.gd/
## SurvivalStats.gd/Ecosystem.gd): health/max_health, survival.stamina/hunger
## (+ max), global_position.y, ecosystem.global_hostility, the "creatures" group
## count, lock_target, inventory["raw_meat"], meals.size(), count_category(),
## active_buffs, status_text. No thirst/temperature meters, no minimap, no quest
## log — those systems don't exist yet, so this HUD doesn't fake them.

var _player: Player
var _ecosystem: Ecosystem

# Bars (foreground fill ColorRects resized by % — the same proven pattern the
# original HUD used, just re-skinned).
var _hp_fill: ColorRect
var _hp_text: Label
var _sta_fill: ColorRect
var _sta_text: Label
var _hunger_fill: ColorRect
var _hunger_text: Label

# Situational readout (top-right).
var _depth_text: Label
var _hostility_text: Label
var _creatures_text: Label

# Status cluster (transient).
var _lock_label: Label
var _buff_row: HBoxContainer
var _status_label: Label

# Provisions chips (bottom-left) — one count Label each.
var _chip_meat: Label
var _chip_meals: Label
var _chip_fruit: Label
var _chip_herb: Label

# Tracks the joined buff-type key last rendered, so _refresh_buff_pills() only
# tears down/rebuilds the pill row when the active set actually changes.
var _last_buff_key := ""

const BAR_WIDTH := 176.0

# --- Journal palette (UI-only presentation tones, not world Palette tokens —
# per §6.1, "paper"/"ink" are new UI-specific neutrals; the same sanctioned
# exception the old HUD's plain black-alpha backdrop already used). ---
const PAPER := Color(0.87, 0.80, 0.655, 0.66)        # warm parchment panel tint
const PAPER_RECESS := Color(0.74, 0.665, 0.535, 0.55) # bar/badge tracks — a shade in from the page
const INK_LINE := Color(0.145, 0.125, 0.105, 0.85)    # border linework — kin to Palette.WALL, not pure black
const INK_TEXT := Color(0.12, 0.10, 0.085)            # body/stat text — dark warm ink, opaque for legibility
const INK_TEXT_SOFT := Color(0.32, 0.28, 0.23)        # secondary/label text — softer ink

## Hand-lettered/rough-brush display face for headers and floor names —
## "journal marginalia, not a HUD font," never a rune/blackletter
## fantasy-generic face. Godot 4 resolves the first installed match at
## runtime, falling back to the engine default if none are present — zero
## font files committed, per the no-binary-assets constraint.
static func _brush_font() -> Font:
    var f := SystemFont.new()
    f.font_names = PackedStringArray(["Bradley Hand", "Segoe Print", "Noteworthy", "Chalkboard SE", "Comic Sans MS", "cursive"])
    return f

## Clean, high-legibility serif for body/stat text — §6.1's other half of the
## typography rule.
static func _serif_font() -> Font:
    var f := SystemFont.new()
    f.font_names = PackedStringArray(["Palatino", "Book Antiqua", "Georgia", "Times New Roman", "serif"])
    return f

func _ready() -> void:
    layer = 10
    _build_vitals_panel()
    _build_status_cluster()
    _build_provisions_row()
    _build_controls_legend()
    _build_situational_panel()

## Called once by Main.gd after both _player and _ecosystem exist.
func bind(player: Player, ecosystem: Ecosystem) -> void:
    _player = player
    _ecosystem = ecosystem

# ---------------------------------------------------------------- chrome ------

## Shared parchment panel chrome: a warm paper tint, soft irregular corners (a
## hand-torn-edge suggestion rather than one uniform app-card radius), and a
## thin ink border on every side — a bordered journal card, not the "coloured
## top accent stripe on a dark card" convention this HUD briefly wore. Every
## panel shares this SAME chrome now — per §6.1, colour is reserved for
## meaningful data (the bars, ingredient swatches), never a per-panel accent.
func _panel_style() -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = PAPER
    sb.corner_radius_top_left = 7
    sb.corner_radius_top_right = 11
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 6
    sb.border_width_top = 2
    sb.border_width_bottom = 2
    sb.border_width_left = 2
    sb.border_width_right = 2
    sb.border_color = INK_LINE
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 10
    sb.content_margin_bottom = 12
    return sb

## A small diamond mark (a rotated colour swatch) standing in for a hand-drawn
## icon/bullet — reads less "flat app icon" than a plain square. Used only
## where the colour is meaningful (a stat's Palette tint, an ingredient's
## Palette.ingredient_color) per §6.1's "sparingly and meaningfully" rule.
## Control has its own rotation/pivot_offset (distinct from Node2D's), so this
## is a pure visual transform that doesn't disturb container layout.
func _swatch(color: Color, size := 11) -> ColorRect:
    var r := ColorRect.new()
    r.color = color
    r.custom_minimum_size = Vector2(size, size)
    r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    r.pivot_offset = Vector2(size * 0.5, size * 0.5)
    r.rotation_degrees = 45.0
    return r

## `brush` picks the hand-lettered display face for headers/floor names;
## everything else (labels, stat text, badge text) is the clean serif, per
## §6.1's "journal marginalia, not a HUD font" split.
func _label(text: String, size := 13, color := INK_TEXT, brush := false) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_override("font", _brush_font() if brush else _serif_font())
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

## Background + fill ColorRect bar pair inside `into`, both fixed to BAR_WIDTH
## so the fill's size.x can be driven by % without touching layout containers,
## plus a thin ink outline layered on top with a fully transparent interior —
## the border stays visible around the bar's full extent regardless of fill %,
## instead of a solid black track like the HUD's first pass.
func _make_bar(into: Control, fill_color: Color, height := 14) -> ColorRect:
    var holder := Control.new()
    holder.custom_minimum_size = Vector2(BAR_WIDTH, height)
    into.add_child(holder)
    var bg := ColorRect.new()
    bg.color = PAPER_RECESS
    bg.size = Vector2(BAR_WIDTH, height)
    holder.add_child(bg)
    var fill := ColorRect.new()
    fill.color = fill_color
    fill.size = Vector2(BAR_WIDTH, height)
    holder.add_child(fill)
    var outline := Panel.new()
    var osb := StyleBoxFlat.new()
    osb.bg_color = Color(0, 0, 0, 0)
    osb.border_width_top = 1
    osb.border_width_bottom = 1
    osb.border_width_left = 1
    osb.border_width_right = 1
    osb.border_color = INK_LINE
    outline.add_theme_stylebox_override("panel", osb)
    outline.size = Vector2(BAR_WIDTH, height)
    holder.add_child(outline)
    return fill

# ---------------------------------------------------------------- vitals ------

## Top-left: floor title + HP / STA / HUNGER bars, each with a distinct colour
## identity pulled straight from Palette — the sparing, meaningful accent use
## §6.1 calls for, against the uniform parchment frame everything else shares.
func _build_vitals_panel() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(panel)

    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 7)
    panel.add_child(col)

    var title := _label("Deepforage", 16, INK_TEXT, true)
    col.add_child(title)
    var subtitle := _label("Floor 1 · The Fungal Shallows", 11, INK_TEXT_SOFT)
    col.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size = Vector2(0, 2)
    col.add_child(spacer)

    # HP — WARN (hot red-orange danger token): the roster's existing "danger,
    # not comfort" colour, reused here so HP reads as the stat that hurts you.
    var hp_parts := _stat_row("HP", Palette.WARN)
    col.add_child(hp_parts[0])
    _hp_fill = hp_parts[1]
    _hp_text = hp_parts[2]
    # STA — GLOW_TEAL (coldest, brightest bioluminescence accent).
    var sta_parts := _stat_row("STA", Palette.GLOW_TEAL)
    col.add_child(sta_parts[0])
    _sta_fill = sta_parts[1]
    _sta_text = sta_parts[2]
    # HUNGER — FLAME (the one warm light in the world) — §6.1's own example
    # ("a hunger bar tinted toward FLAME/EMBER as it empties").
    var hunger_parts := _stat_row("HUNGER", Palette.FLAME)
    col.add_child(hunger_parts[0])
    _hunger_fill = hunger_parts[1]
    _hunger_text = hunger_parts[2]

## One "swatch + label + bar + trailing %/count text" row.
func _stat_row(label_text: String, color: Color) -> Array:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    row.add_child(_swatch(color))
    var lab := _label(label_text, 12)
    lab.custom_minimum_size = Vector2(56, 0)
    row.add_child(lab)
    var fill := _make_bar(row, color)
    var pct := _label("100%", 12, INK_TEXT_SOFT)
    pct.custom_minimum_size = Vector2(44, 0)
    pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    row.add_child(pct)
    return [row, fill, pct]

# ------------------------------------------------------------- status cluster -

## Just below the vitals panel: lock-on target, active buff chips, and the
## transient status_text feedback line — plain ink text, no panel chrome,
## since these are secondary/transient (a margin note, not a page).
func _build_status_cluster() -> void:
    var col := VBoxContainer.new()
    col.position = Vector2(16, 148)
    col.add_theme_constant_override("separation", 5)
    add_child(col)

    _lock_label = _label("", 12, Palette.WARN)
    col.add_child(_lock_label)

    _buff_row = HBoxContainer.new()
    _buff_row.add_theme_constant_override("separation", 6)
    col.add_child(_buff_row)

    _status_label = _label("", 12, INK_TEXT_SOFT)
    col.add_child(_status_label)

## One small rounded pill per active buff type — parchment-consistent, not a
## special colour (a buff isn't a single fixed Palette concept, so it gets the
## same uniform chrome as every other panel/badge).
func _make_buff_pill(buff_type: String) -> PanelContainer:
    var pill := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = PAPER
    sb.corner_radius_top_left = 8
    sb.corner_radius_top_right = 8
    sb.corner_radius_bottom_left = 8
    sb.corner_radius_bottom_right = 8
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_color = INK_LINE
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 2
    sb.content_margin_bottom = 2
    pill.add_theme_stylebox_override("panel", sb)
    pill.add_child(_label(buff_type.capitalize(), 11, INK_TEXT))
    return pill

# ------------------------------------------------------------ provisions row --

## Bottom-left: 4 slot-chip panels (Raw Meat / Meals / Fruit / Herbs), each a
## real bound count — parchment chrome with one small meaningful-colour swatch
## per chip (the ingredient's own Palette.ingredient_color), not a whole
## coloured border, per §6.1's own "recipe card ingredient swatch" example.
func _build_provisions_row() -> void:
    var row := HBoxContainer.new()
    row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    row.position = Vector2(16, -84)
    row.add_theme_constant_override("separation", 8)
    add_child(row)

    _chip_meat = _add_chip(row, "Meat", Palette.EMBER)
    _chip_meals = _add_chip(row, "Meals", Palette.FLAME)
    _chip_fruit = _add_chip(row, "Fruit", Palette.ingredient_color("bleedberry"))
    _chip_herb = _add_chip(row, "Herbs", Palette.ingredient_color("stoneleaf"))

## One 60x60 slot chip: parchment chrome, a small colour-swatch mark, a label,
## and a count in serif — returns the count Label to update later.
func _add_chip(into: Control, label_text: String, color: Color) -> Label:
    var chip := PanelContainer.new()
    chip.custom_minimum_size = Vector2(60, 60)
    chip.add_theme_stylebox_override("panel", _panel_style())

    var col := VBoxContainer.new()
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    col.add_theme_constant_override("separation", 2)
    chip.add_child(col)

    var mark_row := HBoxContainer.new()
    mark_row.alignment = BoxContainer.ALIGNMENT_CENTER
    var mark := _swatch(color, 8)
    mark_row.add_child(mark)
    col.add_child(mark_row)

    var top := _label(label_text, 9, INK_TEXT_SOFT)
    top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(top)

    var count := _label("0", 17, INK_TEXT)
    count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(count)

    into.add_child(chip)
    return count

# ------------------------------------------------------------- controls legend

## Bottom-right: compact badge-style key + action rows, grouped movement vs.
## combat/interaction — parchment chrome throughout, no special accent colour
## (a keybind legend isn't a Palette-meaningful concept, so it gets the same
## uniform chrome as everything else).
func _build_controls_legend() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    panel.position = Vector2(-330, -172)
    panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(panel)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 6)
    panel.add_child(outer)

    outer.add_child(_label("Controls", 12, INK_TEXT_SOFT, true))

    var columns := HBoxContainer.new()
    columns.add_theme_constant_override("separation", 18)
    outer.add_child(columns)

    var move_col := VBoxContainer.new()
    move_col.add_theme_constant_override("separation", 3)
    columns.add_child(move_col)
    move_col.add_child(_badge_row("WASD", "Move"))
    move_col.add_child(_badge_row("SHIFT", "Sprint"))
    move_col.add_child(_badge_row("SPACE", "Jump"))
    move_col.add_child(_badge_row("MOUSE", "Look"))
    move_col.add_child(_badge_row("ESC", "Cursor"))

    var act_col := VBoxContainer.new()
    act_col.add_theme_constant_override("separation", 3)
    columns.add_child(act_col)
    act_col.add_child(_badge_row("LMB", "Light atk"))
    act_col.add_child(_badge_row("RMB", "Heavy atk"))
    act_col.add_child(_badge_row("Q", "Lock-on"))
    act_col.add_child(_badge_row("CTRL", "Dodge"))
    act_col.add_child(_badge_row("E", "Gather"))

    var craft_col := VBoxContainer.new()
    craft_col.add_theme_constant_override("separation", 3)
    columns.add_child(craft_col)
    craft_col.add_child(_badge_row("B", "Campfire"))
    craft_col.add_child(_badge_row("C", "Cook"))
    craft_col.add_child(_badge_row("F", "Eat"))

## One "key-badge + action" row — an ink-outlined parchment badge, not a dark
## chip with a saturated border.
func _badge_row(key: String, action: String) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)

    var badge := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = PAPER_RECESS
    sb.corner_radius_top_left = 4
    sb.corner_radius_top_right = 4
    sb.corner_radius_bottom_left = 4
    sb.corner_radius_bottom_right = 4
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_color = INK_LINE
    sb.content_margin_left = 6
    sb.content_margin_right = 6
    sb.content_margin_top = 1
    sb.content_margin_bottom = 1
    badge.add_theme_stylebox_override("panel", sb)
    badge.custom_minimum_size = Vector2(50, 0)
    var key_lab := _label(key, 10, INK_TEXT)
    key_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    badge.add_child(key_lab)
    row.add_child(badge)

    var act_lab := _label(action, 11, INK_TEXT_SOFT)
    row.add_child(act_lab)
    return row

# ------------------------------------------------------------ situational panel

## Top-right: Depth / Hostility / Creatures — the same three real values as
## before, styled consistently with every other panel. Not a minimap (no
## level-layout data exists to draw one).
func _build_situational_panel() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.position = Vector2(-208, 14)
    panel.add_theme_stylebox_override("panel", _panel_style())
    add_child(panel)

    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 6)
    panel.add_child(col)

    col.add_child(_label("Survey", 12, INK_TEXT_SOFT, true))
    _depth_text = _label("Depth: 0.0 m", 12, INK_TEXT)
    col.add_child(_depth_text)
    _hostility_text = _label("Hostility: 0%", 12, INK_TEXT)
    col.add_child(_hostility_text)
    _creatures_text = _label("Creatures: 0", 12, INK_TEXT)
    col.add_child(_creatures_text)

# ------------------------------------------------------------------- process --

func _process(_delta: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return

    if _hp_fill != null:
        var hp_pct := clampf(_player.health / _player.max_health, 0.0, 1.0)
        _hp_fill.size.x = BAR_WIDTH * hp_pct
        if _hp_text != null:
            _hp_text.text = "%d%%" % int(round(hp_pct * 100.0))

    if _player.survival != null:
        if _sta_fill != null:
            var sta_pct := clampf(_player.survival.stamina / _player.survival.max_stamina, 0.0, 1.0)
            _sta_fill.size.x = BAR_WIDTH * sta_pct
            if _sta_text != null:
                _sta_text.text = "%d%%" % int(round(sta_pct * 100.0))
        if _hunger_fill != null:
            var hu_pct := clampf(_player.survival.hunger / _player.survival.max_hunger, 0.0, 1.0)
            _hunger_fill.size.x = BAR_WIDTH * hu_pct
            if _hunger_text != null:
                _hunger_text.text = "%d%%" % int(round(hu_pct * 100.0))

    if _depth_text != null:
        _depth_text.text = "Depth: %.1f m" % maxf(-_player.global_position.y, 0.0)

    if _ecosystem != null:
        if _hostility_text != null:
            _hostility_text.text = "Hostility: %d%%" % int(_ecosystem.global_hostility * 100.0)
        if _creatures_text != null:
            _creatures_text.text = "Creatures: %d" % get_tree().get_nodes_in_group("creatures").size()

    if _lock_label != null:
        if _player.lock_target != null and is_instance_valid(_player.lock_target):
            _lock_label.text = "Locked: %s" % str(_player.lock_target.display_name)
        else:
            _lock_label.text = ""

    _refresh_buff_pills()

    if _status_label != null:
        _status_label.text = _player.status_text

    if _chip_meat != null:
        _chip_meat.text = str(int(_player.inventory.get("raw_meat", 0)))
    if _chip_meals != null:
        _chip_meals.text = str(_player.meals.size())
    if _chip_fruit != null:
        _chip_fruit.text = str(_player.count_category("fruit"))
    if _chip_herb != null:
        _chip_herb.text = str(_player.count_category("herb"))

## Rebuilds the buff-pill row only when the set of active buff types actually
## changed, so we're not tearing down/recreating Controls every single frame.
func _refresh_buff_pills() -> void:
    if _buff_row == null:
        return
    var types: Array = []
    for b in _player.active_buffs:
        types.append(str(b["type"]))
    var key := ", ".join(types)
    if key == _last_buff_key:
        return
    _last_buff_key = key
    for c in _buff_row.get_children():
        c.queue_free()
    for t in types:
        _buff_row.add_child(_make_buff_pill(t))
