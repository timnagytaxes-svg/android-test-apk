class_name ModuleCoordinator
extends Node

signal view_changed(view: Dictionary, recent_events: Array)
signal visual_requested(event: Dictionary)

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
    if combat != null:
        if combat.changed.is_connected(_on_combat_changed):
            combat.changed.disconnect(_on_combat_changed)
        if combat.resolved.is_connected(_on_combat_resolved):
            combat.resolved.disconnect(_on_combat_resolved)
    combat = next_combat
    combat.changed.connect(_on_combat_changed)
    combat.resolved.connect(_on_combat_resolved)

func command(kind: String) -> void:
    var actor: ModuleActor = combat.current_actor()
    if actor == null or actor.id != "hero":
        return
    var target_id: String = "hero" if kind == "mend" or kind == "potion" else "foe"
    var accepted: bool = combat.advance_turn() if kind == "end" else combat.execute(kind, target_id)
    if not accepted:
        _record("Unavailable. Potions unlock AFTER your regular action.")
        _publish()

func change_gear(item_id: String, slot: String, equip_item: bool) -> void:
    if not combat.change_gear(item_id, slot, equip_item):
        _record("Equipment changes require an unused player action.")
        _publish()

func save_game() -> void:
    var payload: Dictionary = {"schema": 2, "combat": combat.to_dict(), "inventory": inventory.to_dict()}
    _record("Battle and equipment saved." if _store.write(payload) else "Save failed.")
    _publish()

func load_game() -> void:
    var payload: Dictionary = _store.read()
    if int(payload.get("schema", 0)) != 2:
        _record("No v2 save found. Start a new battle and save.")
        _publish()
        return
    if not payload.get("combat") is Dictionary or not payload.get("inventory") is Dictionary:
        _record("Save data is invalid.")
        _publish()
        return
    var new_inventory := ModuleInventory.new()
    if not new_inventory.restore(payload["inventory"]):
        _record("Equipment save is invalid.")
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
    _record("Battle and gear restored.")
    _publish()
    _schedule_ai()

func _on_combat_resolved(event: Dictionary) -> void:
    visual_requested.emit(event)

func _on_combat_changed(message: String) -> void:
    _record(message)
    _publish()
    _schedule_ai()

func _record(message: String) -> void:
    _events.append(message)
    if _events.size() > 16:
        _events.pop_front()

func _publish() -> void:
    var actor: ModuleActor = combat.current_actor()
    var hero: ModuleActor = combat.actor_by_id("hero")
    var ally: ModuleActor = combat.actor_by_id("companion")
    var enemy: ModuleActor = combat.actor_by_id("foe")
    if hero == null or ally == null or enemy == null:
        return
    var player_turn: bool = actor != null and actor.id == "hero"
    var can_act: bool = player_turn and not hero.action_used
    view_changed.emit({
        "round": combat.round_number,
        "turn_name": actor.display_name if actor != null else combat.outcome,
        "hero": combat.actor_view(hero),
        "companion": combat.actor_view(ally),
        "foe": combat.actor_view(enemy),
        "potions": inventory.potions,
        "bag": inventory.bag.duplicate(),
        "equipment": inventory.equipped.duplicate(),
        "finished": combat.finished,
        "can_act": can_act,
        "can_special": can_act and hero.stamina >= 2,
        "can_ember": can_act and hero.stamina >= 1,
        "can_frost": can_act and hero.stamina >= 2,
        "can_mend": can_act and hero.stamina >= 2 and hero.hp < combat.max_hp_for(hero),
        "can_potion": player_turn and hero.action_used and not hero.bonus_used and hero.hp < combat.max_hp_for(hero) and inventory.potions > 0,
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
