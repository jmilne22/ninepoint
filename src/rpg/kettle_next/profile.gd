## Session-only asset selection; never serialized into campaign progress.
class_name KettleNextProfile
extends RefCounted

## Practice opts into the newest models without changing the campaign setting.
static var practice_presentation := false

const PEOPLE := ["player", "wren", "kesh", "tomas"]

static func campaign() -> bool:
    return practice_presentation or OS.get_environment("NINEPOINT_PRESENTATION") == "campaign_next"

static func enabled() -> bool:
    return campaign() or OS.get_environment("NINEPOINT_PRESENTATION") == "kettle_next"

static func has_person(who: String) -> bool:
    return ResourceLoader.exists("%s/%s.glb" % [asset_root(), who]) if campaign() else enabled() and who in PEOPLE

static func asset_root() -> String:
    return "res://art/campaign_next/people" if campaign() else "res://art/kettle_next"

static func face_path(who: String) -> String:
    return "%s/%s_face.png" % [asset_root(), who]

static func table_path() -> String:
    return "res://art/campaign_next/table.glb" if campaign() else "res://art/kettle_next/table.glb" if enabled() else "res://art/table_scene/table.glb"

static func person_path(who: String, fallback: String) -> String:
    return "%s/%s.glb" % [asset_root(), who] if has_person(who) else fallback

static func room_path(map_id: String) -> String:
    if campaign(): return "res://art/campaign_next/maps/%s/room.glb" % map_id
    return "res://art/kettle_next/room.glb" if enabled() and map_id == "de_ketel" else "res://art/expressive_world/maps/%s/room.glb" % map_id

static func prepare_material(original: Material) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = preload("res://src/rpg/kettle_next/cloth.gdshader")
    if original is StandardMaterial3D:
        mat.set_shader_parameter("colour", original.albedo_color)
        mat.set_shader_parameter("fabric", "Cloth" in original.resource_name or "Trouser" in original.resource_name)
    return mat

static var _embedded: Dictionary = {}

static func embedded_texture(name: String, fallback: Texture2D) -> Texture2D:
    if not campaign(): return fallback
    if not _embedded.has(name):
        _embedded[name] = load("res://art/campaign_next/surfaces/%s.png" % name)
    return _embedded[name] as Texture2D
