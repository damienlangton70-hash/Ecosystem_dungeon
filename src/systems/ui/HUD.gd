class_name HUD
extends CanvasLayer
## Deepforage — the real in-game HUD. Replaces the old placeholder (plain white
## Labels + flat ColorRect bars stacked in the corner) with styled panel chrome:
## rounded-corner StyleBoxFlat panels with a coloured accent edge, colour-swatch
## "icons" next to every stat, chip-styled resource counts, and badge-styled
## controls — the reference image's *information design* translated into
## Deepforage's own established visual language (Palette tokens, monospace
## system font, zero binary assets).
##
## Owns every HUD control node and its own _process(delta) reading live
## player/ecosystem state (this logic used to live in Main.gd's _process()).
## Main.gd just constructs one of these and calls bind() once both _player and
## _ecosystem exist.
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
# old HUD used, just styled).
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

## System font search list — Godot 4 resolves the first installed match at
## runtime and falls back to the engine default font if none are present.
## Zero font files committed, per the no-binary-assets constraint.
static func _mono_font() -> Font:
    var f := SystemFont.new()
    f.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono", "Liberation Mono", "Courier New", "monospace"])
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

## Shared rounded dark panel chrome with a coloured top accent edge — the
## "cold glow / warm ember" identity edge called for in the brief. StyleBoxFlat
## is pure resource data (no image/font files), so this satisfies the
## no-binary-assets constraint outright.
func _panel_style(accent: Color, bg_alpha := 0.62) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.03, 0.035, 0.045, bg_alpha)
    sb.corner_radius_top_left = 10
    sb.corner_radius_top_right = 10
    sb.corner_radius_bottom_left = 10
    sb.corner_radius_bottom_right = 10
    sb.border_width_top = 3
    sb.border_color = accent
    sb.content_margin_left = 14
    sb.content_margin_right = 14
    sb.content_margin_top = 10
    sb.content_margin_bottom = 12
    return sb

## A small square/diamond colour-swatch "icon" standing in for a raster icon —
## extends the existing colour-coded-bar convention the old HUD already used.
func _swatch(color: Color, size := 12) -> ColorRect:
    var r := ColorRect.new()
    r.color = color
    r.custom_minimum_size = Vector2(size, size)
    r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    return r

func _label(text: String, size := 13, color := Color(0.90, 0.92, 0.95)) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_override("font", _mono_font())
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

## Background + fill ColorRect bar pair inside `into`, both fixed to BAR_WIDTH
## so the fill's size.x can be driven by % without touching layout containers.
func _make_bar(into: Control, fill_color: Color, height := 14) -> ColorRect:
    var holder := Control.new()
    holder.custom_minimum_size = Vector2(BAR_WIDTH, height)
    into.add_child(holder)
    var bg := ColorRect.new()
    bg.color = Color(0.0, 0.0, 0.0, 0.55)
    bg.size = Vector2(BAR_WIDTH, height)
    holder.add_child(bg)
    var fill := ColorRect.new()
    fill.color = fill_color
    fill.size = Vector2(BAR_WIDTH, height)
    holder.add_child(fill)
    return fill

# ---------------------------------------------------------------- vitals ------

## Top-left: floor title + HP / STA / HUNGER bars, each with a distinct colour
## identity so the three read apart at a glance (the single most "does this
## look intentional" element per the brief).
func _build_vitals_panel() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 14)
    panel.add_theme_stylebox_override("panel", _panel_style(Palette.GLOW_TEAL))
    add_child(panel)

    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 7)
    panel.add_child(col)

    var title := _label("DEEPFORAGE", 14, Color(0.85, 0.92, 0.90))
    col.add_child(title)
    var subtitle := _label("Floor 1 · The Fungal Shallows", 11, Color(0.55, 0.65, 0.62))
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
    # HUNGER — FLAME (the one warm light in the world); distinct from both
    # WARN (redder/hotter) and GLOW_TEAL (cold) so all three separate cleanly.
    var hunger_parts := _stat_row("HUNGER", Palette.FLAME)
    col.add_child(hunger_parts[0])
    _hunger_fill = hunger_parts[1]
    _hunger_text = hunger_parts[2]

## One "swatch + label + bar + trailing %/count text" row, matching the
## reference image's icon-coded-bar layout. Returns [row, fill, pct_label] so
## the caller can wire the fill/label to its own member vars.
func _stat_row(label_text: String, color: Color) -> Array:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    row.add_child(_swatch(color))
    var lab := _label(label_text, 12)
    lab.custom_minimum_size = Vector2(52, 0)
    row.add_child(lab)
    var fill := _make_bar(row, color)
    var pct := _label("100%", 12, Color(0.80, 0.84, 0.86))
    pct.custom_minimum_size = Vector2(44, 0)
    pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    row.add_child(pct)
    return [row, fill, pct]

# ------------------------------------------------------------- status cluster -

## Just below the vitals panel: lock-on target, active buff chips, and the
## transient status_text feedback line. Plainer/no chrome since these are
## secondary and transient, per the brief.
func _build_status_cluster() -> void:
    var col := VBoxContainer.new()
    col.position = Vector2(16, 138)
    col.add_theme_constant_override("separation", 5)
    add_child(col)

    _lock_label = _label("", 12, Palette.WARN)
    col.add_child(_lock_label)

    _buff_row = HBoxContainer.new()
    _buff_row.add_theme_constant_override("separation", 6)
    col.add_child(_buff_row)

    _status_label = _label("", 12, Color(1.0, 0.92, 0.68))
    col.add_child(_status_label)

## One small rounded pill per active buff type (not a comma-joined sentence).
func _make_buff_pill(buff_type: String) -> PanelContainer:
    var pill := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.10, 0.22, 0.20, 0.85)
    sb.corner_radius_top_left = 8
    sb.corner_radius_top_right = 8
    sb.corner_radius_bottom_left = 8
    sb.corner_radius_bottom_right = 8
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_color = Palette.GLOW_FUNGUS
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 2
    sb.content_margin_bottom = 2
    pill.add_theme_stylebox_override("panel", sb)
    pill.add_child(_label(buff_type.capitalize(), 11, Palette.GLOW_FUNGUS))
    return pill

# ------------------------------------------------------------ provisions row --

## Bottom-left: 4 slot-chip panels (Raw Meat / Meals / Fruit / Herbs), each a
## real bound count — the hotbar-style translation of the reference image's
## item slots, honestly sized to the 4 real resources Deepforage tracks today.
func _build_provisions_row() -> void:
    var row := HBoxContainer.new()
    row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    row.position = Vector2(16, -84)
    row.add_theme_constant_override("separation", 8)
    add_child(row)

    _chip_meat = _add_chip(row, "MEAT", Palette.EMBER)
    _chip_meals = _add_chip(row, "MEALS", Palette.FLAME)
    _chip_fruit = _add_chip(row, "FRUIT", Palette.ingredient_color("bleedberry"))
    _chip_herb = _add_chip(row, "HERBS", Palette.ingredient_color("stoneleaf"))

## One 60x60 slot chip: coloured top border matching the resource, a short
## label, and a large count Label — returns the count Label to update later.
func _add_chip(into: Control, label_text: String, color: Color) -> Label:
    var chip := PanelContainer.new()
    chip.custom_minimum_size = Vector2(60, 60)
    chip.add_theme_stylebox_override("panel", _panel_style(color, 0.70))

    var col := VBoxContainer.new()
    col.alignment = BoxContainer.ALIGNMENT_CENTER
    col.add_theme_constant_override("separation", 2)
    chip.add_child(col)

    var top := _label(label_text, 9, Color(0.68, 0.72, 0.74))
    top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(top)

    var count := _label("0", 18, Color(0.94, 0.95, 0.97))
    count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    col.add_child(count)

    into.add_child(chip)
    return count

# ------------------------------------------------------------- controls legend

## Bottom-right: compact badge-style key + action rows, grouped movement vs.
## combat/interaction, replacing the two dense help sentences. Every current
## binding is present (WASD, Shift, Space, Mouse, Esc, LMB, RMB, Q, Ctrl, E, B,
## C, F) — none dropped, just legible and grouped.
func _build_controls_legend() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    panel.position = Vector2(-330, -172)
    panel.add_theme_stylebox_override("panel", _panel_style(Palette.GLOW_VIOLET, 0.60))
    add_child(panel)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 6)
    panel.add_child(outer)

    outer.add_child(_label("CONTROLS", 11, Color(0.62, 0.60, 0.72)))

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

## One "key-badge + action" row.
func _badge_row(key: String, action: String) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)

    var badge := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.14, 0.13, 0.17, 0.9)
    sb.corner_radius_top_left = 5
    sb.corner_radius_top_right = 5
    sb.corner_radius_bottom_left = 5
    sb.corner_radius_bottom_right = 5
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_color = Palette.GLOW_VIOLET
    sb.content_margin_left = 6
    sb.content_margin_right = 6
    sb.content_margin_top = 1
    sb.content_margin_bottom = 1
    badge.add_theme_stylebox_override("panel", sb)
    badge.custom_minimum_size = Vector2(50, 0)
    var key_lab := _label(key, 10, Color(0.85, 0.82, 0.92))
    key_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    badge.add_child(key_lab)
    row.add_child(badge)

    var act_lab := _label(action, 11, Color(0.78, 0.79, 0.80))
    row.add_child(act_lab)
    return row

# ------------------------------------------------------------ situational panel

## Top-right: Depth / Hostility / Creatures — the same three real values the
## old plain-Label readout showed, styled consistently with the vitals panel.
## Deliberately NOT a minimap (no level-layout data exists to draw one); this
## is the honest data-readout equivalent in the same screen corner the
## reference image reserves for its minimap.
func _build_situational_panel() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.position = Vector2(-208, 14)
    panel.add_theme_stylebox_override("panel", _panel_style(Palette.GLOW_BLUE))
    add_child(panel)

    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 6)
    panel.add_child(col)

    col.add_child(_label("SURVEY", 11, Color(0.55, 0.65, 0.75)))
    _depth_text = _label("Depth: 0.0 m", 12)
    col.add_child(_depth_text)
    _hostility_text = _label("Hostility: 0%", 12)
    col.add_child(_hostility_text)
    _creatures_text = _label("Creatures: 0", 12)
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
            _lock_label.text = "LOCKED: %s" % str(_player.lock_target.display_name)
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
