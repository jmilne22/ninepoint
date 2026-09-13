extends RefCounted

static func run(t: TestKit) -> void:
    var view := SubViewport.new()
    var logical := Vector2(768,300)
    for scale in [1,2]:
        view.size = Vector2i(logical)*scale
        for point in [Vector2.ZERO,Vector2(767,299),Vector2(384,150),Vector2(17.5,98.25)]:
            var pixel := TableSceneStage.to_pixels(view,logical,point)
            t.ok(TableSceneStage.to_logical(view,logical,pixel).is_equal_approx(point),"viewport conversion round trip")
    view.free()
    var prior := OS.get_environment("NINEPOINT_PRESENTATION")
    OS.set_environment("NINEPOINT_PRESENTATION","campaign_next")
    t.ok(KettleNextProfile.campaign(),"campaign preview is selected only for this process")
    for who in ["player","sunny","marguerite","extra_kid"]:
        t.ok(KettleNextProfile.has_person(who),"campaign rig exists for "+who)
    OS.set_environment("NINEPOINT_PRESENTATION","kettle_next")
    t.ok(not KettleNextProfile.has_person("hana"),"Kettle launcher retains its original scope")
    t.eq(KettleNextProfile.table_path(),"res://art/kettle_next/table.glb","Kettle table preserved")
    OS.set_environment("NINEPOINT_PRESENTATION","")
    t.eq(KettleNextProfile.table_path(),"res://art/table_scene/table.glb","production table unchanged")
    OS.set_environment("NINEPOINT_PRESENTATION",prior)
