## Session-only asset selection; never serialized into campaign progress.
class_name KettleNextProfile
extends RefCounted

const PEOPLE := ["player", "wren", "kesh", "tomas"]

static func enabled() -> bool:
    return OS.get_environment("NINEPOINT_PRESENTATION") == "kettle_next"

static func has_person(who: String) -> bool:
    return enabled() and who in PEOPLE

static func person_path(who: String, fallback: String) -> String:
    return "res://art/kettle_next/%s.glb" % who if has_person(who) else fallback

static func room_path(map_id: String) -> String:
    return "res://art/kettle_next/room.glb" if enabled() and map_id == "de_ketel" else "res://art/expressive_world/maps/%s/room.glb" % map_id

static func prepare_material(original: Material) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = preload("res://src/rpg/kettle_next/cloth.gdshader")
    if original is StandardMaterial3D:
        mat.set_shader_parameter("colour", original.albedo_color)
        mat.set_shader_parameter("fabric", "Cloth" in original.resource_name or "Trouser" in original.resource_name)
    return mat
