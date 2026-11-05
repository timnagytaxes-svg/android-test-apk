extends Control

const SAVE_PATH: String = "user://ironbound_world_v05.json"
const BATTLE_SCENE: PackedScene = preload("res://v03/battle_screen.tscn")

var world: V5WorldState = V5WorldState.new()
var game: V3Coordinator
var world_layer: Control
var battle_layer: Control
var battle_screen: Control
var map_view: V5WorldView
var title_label: Label
var status_label: Label
var quest_label: Label
var info_label: Label
var class_pick: OptionButton
var _walk_timer: Timer
var _route: Array[Vector2i] = []
var _active_encounter: String = ""
var _message: String = "Tap the purple ! to visit Elder Rowan and begin your quest."

func _ready() -> void:
    game = V3Coordinator.new()
    game.bag = ModuleInventory.new()
    add_child(game)
    _make_ui()
    world.changed.connect(_on_world_changed)
    map_view.set_world(world)
    _walk_timer = Timer.new()
    _walk_timer.wait_time = 0.14
    _walk_timer.timeout.connect(_walk_tick)
    add_child(_walk_timer)
    _refresh()

func _make_ui() -> void:
    var base := ColorRect.new()
    base.color = Color("#08111e")
    base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(base)
    world_layer = Control.new()
    world_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(world_layer)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["top", "left", "right", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 12)
    world_layer.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 6)
    margin.add_child(column)
    title_label = _label("IRONBOUND  •  EMBER RIFT  v0.5", 28, Color("#f5c880"))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title_label)
    status_label = _label("", 19, Color("#bad9ff"))
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(status_label)
    map_view = V5WorldView.new()
    map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_view.tile_tapped.connect(_on_tile_tapped)
    column.add_child(map_view)
    quest_label = _label("", 19, Color("#f2dcaa"))
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(quest_label)
    info_label = _label(_message, 19, Color("#cce6d2"))
    info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info_label.custom_minimum_size = Vector2(0, 69)
    column.add_child(info_label)
    var directions := GridContainer.new()
    directions.columns = 5
    directions.add_theme_constant_override("h_separation",6)
    column.add_child(directions)
    var choices: Array[String] = ["NORTH", "WEST", "TALK / OPEN", "EAST", "SOUTH"]
    for id: String in choices:
        var button := _button(id, 17, 65)
        directions.add_child(button)
        button.pressed.connect(_press_move.bind(id))
    var class_row := HBoxContainer.new()
    class_row.add_theme_constant_override("separation",8)
    column.add_child(class_row)
    class_row.add_child(_label("WARDEN CLASS:",17,Color("#e4c98a")))
    class_pick = OptionButton.new()
    class_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    class_pick.add_theme_font_size_override("font_size",17)
    for klass: String in ["vanguard", "spellblade", "bulwark"]:
        class_pick.add_item(str(V4Progression.CLASSES[klass]["name"]))
    class_pick.item_selected.connect(_class_changed)
    class_row.add_child(class_pick)
    var utilities := HBoxContainer.new()
    utilities.add_theme_constant_override("separation",8)
    column.add_child(utilities)
    for action: String in ["SAVE", "LOAD", "RESTART WORLD"]:
        var button := _button(action, 17, 56)
        utilities.add_child(button)
        button.pressed.connect(_utility.bind(action))
    battle_layer = Control.new()
    battle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    battle_layer.visible = false
    add_child(battle_layer)

func _label(content: String, fontsize: int, tint: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.add_theme_font_size_override("font_size", fontsize)
    label.add_theme_color_override("font_color", tint)
    return label

func _button(content: String, fontsize: int, height: float) -> Button:
    var button := Button.new()
    button.text = content
    button.custom_minimum_size = Vector2(0,height)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", fontsize)
    return button

func _refresh() -> void:
    if game == null:
        return
    status_label.text = "LEVEL %d  •  %s  •  POTIONS %d  •  VICTORIES %d" % [
        int(game.progression.heroes["warden"]["level"]),
        str(V4Progression.CLASSES[game.progression.hero_class]["name"]).to_upper(),
        game.bag.potions, game.progression.victories]
    quest_label.text = "QUEST  •  " + world.objective_text()
    info_label.text = _message
    map_view.queue_redraw()
    var class_index: int = ["vanguard", "spellblade", "bulwark"].find(game.progression.hero_class)
    if class_index >= 0:
        class_pick.select(class_index)

func _on_world_changed(message: String) -> void:
    if not message.is_empty():
        _message = message
    _refresh()

func _press_move(action: String) -> void:
    if not _active_encounter.is_empty():
        return
    match action:
        "NORTH": _move_manual(Vector2i(0,-1))
        "SOUTH": _move_manual(Vector2i(0,1))
        "EAST": _move_manual(Vector2i(1,0))
        "WEST": _move_manual(Vector2i(-1,0))
        "TALK / OPEN": _interact_here()

func _move_manual(delta: Vector2i) -> void:
    _stop_walk()
    if world.move(delta):
        _interact_here()

func _on_tile_tapped(tile: Vector2i) -> void:
    if not _active_encounter.is_empty():
        return
    _stop_walk()
    if tile == world.player:
        _interact_here()
        return
    _route = world.path_to(tile)
    if _route.is_empty():
        _message = "No clear route. Try tapping a green grass tile."
        _refresh()
        return
    _walk_timer.start()
    _walk_tick()

func _walk_tick() -> void:
    if _route.is_empty():
        _stop_walk()
        return
    var next: Vector2i = _route.pop_front()
    if not world.move(next - world.player):
        _stop_walk()
        return
    if not world.location_id(world.player).is_empty():
        _stop_walk()
        _interact_here()
    elif _route.is_empty():
        _stop_walk()

func _stop_walk() -> void:
    _route.clear()
    if _walk_timer != null:
        _walk_timer.stop()

func _interact_here() -> void:
    var outcome: Dictionary = world.inspect(game.bag)
    match str(outcome.get("kind","none")):
        "battle":
            _launch_battle(str(outcome["encounter"]))
        "dialogue":
            _message = "%s: %s" % [str(outcome.get("speaker","")),str(outcome.get("text",""))]
        "treasure":
            _message = str(outcome.get("text","Treasure found."))
    _refresh()

func _launch_battle(encounter: String) -> void:
    if not _active_encounter.is_empty():
        return
    _stop_walk()
    _active_encounter = encounter
    game.new_encounter(false, encounter)
    battle_screen = BATTLE_SCENE.instantiate() as Control
    battle_screen.set("injected_game",game)
    battle_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    battle_screen.connect("return_to_world",_return_from_battle)
    battle_layer.add_child(battle_screen)
    world_layer.visible = false
    battle_layer.visible = true

func _return_from_battle() -> void:
    if _active_encounter.is_empty() or game.battle == null or not game.battle.finished:
        return
    var victory: bool = game.battle.result == "VICTORY"
    world.finish_encounter(_active_encounter, victory)
    _active_encounter = ""
    if battle_screen != null:
        battle_layer.remove_child(battle_screen)
        battle_screen.queue_free()
        battle_screen = null
    battle_layer.visible = false
    world_layer.visible = true
    if victory:
        _message = "Victory! Experience and equipment are retained. " + world.objective_text()
        _save_world(true)
    else:
        _message = "Defeat. That encounter remains available for another attempt."
    _refresh()

func _class_changed(item: int) -> void:
    if item < 0 or item >= 3:
        return
    var klass: String = ["vanguard", "spellblade", "bulwark"][item]
    if game.progression.change_class(klass):
        _message = "Class switched to %s. Takes effect in your next battle." % str(V4Progression.CLASSES[klass]["name"])
        _refresh()

func _utility(action: String) -> void:
    match action:
        "SAVE":
            _save_world()
        "LOAD":
            _load_world()
        "RESTART WORLD":
            _stop_walk()
            world = V5WorldState.new()
            world.changed.connect(_on_world_changed)
            game.bag = ModuleInventory.new()
            game.progression = V4Progression.new()
            game.generation += 1
            map_view.set_world(world)
            _message = "New world started. This does not overwrite your saved slot until SAVE."
            _refresh()

func _save_world(silent: bool = false) -> bool:
    if not _active_encounter.is_empty():
        return false
    var record: Dictionary = {
        "schema": 5,
        "world": world.to_dict(),
        "inventory": game.bag.to_dict(),
        "progression": game.progression.to_dict()
    }
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        _message = "Could not open world save file."
        _refresh()
        return false
    file.store_string(JSON.stringify(record))
    file.flush()
    var ok: bool = file.get_error() == OK
    file.close()
    if not silent:
        _message = "Exploration, class, XP, and gear saved!" if ok else "World save failed."
    _refresh()
    return ok

func _load_world() -> bool:
    _stop_walk()
    if not FileAccess.file_exists(SAVE_PATH):
        _message = "No v0.5 world save exists."
        _refresh()
        return false
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        _message = "World save could not be opened."
        _refresh()
        return false
    var payload: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not payload is Dictionary or int(payload.get("schema",0)) != 5:
        _message = "Save format is incompatible."
        _refresh()
        return false
    if not payload.get("world") is Dictionary or not payload.get("inventory") is Dictionary or not payload.get("progression") is Dictionary:
        _message = "World save is incomplete."
        _refresh()
        return false
    var loaded_world := V5WorldState.new()
    var loaded_bag := ModuleInventory.new()
    var loaded_progress := V4Progression.new()
    if not loaded_world.restore(payload["world"]) or not loaded_bag.restore(payload["inventory"]) or not loaded_progress.restore(payload["progression"]):
        _message = "World save validation failed. Previous state retained."
        _refresh()
        return false
    world = loaded_world
    world.changed.connect(_on_world_changed)
    game.bag = loaded_bag
    game.progression = loaded_progress
    game.generation += 1
    map_view.set_world(world)
    _message = "World restored. Explore or continue the quest!"
    _refresh()
    return true
