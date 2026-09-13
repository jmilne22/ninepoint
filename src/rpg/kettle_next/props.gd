## A working prop follows the authored palm; it never changes actor movement.
class_name KettleNextProps
extends RefCounted

static func attach_cloth(model: Node) -> Node3D:
    var skeleton := find_skeleton(model)
    if skeleton == null: return null
    var attachment := BoneAttachment3D.new()
    attachment.bone_name = "hand_R"
    skeleton.add_child(attachment)
    var cloth: Node3D = load("res://art/kettle_next/cloth.glb").instantiate()
    cloth.position = Vector3(0,.065,.008)
    cloth.rotation.x = PI/2.0 + .46
    attachment.add_child(cloth)
    return cloth

static func find_skeleton(node: Node) -> Skeleton3D:
    if node is Skeleton3D: return node
    for child in node.get_children():
        var found := find_skeleton(child)
        if found != null: return found
    return null

static func attach_stone(model: Node, player: bool) -> Node3D:
    var skeleton := find_skeleton(model)
    if skeleton == null: return null
    var attachment := BoneAttachment3D.new()
    attachment.bone_name = "finger0_R" if player else "finger0_L"
    skeleton.add_child(attachment)
    var stone: Node3D = load("res://art/table_scene/black_stone.glb").instantiate()
    stone.position = Vector3(.012,.028,.012)
    stone.rotation.x = PI/2.0
    stone.scale = Vector3.ONE*.58
    attachment.add_child(stone)
    stone.hide()
    return stone
