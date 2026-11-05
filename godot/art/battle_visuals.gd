class_name BattleVisuals
extends Control

var _sprites: Dictionary = {}
var _rests: Dictionary = {}
var _queue: Array[Dictionary] = []
var _playing: bool = false
var _pulse_timer: Timer

func _ready() -> void:
    custom_minimum_size = Vector2(0, 355)
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _new_sprite("hero", preload("res://art/warden.svg"))
    _new_sprite("companion", preload("res://art/mira.svg"))
    _new_sprite("foe", preload("res://art/ashfang.svg"))
    resized.connect(_position_sprites)
    _position_sprites()
    _pulse_timer = Timer.new()
    _pulse_timer.wait_time = 0.85
    add_child(_pulse_timer)
    _pulse_timer.timeout.connect(_idle_tick)
    _pulse_timer.start()

func _new_sprite(actor_id: String, source: Texture2D) -> void:
    var sprite := Sprite2D.new()
    sprite.texture = source
    sprite.hframes = 4
    sprite.frame = 0
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale = Vector2(1.65, 1.65) if actor_id != "foe" else Vector2(2.25, 2.25)
    add_child(sprite)
    _sprites[actor_id] = sprite

func _position_sprites() -> void:
    if _sprites.size() < 3:
        return
    var w: float = size.x
    var h: float = size.y
    _rests = {
        "hero": Vector2(w * 0.19, h * 0.72),
        "companion": Vector2(w * 0.42, h * 0.76),
        "foe": Vector2(w * 0.78, h * 0.55)
    }
    for actor_id: String in _sprites.keys():
        var sprite: Sprite2D = _sprites[actor_id]
        if not _playing:
            sprite.position = _rests[actor_id]
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    draw_rect(Rect2(Vector2.ZERO, size), Color("#10243b"))
    draw_rect(Rect2(Vector2(0, h * 0.53), Vector2(w, h * 0.47)), Color("#30434a"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,h*0.60),Vector2(w*0.17,h*0.22),Vector2(w*0.38,h*0.62)]), Color("#1c3447"))
    draw_colored_polygon(PackedVector2Array([Vector2(w*0.19,h*0.62),Vector2(w*0.59,h*0.13),Vector2(w*0.96,h*0.62)]), Color("#1b3144"))
    draw_colored_polygon(PackedVector2Array([Vector2(w*0.60,h*0.64),Vector2(w*0.91,h*0.28),Vector2(w,h*0.60)]), Color("#243c4a"))
    draw_line(Vector2(0,h*0.69),Vector2(w,h*0.69),Color("#53645e"),3.0)
    for i: int in range(8):
        var y: float = h * (0.72 + float(i) * 0.039)
        draw_line(Vector2(0,y),Vector2(w,y),Color("#455657",0.6),1.0)
    for i: int in range(9):
        var x: float = float(i) * w / 8.0
        draw_line(Vector2(x,h*0.72),Vector2(w*0.5+(x-w*0.5)*1.6,h),Color("#455657",0.45),1.0)
    for i: int in range(19):
        var x: float = float((i*97 + 19)%997) / 997.0 * w
        var y: float = float((i*79 + 11)%71) / 100.0 * h
        draw_circle(Vector2(x,y),1.6,Color("#b7dcea",0.7))
    draw_rect(Rect2(Vector2.ZERO, size),Color("#d9b677",0.55),false,2.0)

func _idle_tick() -> void:
    if _playing:
        return
    for actor_id: String in _sprites.keys():
        var sprite: Sprite2D = _sprites[actor_id]
        sprite.frame = 0
        sprite.position.y = float(_rests[actor_id].y) + (1.5 if _pulse_timer.wait_time > 0.0 else 0.0)

func sync_state(view: Dictionary) -> void:
    if _sprites.is_empty():
        return
    for actor_id: String in _sprites.keys():
        var data: Dictionary = view["foe"] if actor_id == "foe" else (view["hero"] if actor_id == "hero" else view["companion"])
        var sprite: Sprite2D = _sprites[actor_id]
        sprite.modulate.a = 1.0 if int(data["hp"]) > 0 else 0.35

func play_event(event: Dictionary) -> void:
    _queue.append(event.duplicate())
    if not _playing:
        call_deferred("_run_next")

func _run_next() -> void:
    if _playing or _queue.is_empty() or not is_inside_tree():
        return
    _playing = true
    var event: Dictionary = _queue.pop_front()
    var kind: String = str(event.get("kind", "attack"))
    var source_id: String = str(event.get("source", "hero"))
    var target_id: String = str(event.get("target", "foe"))
    if not _sprites.has(source_id) or not _sprites.has(target_id):
        _playing = false
        return
    var source: Sprite2D = _sprites[source_id]
    var target: Sprite2D = _sprites[target_id]
    source.frame = 2 if kind in ["ember","frost","mend","potion"] else 1
    var original: Vector2 = _rests[source_id]
    var toward: Vector2 = (target.position - original).normalized() * 19.0
    var effect_color: Color = Color("#ffd275")
    if kind == "frost":
        effect_color = Color("#74e4ff")
    elif kind == "ember":
        effect_color = Color("#ff783a")
    elif kind in ["mend","potion"]:
        effect_color = Color("#85f0aa")
    elif kind == "special":
        effect_color = Color("#a88fff")
    elif kind == "guard":
        effect_color = Color("#b7d4ff")
    var spark: Node2D = _burst(effect_color, target.position if kind != "guard" else source.position)
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(source, "position", original + toward, 0.13).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(spark, "scale", Vector2(3.8, 3.8), 0.36)
    tween.tween_property(spark, "modulate:a", 0.0, 0.36)
    if kind not in ["guard", "potion", "mend"]:
        target.frame = 3
        tween.tween_property(target, "modulate", Color("#ffac9a"), 0.12)
    await tween.finished
    if not is_instance_valid(source) or not is_inside_tree():
        return
    source.position = original
    source.frame = 0
    target.frame = 0
    target.modulate = Color.WHITE
    if is_instance_valid(spark):
        spark.queue_free()
    _playing = false
    if not _queue.is_empty():
        call_deferred("_run_next")

func _burst(tint: Color, location: Vector2) -> Node2D:
    var node := Node2D.new()
    node.position = location
    node.z_index = 12
    add_child(node)
    var points := PackedVector2Array()
    for i: int in range(14):
        var angle: float = float(i) * TAU / 14.0
        points.append(Vector2(cos(angle),sin(angle))*13.0)
    var flash := Polygon2D.new()
    flash.polygon = points
    flash.color = Color(tint.r,tint.g,tint.b,0.38)
    node.add_child(flash)
    var circle := Line2D.new()
    circle.points = points
    circle.closed = true
    circle.width = 2.8
    circle.default_color = tint
    node.add_child(circle)
    for i: int in range(4):
        var ray := Line2D.new()
        var angle: float = float(i) * PI / 2.0
        ray.points = PackedVector2Array([Vector2(cos(angle),sin(angle))*8.0,Vector2(cos(angle),sin(angle))*21.0])
        ray.width = 2.0
        ray.default_color = tint
        node.add_child(ray)
    return node
