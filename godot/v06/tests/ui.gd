extends SceneTree

var errors: int = 0

func _init() -> void:
    call_deferred("_exercise")

func _exercise() -> void:
    var packed: PackedScene = load("res://v06/world_game.tscn")
    _check(packed != null,"v0.6 scene loads")
    if packed == null:
        quit(1)
        return
    var screen: Control = packed.instantiate() as Control
    get_root().add_child(screen)
    await process_frame
    _check(screen.get("campaign") is V6Campaign,"Adventure director initialized")
    _check(screen.get("map_view") is V6OverworldArt,"Original illustrated map is visible")
    _check(screen.get("overlay").visible,"Title panel opens on launch")
    screen.call("_close_panel")
    var director: V6Campaign = screen.get("campaign")
    var game: V3Coordinator = screen.get("game")
    _check(director.current_zone() == screen.get("world"),"World state references active chapter")

    screen.call("_open_panel","journal")
    _check(screen.get("overlay").visible and screen.get("overlay_text").text.contains("CHAPTER 1"),
        "Quest journal opens")
    screen.call("_open_panel","pack")
    _check(screen.get("overlay_text").text.contains("Potions"),"Inventory opens outside combat")
    screen.call("_close_panel")

    director.current_zone().quest_started = true
    var before_gold: int = director.gold
    screen.call("_launch_battle","raider")
    await process_frame
    _check(screen.get("battle_layer").visible,"Battle layer opens from overworld")
    _check(game.battle.unit_by_id("raider").alive(),"Correct patrol enemy loaded")
    # Simulate a resolved battle event to test the entire presentation transition.
    game.battle.finished = true
    game.battle.result = "VICTORY"
    game._publish()
    await process_frame
    await process_frame
    _check(screen.get("battle_screen") == null,"Win returns to overworld automatically")
    _check(screen.get("world_layer").visible,"Overworld restores without opening EQUIP")
    _check(bool(director.current_zone().cleared["raider"]),"Encounter marked complete once")
    _check(director.gold > before_gold,"Returning battle grants loot")
    _check(screen.call("_save_world"),"Adventure saves to slot 1")
    _check(screen.call("_load_world"),"Adventure loads from slot 1")
    _check(bool(screen.get("campaign").current_zone().cleared["raider"]),"Quest flags survive save/load")

    # Player turn should advance automatically if a bonus action is not legal.
    game.new_encounter(false,"raider")
    _check(game.battle.end_turn(),"AI initiative passes to player")
    _check(game.is_player_turn(),"Warden ready to act")
    _check(game.battle.execute("guard","warden"),"Player uses their action")
    await process_frame
    _check(not game.is_player_turn(),"Spent turn automatically advances when no bonus action available")

    # If healing is possible, the bonus window must remain open until potion use.
    game.new_encounter(false,"raider")
    game.battle.end_turn()
    game.battle.unit_by_id("warden").hurt(8)
    _check(game.battle.execute("guard","warden"),"Guard prepares bonus healing")
    await process_frame
    _check(game.is_player_turn(),"Injured Warden retains healing window")
    _check(game.battle.can_act("potion","warden"),"Potion is available as a bonus")
    _check(game.battle.execute("potion","warden"),"Potion heals in bonus window")
    await process_frame
    _check(not game.is_player_turn(),"Bonus action ends the spent turn automatically")

    game.generation += 1
    screen.queue_free()
    await process_frame
    if errors == 0:
        print("V06 AUTO FLOW AND UI INTEGRATION PASSED")
    quit(1 if errors > 0 else 0)

func _check(ok: bool, message: String) -> void:
    if ok:
        print("PASS V06 UI: "+message)
    else:
        errors += 1
        push_error("FAIL V06 UI: "+message)
