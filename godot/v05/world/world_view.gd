class_name V5WorldView
extends Control

signal tile_tapped(tile: Vector2i)

const PARTY_ATLAS: Texture2D = preload("res://v03/assets/party.png")
var world: V5WorldState
var _tile_size: float = 42.0
var _offset: Vector2 = Vector2.ZERO
var _blink_timer: Timer
var _blink: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    custom_minimum_size = Vector2(0, 490)
    resized.connect(queue_redraw)
    _blink_timer = Timer.new()
    _blink_timer.wait_time = 0.5
    add_child(_blink_timer)
    _blink_timer.timeout.connect(_animate_marker)
    _blink_timer.start()

func _animate_marker() -> void:
    _blink = not _blink
    queue_redraw()

func set_world(next_world: V5WorldState) -> void:
    world = next_world
    queue_redraw()

func _dimensions() -> void:
    if world == null:
        return
    _tile_size = minf(size.x / float(V5WorldState.MAP_SIZE.x), size.y / float(V5WorldState.MAP_SIZE.y))
    _offset = (size - Vector2(V5WorldState.MAP_SIZE) * _tile_size) / 2.0

func _draw() -> void:
    if world == null:
        return
    _dimensions()
    draw_rect(Rect2(Vector2.ZERO, size), Color("#0b1826"))
    for y: int in range(V5WorldState.MAP_SIZE.y):
        for x: int in range(V5WorldState.MAP_SIZE.x):
            var tile: Vector2i = Vector2i(x, y)
            var place: Vector2 = _offset + Vector2(tile) * _tile_size
            var rect: Rect2 = Rect2(place, Vector2.ONE * _tile_size)
            var ground: String = world.terrain(tile)
            var color: Color = Color("#447348") if (x + y) % 2 == 0 else Color("#3d6945")
            match ground:
                "wall": color = Color("#182d36")
                "stone": color = Color("#727b7e")
                "water": color = Color("#276a8b")
                "tree": color = Color("#1b4a34")
            draw_rect(rect, color)
            if ground == "tree":
                draw_circle(place + Vector2.ONE * _tile_size * 0.5, _tile_size * 0.31, Color("#2b8450"))
                draw_circle(place + Vector2(_tile_size * 0.4, _tile_size * 0.4), _tile_size * 0.19, Color("#5baf64"))
            elif ground == "stone":
                draw_rect(Rect2(place + Vector2.ONE * _tile_size * 0.15, Vector2.ONE * _tile_size * 0.7), Color("#a5a99f"))
            elif ground == "water":
                draw_line(place + Vector2(_tile_size*0.1, _tile_size*0.55), place + Vector2(_tile_size*0.8,_tile_size*0.55), Color("#6cbfce"), 2.0)
            elif ground == "grass" and (x + y) % 5 == 0:
                draw_circle(place + Vector2(_tile_size*0.8,_tile_size*0.7), 2.0, Color("#b7bc71"))
            draw_rect(rect, Color("#122e2c",0.18), false, 1.0)
    _draw_markers()
    var player_place: Vector2 = _offset + Vector2(world.player) * _tile_size
    draw_circle(player_place + Vector2(_tile_size*0.5, _tile_size*0.83), _tile_size*0.29, Color("#101e2a",0.55))
    draw_texture_rect_region(PARTY_ATLAS, Rect2(player_place.x + _tile_size*0.12, player_place.y - _tile_size*0.1, _tile_size*0.76, _tile_size*1.06), Rect2(0,0,48,48), Color.WHITE)
    draw_rect(Rect2(_offset, Vector2(V5WorldState.MAP_SIZE)*_tile_size), Color("#e0bd74",0.6), false, 3.0)

func _draw_markers() -> void:
    var elder: Vector2 = _offset + Vector2(V5WorldState.ELDER) * _tile_size
    _icon(elder, Color("#c59af1"), "!")
    var chest: Vector2 = _offset + Vector2(V5WorldState.CHEST)*_tile_size
    if not world.chest_opened:
        _icon(chest, Color("#e2bb6a"), "$")
    for id: String in V5WorldState.ENCOUNTERS.keys():
        if bool(world.cleared[id]):
            continue
        var at: Vector2 = _offset + Vector2(V5WorldState.ENCOUNTERS[id]) * _tile_size
        var tint: Color = Color("#f15e56") if id == "boss" else Color("#ffa776")
        _icon(at, tint, "!" if id == "boss" else "X")

func _icon(at: Vector2, tint: Color, shape: String) -> void:
    var center: Vector2 = at + Vector2.ONE * _tile_size * 0.5
    draw_circle(center, _tile_size * (0.37 if _blink else 0.33), tint)
    if shape == "X":
        draw_line(center-Vector2.ONE*_tile_size*0.15,center+Vector2.ONE*_tile_size*0.15,Color("#212337"),3.0)
        draw_line(center+Vector2(-_tile_size*0.15,_tile_size*0.15),center+Vector2(_tile_size*0.15,-_tile_size*0.15),Color("#212337"),3.0)
    elif shape == "!":
        draw_line(center + Vector2(0,-_tile_size*0.16),center+Vector2(0,_tile_size*0.06),Color("#27283e"),3.0)
        draw_circle(center+Vector2(0,_tile_size*0.19),1.7,Color("#27283e"))
    elif shape == "$":
        draw_rect(Rect2(center-Vector2.ONE*_tile_size*0.11, Vector2.ONE*_tile_size*0.22),Color("#644621"))

func _gui_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return
    if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed or world == null:
        return
    _dimensions()
    var local: Vector2 = (event.position - _offset) / _tile_size
    var tile: Vector2i = Vector2i(floori(local.x),floori(local.y))
    if tile.x >= 0 and tile.y >= 0 and tile.x < V5WorldState.MAP_SIZE.x and tile.y < V5WorldState.MAP_SIZE.y:
        tile_tapped.emit(tile)
        accept_event()
