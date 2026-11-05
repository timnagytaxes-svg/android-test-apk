extends SceneTree

var errors: int = 0

func _init() -> void:
    call_deferred("_exercise")

func _exercise() -> void:
    var source: PackedScene = load("res://v05/world_game.tscn")
    _check(source != null, "Overworld scene loaded")
    if source == null:
        quit(1)
        return
    var screen: Control = source.instantiate() as Control
    get_root().add_child(screen)
    await process_frame
    var map: V5WorldView = screen.get("map_view") as V5WorldView
    _check(map != null and map.world != null, "World renderer initialized")
    var game: V3Coordinator = screen.get("game") as V3Coordinator
    _check(game != null and game.bag != null, "Persistent game coordinator exists")
    _check(screen.get("battle_layer") != null, "Battle layer exists")
    _check(game.battle == null, "World startup does not create unnecessary combat")
    screen.call("_launch_battle", "raider")
    await process_frame
    var battle: Control = screen.get("battle_screen") as Control
    _check(battle != null and is_instance_valid(battle), "Battle overlay instantiated")
    _check(battle.get("injected_game") == game, "Battle uses same game coordinator")
    _check(battle.get("game") == game, "Battle scene adopted existing coordinator")
    _check(game.battle.unit_by_id("raider").alive(), "Correct patrol enemy spawned")
    _check(screen.get("world_layer").visible == false, "World hidden while fighting")
    _check(screen.get("battle_layer").visible == true, "Battle overlay visible")
    _check(battle.get("equip_layer") != null, "Equipment view initialized in world-mode")
    var sim: V3Battle = game.battle
    sim.finished = true
    sim.result = "DEFEAT"
    screen.call("_return_from_battle")
    await process_frame
    _check(screen.get("world_layer").visible == true, "Return restores world view")
    _check(screen.get("battle_screen") == null, "Battle UI removed on return")
    _check(screen.get("_active_encounter") == "", "Encounter lock released")
    _check(not (screen.get("world") as V5WorldState).cleared["raider"], "Defeat does not clear enemy")

    screen.queue_free()
    if errors == 0:
        print("V05 UI BATTLE TRANSITION TESTS PASSED")
    quit(1 if errors > 0 else 0)

func _check(ok: bool, description: String) -> void:
    if ok:
        print("PASS V05 UI: " + description)
    else:
        errors += 1
        push_error("FAIL V05 UI: " + description)
