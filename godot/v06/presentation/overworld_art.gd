class_name V6OverworldArt
extends V5WorldView

# All biome tiles, scenery, lighting, buildings and icons are original runtime
# vector/pixel illustrations. They are drawn only on world/state changes.
const COLORS: Array[Dictionary] = [
    {"grass": "#507b50", "accent": "#87a960", "path": "#d1ae72",
     "sky": "#15384c", "tree": "#286f41", "water": "#327c9d", "spark": "#f9dd90"},
    {"grass": "#a9c6d1", "accent": "#dff0ed", "path": "#9ba9bd",
     "sky": "#1c3454", "tree": "#5375a6", "water": "#7ac5d8", "spark": "#e0c4ff"},
    {"grass": "#665373", "accent": "#9a719f", "path": "#b68076",
     "sky": "#281b49", "tree": "#514174", "water": "#cc5d56", "spark": "#ffb17d"}
]

func _draw() -> void:
    if world == null:
        return
    _dimensions()
    var chapter: int = (world as V6ZoneWorld).chapter if world is V6ZoneWorld else 0
    var pal: Dictionary = COLORS[chapter]
    draw_rect(Rect2(Vector2.ZERO, size), Color(pal["sky"]))
    var dim: Vector2 = Vector2.ONE * _tile_size
    for y: int in range(V5WorldState.MAP_SIZE.y):
        for x: int in range(V5WorldState.MAP_SIZE.x):
            var tile: Vector2i = Vector2i(x, y)
            var at: Vector2 = _offset + Vector2(tile) * _tile_size
            var kind: String = world.terrain(tile)
            var tinted: Color = Color(pal["grass"])
            if (x + y) % 2 == 0:
                tinted = tinted.lightened(0.07)
            match kind:
                "wall": tinted = Color(pal["sky"]).darkened(0.22)
                "water", "ice", "lava": tinted = Color(pal["water"])
                "stone": tinted = Color(pal["path"])
                "tree", "crystal", "spire": tinted = Color(pal["grass"]).darkened(0.17)
            draw_rect(Rect2(at, dim), tinted)
            if kind in ["grass","snow","ash"]:
                _draw_ground_details(x, y, at, dim, pal, chapter)
            elif kind in ["tree", "crystal", "spire"]:
                _draw_tree(at, dim, pal, chapter)
            elif kind in ["water", "ice", "lava"]:
                _draw_water(at, dim, pal, chapter, x+y)
            elif kind == "stone":
                _draw_road(at, dim, pal, x+y)
            if kind == "wall":
                draw_rect(Rect2(at + dim*0.1, dim*0.8), Color(pal["sky"]).lightened(0.10))
    _draw_landmarks(pal)
    var foot: Vector2 = _offset + Vector2(world.player) * _tile_size
    draw_ellipse(foot + Vector2(_tile_size*0.5,_tile_size*0.82),_tile_size*0.30,_tile_size*0.13,Color("#14212a",0.60))
    draw_texture_rect_region(PARTY_ATLAS,
        Rect2(foot.x+_tile_size*0.05, foot.y-_tile_size*0.10, _tile_size*0.90,_tile_size*1.03),
        Rect2(0,0,48,48), Color.WHITE)
    draw_rect(Rect2(_offset,Vector2(V5WorldState.MAP_SIZE)*_tile_size),
        Color("#e6c684",0.65),false,3.0)

func draw_ellipse(pos: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
    var pts := PackedVector2Array()
    for i: int in range(16):
        var angle: float = float(i)*TAU/16.0
        pts.append(pos+Vector2(cos(angle)*radius_x,sin(angle)*radius_y))
    draw_colored_polygon(pts,color)

func _draw_ground_details(x: int, y: int, at: Vector2, dim: Vector2, pal: Dictionary, chapter: int) -> void:
    var seed: int = (x * 73 + y * 137 + chapter * 91) % 17
    if seed < 4:
        draw_line(at+dim*Vector2(0.25,0.72),at+dim*Vector2(0.18,0.48),Color(pal["accent"]),1.5)
        draw_line(at+dim*Vector2(0.25,0.72),at+dim*Vector2(0.36,0.53),Color(pal["accent"]),1.5)
        draw_circle(at+dim*Vector2(0.29,0.44),dim.x*0.045,Color(pal["spark"]))
    if seed == 8 or seed == 12:
        draw_circle(at+dim*Vector2(0.7,0.67),dim.x*0.08,Color(pal["accent"],0.60))
        draw_circle(at+dim*Vector2(0.68,0.66),dim.x*0.025,Color("#ffffff",0.8))
    draw_rect(Rect2(at,dim),Color(pal["sky"],0.12),false,0.6)

func _draw_tree(at: Vector2, dim: Vector2, pal: Dictionary, chapter: int) -> void:
    var center: Vector2 = at+dim*0.5
    draw_ellipse(center+Vector2(0,dim.y*0.33),dim.x*0.25,dim.y*0.08,Color("#0b1823",0.4))
    if chapter == 0:
        draw_rect(Rect2(center.x-dim.x*0.08,center.y,dim.x*0.16,dim.y*0.36),Color("#664d3c"))
        draw_circle(center-Vector2(0,dim.y*0.13),dim.x*0.31,Color(pal["tree"]))
        draw_circle(center+Vector2(-dim.x*0.14,-dim.y*0.19),dim.x*0.20,Color("#62a46a"))
        draw_circle(center+Vector2(dim.x*0.17,-dim.y*0.23),dim.x*0.15,Color("#80b26d"))
    else:
        var spikes := PackedVector2Array([
            center+Vector2(0,-dim.y*0.42),
            center+Vector2(dim.x*0.27,-dim.y*0.01),
            center+Vector2(dim.x*0.18,dim.y*0.31),
            center+Vector2(-dim.x*0.25,dim.y*0.25),
            center+Vector2(-dim.x*0.23,-dim.y*0.03)])
        draw_colored_polygon(spikes,Color(pal["tree"]))
        draw_line(spikes[0],center+Vector2(0,dim.y*0.18),Color(pal["spark"],0.7),2.0)

func _draw_water(at: Vector2, dim: Vector2, pal: Dictionary, chapter: int, seed: int) -> void:
    for i: int in range(3):
        var y: float = dim.y*(0.25+i*0.25)
        var shift: float = dim.x*float((seed+i*3)%5)/15.0
        draw_line(at+Vector2(shift,y),at+Vector2(dim.x*0.65+shift,y),
            Color(pal["spark"],0.45),1.8)
    if chapter == 2:
        draw_circle(at+dim*0.5,dim.x*0.14,Color("#ffad6f",0.46))

func _draw_road(at: Vector2, dim: Vector2, pal: Dictionary, seed: int) -> void:
    draw_rect(Rect2(at+dim*0.10,dim*0.80),Color(pal["path"]).lightened(0.12))
    draw_line(at+dim*Vector2(0.12,0.36),at+dim*Vector2(0.9,0.36),Color(pal["sky"],0.25),1.0)
    if seed % 2 == 0:
        draw_line(at+dim*Vector2(0.4,0.1),at+dim*Vector2(0.4,0.35),Color(pal["sky"],0.25),1.0)

func _draw_landmarks(pal: Dictionary) -> void:
    var zone: V6ZoneWorld = world as V6ZoneWorld
    if zone == null:
        return
    _draw_house(zone.ELDER, pal, Color("#9b77b9"))
    _draw_house(V6ZoneWorld.MERCHANT, pal, Color("#e2a365"))
    _draw_house(V6ZoneWorld.CAMP, pal, Color("#8cbbad"))
    _draw_house(V6ZoneWorld.CHRONICLE, pal, Color("#c6b9f2"))
    if not zone.chest_opened:
        _marker(zone.CHEST, Color("#edc372"), "$")
    for encounter: String in zone.ENCOUNTERS.keys():
        if bool(zone.cleared[encounter]):
            continue
        _marker(zone.ENCOUNTERS[encounter],
            Color("#ed7a75") if encounter == "boss" else Color("#f9a46a"),
            "!" if encounter == "boss" else "X")
    if zone.chapter < 2:
        _marker(V6ZoneWorld.GATE_FORWARD,
            Color("#8abff7") if zone.portal_ready() else Color("#63798a"),
            ">" if zone.portal_ready() else "L")
    if zone.chapter > 0:
        _marker(V6ZoneWorld.GATE_BACK,Color("#9cdecc"),"<")

func _draw_house(tile: Vector2i, pal: Dictionary, roof: Color) -> void:
    var at: Vector2 = _offset+Vector2(tile)*_tile_size
    var c: Vector2 = at+Vector2.ONE*_tile_size*0.5
    var d: float = _tile_size
    draw_ellipse(c+Vector2(0,d*0.32),d*0.37,d*0.12,Color("#112130",0.50))
    draw_rect(Rect2(c.x-d*0.27,c.y-d*0.09,d*0.54,d*0.43),Color("#efdbba"))
    var roof_shape := PackedVector2Array([
        c+Vector2(0,-d*0.44),c+Vector2(d*0.40,-d*0.04),
        c+Vector2(-d*0.40,-d*0.04)])
    draw_colored_polygon(roof_shape,roof)
    draw_rect(Rect2(c.x-d*0.07,c.y+d*0.10,d*0.14,d*0.22),Color("#4d3c57"))
    draw_circle(c+Vector2(d*0.14,d*0.08),d*0.035,Color(pal["spark"]))

func _marker(tile: Vector2i, tint: Color, shape: String) -> void:
    var center: Vector2 = _offset+Vector2(tile)*_tile_size+Vector2.ONE*_tile_size*0.5
    var radius: float = _tile_size*(0.32 if _blink else 0.36)
    draw_circle(center,radius+2.0,Color("#132132",0.8))
    draw_circle(center,radius,tint)
    var stroke: Color = Color("#18253d")
    if shape == "X":
        draw_line(center+Vector2(-7,-7),center+Vector2(7,7),stroke,3.2)
        draw_line(center+Vector2(7,-7),center+Vector2(-7,7),stroke,3.2)
    elif shape in ["<",">"]:
        var sign: float = -1.0 if shape == "<" else 1.0
        draw_line(center+Vector2(-5*sign,-8),center+Vector2(6*sign,0),stroke,3.0)
        draw_line(center+Vector2(6*sign,0),center+Vector2(-5*sign,8),stroke,3.0)
    elif shape == "!":
        draw_line(center+Vector2(0,-9),center+Vector2(0,3),stroke,4.0)
        draw_circle(center+Vector2(0,9),2.0,stroke)
    elif shape == "L":
        draw_rect(Rect2(center-Vector2(6,8),Vector2(12,16)),stroke,false,3.0)
    elif shape == "$":
        draw_rect(Rect2(center-Vector2(7,5),Vector2(14,10)),stroke)
        draw_circle(center+Vector2(0,-2),3.0,Color("#fef0a8"))
