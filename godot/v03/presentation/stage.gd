class_name V3Stage
extends Control

signal unit_tapped(id: String)

const PARTY_TEX: Texture2D = preload("res://v03/assets/party.png")
const EFFECTS_TEX: Texture2D = preload("res://v03/assets/effects.png")
const BOSS_TEX: Texture2D = preload("res://art/ashfang.svg")

var sprites: Dictionary = {}
var hotspots: Dictionary = {}
var nameplates: Dictionary = {}
var bars: Dictionary = {}
var positions: Dictionary = {}
var selectable: Array[String] = []
var _events: Array[Dictionary] = []
var _running: bool = false
var _latest: Dictionary = {}

func _ready() -> void:
    custom_minimum_size = Vector2(0, 570)
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_PASS
    for id: String in ["warden", "mira", "lyra", "kestrel", "ashfang", "raider", "shaman"]:
        var sprite := Sprite2D.new()
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        if id == "ashfang":
            sprite.texture = BOSS_TEX
            sprite.hframes = 4
            sprite.scale = Vector2(2.0,2.0)
        else:
            sprite.texture = PARTY_TEX
            sprite.hframes = 4
            sprite.vframes = 4
            var row: int = 0
            match id:
                "warden": row = 0
                "mira": row = 1
                "lyra": row = 3
                "kestrel", "raider": row = 2
                "shaman": row = 3
            sprite.frame_coords = Vector2i(0,row)
            sprite.scale = Vector2(2.4,2.4) if id in ["warden","mira","lyra","kestrel"] else Vector2(2.1,2.1)
        if id in ["raider", "shaman"]:
            sprite.modulate = Color("#f0a599") if id == "raider" else Color("#b08feb")
        add_child(sprite)
        sprites[id] = sprite
        var label := Label.new()
        label.add_theme_font_size_override("font_size",18)
        label.add_theme_color_override("font_color", Color.WHITE)
        label.add_theme_color_override("font_shadow_color",Color.BLACK)
        label.add_theme_constant_override("shadow_offset_x",2)
        label.add_theme_constant_override("shadow_offset_y",2)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        add_child(label)
        nameplates[id] = label
        var health_bar := ProgressBar.new()
        health_bar.show_percentage = false
        health_bar.custom_minimum_size = Vector2(95,8)
        add_child(health_bar)
        bars[id] = health_bar
        var hot := Button.new()
        hot.flat = true
        hot.mouse_filter = Control.MOUSE_FILTER_STOP
        hot.visible = false
        add_child(hot)
        hot.pressed.connect(_on_unit_tapped.bind(id))
        hotspots[id] = hot
    resized.connect(_layout_characters)
    _layout_characters()

func _layout_characters() -> void:
    var w: float = size.x
    var h: float = size.y
    positions = {
        "ashfang": Vector2(w*0.22,h*0.40),
        "raider": Vector2(w*0.17,h*0.76),
        "shaman": Vector2(w*0.43,h*0.75),
        "warden": Vector2(w*0.80,h*0.26),
        "mira": Vector2(w*0.72,h*0.43),
        "lyra": Vector2(w*0.81,h*0.61),
        "kestrel": Vector2(w*0.70,h*0.79)
    }
    for id: String in positions.keys():
        var at: Vector2 = positions[id]
        var sprite: Sprite2D = sprites[id]
        if not _running:
            sprite.position = at
        var hot: Button = hotspots[id]
        hot.position = at-Vector2(59,61)
        hot.size = Vector2(118,128)
        var label: Label = nameplates[id]
        label.position = at+Vector2(-67,62)
        label.size = Vector2(134,28)
        var bar: ProgressBar = bars[id]
        bar.position = at+Vector2(-47,90)
        bar.size = Vector2(95,8)
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    draw_rect(Rect2(Vector2.ZERO, size), Color("#152636"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,h*0.55),Vector2(w*0.18,h*0.1),Vector2(w*0.38,h*0.55)]),Color("#213d46"))
    draw_colored_polygon(PackedVector2Array([Vector2(w*0.21,h*0.58),Vector2(w*0.50,h*0.06),Vector2(w*0.83,h*0.59)]),Color("#29404c"))
    draw_colored_polygon(PackedVector2Array([Vector2(w*0.60,h*0.56),Vector2(w*0.94,h*0.17),Vector2(w,h*0.45)]),Color("#26394e"))
    draw_rect(Rect2(Vector2(0,h*0.56),Vector2(w,h*0.44)),Color("#4c5846"))
    for i: int in range(13):
        var y: float = h*(0.57+float(i)*0.037)
        draw_line(Vector2(0,y),Vector2(w,y),Color("#73816c",0.35),1.6)
    for i: int in range(9):
        var x: float = float(i)*w/8.0
        draw_line(Vector2(x,h*0.55),Vector2(w*0.5+(x-w*0.5)*1.5,h),Color("#263e3f",0.42),1.5)
    for i: int in range(22):
        var x: float = float((i*191+37)%991)/991.0*w
        var y: float = float((i*83+13)%47)/100.0*h
        draw_circle(Vector2(x,y),1.9,Color("#bfdfeb",0.64))
    for id: String in selectable:
        if positions.has(id):
            draw_arc(positions[id]+Vector2(0,60),57,0.0,TAU,32,Color("#ffda78"),3.5)
    draw_rect(Rect2(Vector2.ZERO,size),Color("#a8c3bf",0.40),false,2.0)

func _on_unit_tapped(id: String) -> void:
    if selectable.has(id):
        unit_tapped.emit(id)

func set_targetable(ids: Array[String]) -> void:
    selectable = ids.duplicate()
    for id: String in hotspots.keys():
        var hot: Button = hotspots[id]
        hot.visible = ids.has(id)
    queue_redraw()

func refresh(snapshot: Dictionary) -> void:
    _latest = snapshot
    for unit: Dictionary in snapshot.get("actors",[]):
        var id: String = str(unit["id"])
        if not sprites.has(id):
            continue
        nameplates[id].text = "%s  %d/%d" % [str(unit["name"]),int(unit["hp"]),int(unit["max_hp"])]
        var health_bar: ProgressBar = bars[id]
        health_bar.max_value = float(unit["max_hp"])
        health_bar.value = float(unit["hp"])
        var sprite: Sprite2D = sprites[id]
        if int(unit["hp"]) <= 0:
            sprite.modulate.a = 0.28
        else:
            sprite.modulate.a = 1.0

func show_action(event: Dictionary) -> void:
    _events.append(event.duplicate())
    if not _running:
        call_deferred("_animate_next")

func _animate_next() -> void:
    if _running or _events.is_empty() or not is_inside_tree():
        return
    _running = true
    var e: Dictionary = _events.pop_front()
    var source_id: String = str(e.get("source", ""))
    var target_id: String = str(e.get("target", ""))
    if not sprites.has(source_id) or not sprites.has(target_id):
        _running = false
        return
    var kind: String = str(e.get("kind","attack"))
    var attacker: Sprite2D = sprites[source_id]
    var victim: Sprite2D = sprites[target_id]
    var target_at: Vector2 = positions[target_id]
    var start: Vector2 = positions[source_id]
    if source_id == "ashfang":
        attacker.frame = 2
    else:
        attacker.frame_coords = Vector2i(2 if kind in ["ember","frost","mend","potion"] else 1,attacker.frame_coords.y)
    var fx := Sprite2D.new()
    fx.texture = EFFECTS_TEX
    fx.hframes = 6
    match kind:
        "attack": fx.frame = 4
        "arc": fx.frame = 0
        "ember": fx.frame = 2
        "frost": fx.frame = 1
        "mend", "potion": fx.frame = 3
        "guard": fx.frame = 5
    fx.position = target_at
    fx.modulate.a = 0.95
    fx.z_index = 10
    fx.scale = Vector2(0.25,0.25)
    var fx_blend := CanvasItemMaterial.new()
    fx_blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    fx.material = fx_blend
    add_child(fx)
    var fly := Label.new()
    fly.text = "%s%d" % ["+" if bool(e.get("healing",false)) else "-",int(e.get("amount",0))]
    if kind == "guard":
        fly.text = "GUARD"
    fly.add_theme_font_size_override("font_size",30)
    fly.add_theme_color_override("font_color",Color("#83ffc4") if bool(e.get("healing",false)) else Color("#ffe0a5"))
    fly.position = target_at+Vector2(-20,-65)
    fly.z_index = 12
    add_child(fly)
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(attacker,"position",start+(target_at-start).normalized()*19.0,0.18)
    tween.tween_property(fx,"scale",Vector2(2.35,2.35),0.40)
    tween.tween_property(fx,"modulate:a",0.0,0.43)
    tween.tween_property(fly,"position:y",fly.position.y-52,0.50)
    tween.tween_property(fly,"modulate:a",0.0,0.5)
    if kind not in ["guard","mend","potion"]:
        tween.tween_property(victim,"modulate",Color("#ff8878"),0.18)
    await tween.finished
    if is_instance_valid(fx):
        fx.queue_free()
    if is_instance_valid(fly):
        fly.queue_free()
    if not is_inside_tree():
        return
    attacker.position = start
    if source_id == "ashfang":
        attacker.frame = 0
    else:
        attacker.frame_coords = Vector2i(0,attacker.frame_coords.y)
    victim.modulate = Color.WHITE
    if not _latest.is_empty():
        refresh(_latest)
    _running = false
    if not _events.is_empty():
        call_deferred("_animate_next")
