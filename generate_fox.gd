extends SceneTree

func _init():
    var root = CharacterBody2D.new()
    root.name = "Fox"
    root.add_to_group("enemies")
    root.set_script(load("res://src/Fox.gd"))

    var anim = AnimatedSprite2D.new()
    anim.name = "AnimatedSprite2D"
    var frames = SpriteFrames.new()
    if not frames.has_animation("walk"): frames.add_animation("walk")
    if not frames.has_animation("run"): frames.add_animation("run")
    anim.sprite_frames = frames
    root.add_child(anim)
    anim.owner = root

    var det = Area2D.new()
    det.name = "DetectionArea"
    root.add_child(det)
    det.owner = root

    var col = CollisionShape2D.new()
    col.name = "CollisionShape2D"
    var shape = CircleShape2D.new()
    shape.radius = 150.0
    col.shape = shape
    det.add_child(col)
    col.owner = root

    var body_col = CollisionShape2D.new()
    body_col.name = "CollisionShape2D"
    var body_shape = CapsuleShape2D.new()
    body_shape.radius = 10.0
    body_shape.height = 20.0
    body_col.shape = body_shape
    root.add_child(body_col)
    body_col.owner = root

    var scene = PackedScene.new()
    scene.pack(root)
    ResourceSaver.save(scene, "res://src/Fox.tscn")
    quit()
