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
    screen.call("_begin_adventure")
    _check(screen.get("overlay_title").text == "HOW TO PLAY","First-run interactive tutorial appears")
    screen.call("_complete_tutorial")
    _check(not screen.get("overlay").visible,"Tutorial opens world play screen")
    _check(screen.get("campaign").tutorial_seen,"Tutorial completion stored")
    var director: V6Campaign = screen.get("campaign")
    var game: V3Coordinator = screen.get("game")
    _check(director.current_zone() == screen.get("world"),"World state references active chapter")

    screen.call("_open_panel","journal")
    _check(screen.get("overlay").visible and screen.get("overlay_text").text.contains("CHAPTER 1"),
        "Quest journal opens")
    screen.call("_open_panel","camp")
    _check(screen.get("overlay_title").text.contains("CAMP"),"Camp has a dedicated conversation panel")
    screen.call("_camp_talk","mira")
    _check(screen.get("overlay_text").text.contains("Last Lantern"),"Companion chapter-one dialogue displayed")
    _check(director.bonds["mira"] == 1,"Dialogue raises companion bond and autosaves")
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
    director = screen.get("campaign") as V6Campaign
    # Chapter portals must preserve each area's quest state while sharing party XP.
    var first: V6ZoneWorld = director.current_zone()
    first.cleared = {"raider":true,"shaman":true,"boss":true}
    first.quest_claimed = true
    first.player = V6ZoneWorld.GATE_FORWARD
    screen.call("_interact_here")
    _check(director.chapter == 1,"Completed chapter unlocks next map")
    _check(screen.get("map_view").world == director.current_zone(),"Rendered map changes with chapter")
    _check(director.current_zone().terrain(Vector2i(2,2)) == "snow","Second chapter draws frozen terrain")
    director.current_zone().player = V6ZoneWorld.GATE_BACK
    screen.call("_interact_here")
    _check(director.chapter == 0,"Player can revisit earlier zones")
    _check(bool(director.current_zone().cleared["raider"]),"Revisiting preserves victory flags")

    var sound: V6Sound = screen.get("_sound") as V6Sound
    _check(sound != null and sound.enabled,"Original sound subsystem initialized")
    sound.set_theme("battle")
    sound.play_sfx("hit")
    sound.set_enabled(false)
    _check(not sound.enabled,"Audio can be disabled for accessibility")
    sound.set_enabled(true)

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

    # Repeatable challenges must leave the main story untouched.
    director = screen.get("campaign") as V6Campaign
    var chapter_flags: Dictionary = director.current_zone().cleared.duplicate()
    var bounties_before: int = director.bounty_victories
    screen.call("_start_bounty","shaman")
    await process_frame
    _check(screen.get("battle_layer").visible,"Optional bounty opens an actual battle")
    _check(bool(screen.get("_bounty_active")),"Bounty encounter tracked separately")
    game.battle.finished = true
    game.battle.result = "VICTORY"
    game._publish()
    await process_frame
    await process_frame
    _check(screen.get("battle_screen") == null,"Bounty returns to map without an EQUIP detour")
    _check(director.bounty_victories == bounties_before + 1,"Bounty victory awards separate progress")
    _check(director.current_zone().cleared == chapter_flags,"Bounties never clear story encounters")

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
