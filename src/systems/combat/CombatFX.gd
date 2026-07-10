class_name CombatFX
extends RefCounted
## Deepforage — lightweight, self-contained combat feedback: a slash arc for the
## swing and an impact burst where a blow lands. Built in code (no shaders, no
## binary assets); each effect fades + frees itself via a Tween, so callers just
## fire-and-forget. Reusable by the player now and creatures later.
##
## Colours come from Palette tokens (per the studio no-inline-Color rule): a pale
## steel streak for the blade, a warm ember flash for a connect.

## A blade streak at `xform` (world space), oriented along the swing. Plays on
## every swing, connect or whiff.
static func slash(parent: Node3D, xform: Transform3D, color: Color, size := 1.0) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var m := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(1.5 * size, 0.5 * size, 0.05)
    m.mesh = box
    m.material_override = _mat(color)
    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(m)
    m.global_transform = xform
    m.transparency = 0.1
    var tw := m.create_tween()
    tw.tween_property(m, "transparency", 1.0, 0.16)
    tw.parallel().tween_property(m, "scale", Vector3(1.6, 1.25, 1.0), 0.16)
    tw.tween_callback(m.queue_free)

## A bright burst at `position` (world space) when a blow connects.
static func impact(parent: Node3D, position: Vector3, color: Color) -> void:
    if parent == null or not parent.is_inside_tree():
        return
    var m := MeshInstance3D.new()
    var s := SphereMesh.new()
    s.radius = 0.22
    s.height = 0.44
    m.mesh = s
    m.material_override = _mat(color)
    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(m)
    m.global_position = position
    m.scale = Vector3(0.4, 0.4, 0.4)
    m.transparency = 0.0
    var tw := m.create_tween()
    tw.tween_property(m, "scale", Vector3(1.5, 1.5, 1.5), 0.15)
    tw.parallel().tween_property(m, "transparency", 1.0, 0.15)
    tw.tween_callback(m.queue_free)

static func _mat(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 3.2
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat
