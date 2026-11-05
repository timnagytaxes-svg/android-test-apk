class_name V3Coordinator
extends Node

signal state_changed(snapshot: Dictionary, feed: Array[String])
signal animate(event: Dictionary)

const SAVE_FILE: String = "user://ironbound_tactics_v03.json"
var battle: V3Battle
var bag: ModuleInventory
var ai := V3AI.new()
var feed: Array[String] = []
var generation: int = 0
var _ai_busy: bool = false
var _ai_pending: bool = false

func new_encounter() -> void:
    generation += 1
    feed.clear()
    bag = ModuleInventory.new()
    _replace(V3Battle.new(bag))
    battle.create()
    _schedule_ai()

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

func _message(message: String) -> void:
    feed.append(message)
    if feed.size() > 16:
        feed.pop_front()
    _publish()

func _on_resolved(event: Dictionary) -> void:
    animate.emit(event)

func _publish() -> void:
    state_changed.emit(battle.snapshot(), feed.duplicate())

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
    var record: Dictionary = {"schema": 3, "battle": battle.serialize(), "inventory": bag.to_dict()}
    var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file == null:
        _message("Save failed.")
        return false
    file.store_string(JSON.stringify(record))
    file.flush()
    var success: bool = file.get_error() == OK
    file.close()
    _message("Saved v0.3 battle." if success else "Save failed.")
    return success

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        _message("No v0.3 save found.")
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        return false
    var payload: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if not payload is Dictionary or int(payload.get("schema", -1)) != 3:
        _message("Incompatible save version.")
        return false
    if not payload.get("inventory") is Dictionary or not payload.get("battle") is Dictionary:
        _message("Save is invalid.")
        return false
    var new_bag := ModuleInventory.new()
    if not new_bag.restore(payload["inventory"]):
        _message("Gear data is invalid.")
        return false
    var new_battle := V3Battle.new(new_bag)
    new_battle.create()
    if not new_battle.restore(payload["battle"]):
        _message("Battle data is invalid.")
        return false
    generation += 1
    bag = new_bag
    _replace(new_battle)
    feed.clear()
    _message("Save restored.")
    _schedule_ai()
    return true
