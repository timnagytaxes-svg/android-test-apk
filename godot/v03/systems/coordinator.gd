class_name V3Coordinator
extends Node

signal state_changed(snapshot: Dictionary, feed: Array[String])
signal animate(event: Dictionary)

const SAVE_FILE: String = "user://ironbound_tactics_v04.json"
var battle: V3Battle
var bag: ModuleInventory
var progression := V4Progression.new()
var _rewarded: bool = false
var ai := V3AI.new()
var feed: Array[String] = []
var generation: int = 0
var _ai_busy: bool = false
var _ai_pending: bool = false

func new_encounter(reset_campaign: bool = false) -> void:
    generation += 1
    feed.clear()
    if reset_campaign:
        progression = V4Progression.new()
    if bag == null or reset_campaign:
        bag = ModuleInventory.new()
    _rewarded = false
    _replace(V3Battle.new(bag))
    battle.create(progression)
    _schedule_ai()

func choose_class(klass: String) -> bool:
    if not progression.change_class(klass):
        return false
    _message("Class set to %s for NEXT encounter." % V4Progression.CLASSES[klass]["name"])
    return true

func _replace(next: V3Battle) -> void:
    if battle != null:
        if battle.changed.is_connected(_on_changed):
            battle.changed.disconnect(_on_changed)
        if battle.action_resolved.is_connected(_on_resolved):
            battle.action_resolved.disconnect(_on_resolved)
    battle = next
    battle.changed.connect(_on_changed)
    battle.action_resolved.connect(_on_resolved)

func is_player_turn() -> bool:
    var actor: V3Unit = battle.active_unit()
    return actor != null and actor.id == "warden"

func available_targets(kind: String) -> Array[String]:
    var ids: Array[String] = []
    if not is_player_turn():
        return ids
    var actor: V3Unit = battle.active_unit()
    for id: String in battle.abilities.targets(kind, actor, battle.units):
        if battle.can_act(kind, id):
            ids.append(id)
    return ids

func player_action(kind: String, target_id: String) -> bool:
    if not is_player_turn():
        return false
    var applied: bool = battle.execute(kind, target_id)
    if not applied:
        _message("That action or target is unavailable.")
    return applied

func end_player_turn() -> void:
    if not is_player_turn():
        return
    if battle.end_turn():
        _schedule_ai()

func alter_equipment(item_id: String, slot: String, equip_item: bool) -> bool:
    if not is_player_turn():
        _message("Gear can only be changed on Warden's turn.")
        return false
    var applied: bool = battle.change_gear(item_id, slot, equip_item)
    if not applied:
        _message("Requires an unused regular action and a valid item.")
    return applied

func _on_changed(message: String) -> void:
    _message(message)
    if battle.finished and battle.result == "VICTORY" and not _rewarded:
        _rewarded = true
        var awards: Array[String] = progression.earn_victory()
        _message("VICTORY • " + "  |  ".join(PackedStringArray(awards)))
        _message("Open EQUIP, choose your class and NEXT ENCOUNTER to keep your XP.")

func _message(message: String) -> void:
    feed.append(message)
    if feed.size() > 16:
        feed.pop_front()
    _publish()

func _on_resolved(event: Dictionary) -> void:
    animate.emit(event)

func _publish() -> void:
    var state: Dictionary = battle.snapshot()
    state["progression"] = progression.to_dict()
    state_changed.emit(state, feed.duplicate())

func _schedule_ai() -> void:
    if battle.finished or is_player_turn() or _ai_busy or _ai_pending:
        return
    _ai_pending = true
    call_deferred("_run_ai")

func _run_ai() -> void:
    _ai_pending = false
    if _ai_busy or battle.finished or is_player_turn():
        return
    _ai_busy = true
    var version: int = generation
    while version == generation and not battle.finished and not is_player_turn():
        await get_tree().create_timer(0.52).timeout
        if version != generation or battle.finished:
            break
        var move: Dictionary = ai.choose(battle)
        if not move.is_empty():
            battle.execute(str(move["kind"]), str(move["target"]))
        if battle.finished:
            break
        await get_tree().create_timer(0.32).timeout
        if version != generation:
            break
        battle.end_turn()
    _ai_busy = false
    if version == generation:
        _publish()
    else:
        _schedule_ai()

func save_game() -> bool:
    if battle == null:
        return false
    var record: Dictionary = {"schema": 4, "battle": battle.serialize(), "inventory": bag.to_dict(),
        "progression": progression.to_dict(), "rewarded": _rewarded}
    var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        _message("Save failed.")
        return false
    file.store_string(JSON.stringify(record))
    file.flush()
    var success: bool = file.get_error() == OK
    file.close()
    _message("Saved class progression, equipment and battle." if success else "Save failed.")
    return success

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        _message("No v0.4 save found.")
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return false
    var payload: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not payload is Dictionary or int(payload.get("schema", -1)) != 4:
        _message("Incompatible save version.")
        return false
    if not payload.get("inventory") is Dictionary or not payload.get("battle") is Dictionary or not payload.get("progression") is Dictionary:
        _message("Save is invalid.")
        return false
    var new_bag := ModuleInventory.new()
    if not new_bag.restore(payload["inventory"]):
        _message("Gear data is invalid.")
        return false
    var loaded_progression := V4Progression.new()
    if not loaded_progression.restore(payload["progression"]):
        _message("Progression data invalid.")
        return false
    var new_battle := V3Battle.new(new_bag)
    new_battle.create(loaded_progression)
    if not new_battle.restore(payload["battle"]):
        _message("Battle data is invalid.")
        return false
    generation += 1
    bag = new_bag
    progression = loaded_progression
    _rewarded = bool(payload.get("rewarded", false))
    if new_battle.finished and new_battle.result == "VICTORY" and not _rewarded:
        _message("Invalid victory save: missing reward state.")
        return false
    _replace(new_battle)
    feed.clear()
    _message("Save restored.")
    _schedule_ai()
    return true
