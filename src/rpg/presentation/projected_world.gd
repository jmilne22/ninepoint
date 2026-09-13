## Live 3D follows the same projected logical coordinates used by input and saves.
class_name ProjectedWorld
extends Node2D

var world: Node2D
var room: RoomProjection
var view: SubViewport
var camera_3d: Camera3D
var picture: Sprite2D
var people: Dictionary = {}
var seated_identities: Array = []

func setup(owner_world: Node2D) -> void:
    world = owner_world
    room = world.map.presentation
    view = SubViewport.new()
    view.size = Vector2i(768,432)
    view.own_world_3d = true
    view.msaa_3d = Viewport.MSAA_4X
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(view)
    var scenery: Node3D = load(KettleNextProfile.room_path(world.map.id)).instantiate()
    view.add_child(scenery)
    if KettleNextProfile.campaign():
        CampaignNextRoom.setup(view,scenery,world.map.id)
        seated_identities = CampaignNextRoom.seated_identities(world.map.id)
    elif KettleNextProfile.enabled() and world.map.id == "de_ketel":
        KettleNextRoom.setup(view, scenery)
    else:
        ExpressiveSurfaces.apply(scenery)
        ExpressiveSurfaces.environment(view,world.map.indoors)
    camera_3d = Camera3D.new()
    camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera_3d.size = 6.75
    if KettleNextProfile.campaign(): CampaignNextRoom.frame_camera(camera_3d)
    view.add_child(camera_3d)
    picture = Sprite2D.new()
    picture.texture = view.get_texture()
    picture.scale = Vector2.ONE * (384.0 / float(view.size.x))
    picture.z_index = -5
    picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(picture)
    view.size_changed.connect(_fit_picture)
    NativeViewportSize.bind_view(view, self, Vector2(384,216))
    var listener := AudioListener2D.new()
    world.player.add_child(listener)
    listener.make_current()
    world.camera.reparent(self)
    world.camera.position = room.project(world.player.position)
    var pad := (Vector2(384,216)-room.size).max(Vector2.ZERO)/2
    world.camera.limit_left = int(-pad.x)
    world.camera.limit_top = int(-pad.y)
    world.camera.limit_right = int(room.size.x+pad.x)
    world.camera.limit_bottom = int(room.size.y+pad.y)
    _find_people(world.entities)

func _fit_picture() -> void:
    picture.scale = Vector2(384,216) / Vector2(view.size)

func _find_people(node: Node) -> void:
    if node is CharacterSprite and not people.has(node.get_instance_id()):
        var person := ExpressivePerson.new()
        person.identity = node._character_id
        person.source = node
        person.has_seat = person.identity in seated_identities
        people[node.get_instance_id()] = weakref(person)
        view.add_child(person)
        node.hide()
    if node is Tram and not people.has(node.get_instance_id()):
        var vehicle := ExpressiveTramVisual.new()
        vehicle.source = node
        people[node.get_instance_id()] = weakref(vehicle)
        view.add_child(vehicle)
    for child in node.get_children(): _find_people(child)

func _process(_delta: float) -> void:
    if world == null: return
    _find_people(world.entities)
    if world.hud != null: world.hud.set_conversation(world.dialogue != null and world.dialogue.running)
    var lift := 18.0 if world.dialogue != null and world.dialogue.running else -14.0
    world.camera.position = room.project(world.player.global_position)+Vector2(0,lift)
    world.camera.force_update_scroll()
    var centre: Vector2 = world.camera.get_screen_center_position()
    picture.position = centre
    var logical := room.unproject_vector(centre-room.origin)
    var target := Vector3(logical.x*.05,0,logical.y*.05)
    camera_3d.position = target+Vector3(20,16.3299,20)
    camera_3d.look_at(target)
