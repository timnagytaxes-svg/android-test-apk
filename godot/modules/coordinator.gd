class_name ModuleCoordinator
extends Node

signal view_changed(view: Dictionary, recent_events: Array)

var combat: ModuleCombat
var inventory: ModuleInventory
var _rules := ModuleAbilityRules.new()
var _ai := ModuleTacticalAI.new()
var _store := ModuleSaveStore.new()
var _events: Array[String] = []
var _ai_scheduled: bool = false
var _ai_running: bool = false

func start_new() -> void:
    _events.clear()
    inventory = ModuleInventory.new()
    _replace_combat(ModuleCombat.new(_rules, inventory))
    combat.start_battle()

func _replace_combat(next_combat: ModuleCombat) -> void:
    if combat != null and combat.changed.is_connected(_on_combat_changed):
        combat.changed.disconnect(_on_combat_changed)
    combat = next_combat
    combat.changed.connect(_on_combat_changed)

func command(kind: String) -> void:
    var actor: ModuleActor = combat.current_actor()
    if actor == null or actor.id != "hero":
        return
    var accepted: bool = combat.advance_turn() if kind == "end" else combat.execute(kind, "foe")
    if not accepted:
        _record("Action unavailable. Attack or guard first; potion is a bonus action.")
        _publish()

func save_game() -> void:
    var payload: Dictionary = {"schema": 1, "combat": combat.to_dict(), "inventory": inventory.to_dict()}
    _record("Saved to device." if _store.write(payload) else "Save failed.")
    _publish()

func load_game() -> void:
    var payload: Dictionary = _store.read()
    if int(payload.get("schema", 0)) != 1:
        _record("No compatible save found.")
        _publish()
        return
    if not payload.get("combat") is Dictionary or not payload.get("inventory") is Dictionary:
        _record("Save data is invalid.")
        _publish()
        return
    var new_inventory := ModuleInventory.new()
    if not new_inventory.restore(payload["inventory"]):
        _record("Inventory save is invalid.")
        _publish()
        return
    var new_combat := ModuleCombat.new(_rules, new_inventory)
    if not new_combat.restore(payload["combat"]):
        _record("Battle save is invalid.")
        _publish()
        return
    inventory = new_inventory
    _replace_combat(new_combat)
    _events.clear()
    _record("Save loaded successfully.")
    _publish()
    _schedule_ai()

func _on_combat_changed(message: String) -> void:
    _record(message)
    _publish()
    _schedule_ai()

func _record(message: String) -> void:
    _events.append(message)
    if _events.size() > 14:
        _events.pop_front()

func _publish() -> void:
    var actor: ModuleActor = combat.current_actor()
    var hero: ModuleActor = combat.actor_by_id("hero")
    var ally: ModuleActor = combat.actor_by_id("companion")
    var enemy: ModuleActor = combat.actor_by_id("foe")
    var player_turn: bool = actor != null and actor.id == "hero"
    view_changed.emit({
        "round": combat.round_number, "turn_name": actor.display_name if actor != null else combat.outcome,
        "hero": hero.to_dict(), "companion": ally.to_dict(), "foe": enemy.to_dict(),
        "potions": inventory.potions, "finished": combat.finished,
        "can_act": player_turn and not hero.action_used,
        "can_special": player_turn and not hero.action_used and hero.stamina >= 2,
        "can_potion": player_turn and hero.action_used and not hero.bonus_used and hero.hp < hero.max_hp and inventory.potions > 0,
        "player_turn": player_turn
    }, _events.duplicate())

func _schedule_ai() -> void:
    var actor: ModuleActor = combat.current_actor()
    if actor == null or actor.id == "hero" or _ai_scheduled or _ai_running:
        return
    _ai_scheduled = true
    call_deferred("_perform_ai")

func _perform_ai() -> void:
    _ai_scheduled = false
    var actor: ModuleActor = combat.current_actor()
    if actor == null or actor.id == "hero":
        return
    _ai_running = true
    var plan: Dictionary = _ai.choose(combat)
    if not plan.is_empty():
        combat.execute(str(plan["kind"]), str(plan["target"]))
    if not combat.finished:
        combat.advance_turn()
    _ai_running = false
    _schedule_ai()
