class_name ModuleCombat
extends RefCounted

signal changed(message: String)

var combatants: Array[ModuleActor] = []
var turn_order: Array[ModuleActor] = []
var turn_index: int = 0
var round_number: int = 1
var finished: bool = false
var outcome: String = ""
var _rules: ModuleAbilityRules
var _inventory: ModuleInventory
var _rng := RandomNumberGenerator.new()

func _init(rules: ModuleAbilityRules, inventory: ModuleInventory) -> void:
    _rules = rules
    _inventory = inventory

func start_battle() -> void:
    combatants.clear()
    combatants.append(ModuleActor.new("hero", "Warden", "party", 36, 6, 2, 12))
    combatants.append(ModuleActor.new("companion", "Mira", "party", 28, 4, 1, 8))
    combatants.append(ModuleActor.new("foe", "Ashfang", "enemy", 65, 5, 2, 10))
    turn_order = combatants.duplicate()
    turn_order.sort_custom(func(a: ModuleActor, b: ModuleActor) -> bool: return a.initiative > b.initiative)
    turn_index = 0
    round_number = 1
    finished = false
    outcome = ""
    _rng.randomize()
    current_actor().begin_turn()
    changed.emit("Battle begins. Warden and Mira face Ashfang.")

func actor_by_id(actor_id: String) -> ModuleActor:
    for actor: ModuleActor in combatants:
        if actor.id == actor_id:
            return actor
    return null

func current_actor() -> ModuleActor:
    if finished or turn_order.is_empty():
        return null
    return turn_order[turn_index]

func living_targets(actor: ModuleActor) -> Array[ModuleActor]:
    var result: Array[ModuleActor] = []
    for other: ModuleActor in combatants:
        if other.team != actor.team and other.alive():
            result.append(other)
    return result

func execute(kind: String, target_id: String = "") -> bool:
    var actor: ModuleActor = current_actor()
    if actor == null or not actor.alive():
        return false
    if kind == "potion":
        if not actor.action_used or actor.bonus_used or actor.hp == actor.max_hp:
            return false
        if not _inventory.consume_potion():
            return false
        actor.bonus_used = true
        var recovered: int = actor.heal(10)
        changed.emit("%s drinks a potion (+%d HP)." % [actor.display_name, recovered])
        return true
    if actor.action_used:
        return false
    if kind == "guard":
        actor.guarding = true
        actor.action_used = true
        changed.emit("%s braces for incoming attacks." % actor.display_name)
        return true
    if kind != "attack" and kind != "special":
        return false
    if kind == "special" and actor.stamina < _rules.SPECIAL_COST:
        return false
    var target: ModuleActor = actor_by_id(target_id)
    if target == null or not target.alive() or target.team == actor.team:
        return false
    if kind == "special":
        actor.stamina -= _rules.SPECIAL_COST
    actor.action_used = true
    var amount: int = target.receive_damage(_rules.damage_for(kind, actor, target, _rng))
    _check_finished()
    var label: String = "Arc Strike" if kind == "special" else "attack"
    var message: String = "%s uses %s on %s for %d damage." % [actor.display_name, label, target.display_name, amount]
    if finished:
        message += " " + outcome
    changed.emit(message)
    return true

func advance_turn() -> bool:
    if finished:
        return false
    var next_index: int = turn_index + 1
    while true:
        while next_index < turn_order.size():
            if turn_order[next_index].alive():
                turn_index = next_index
                current_actor().begin_turn()
                changed.emit("%s's turn." % current_actor().display_name)
                return true
            next_index += 1
        round_number += 1
        turn_order = combatants.filter(func(a: ModuleActor) -> bool: return a.alive())
        turn_order.sort_custom(func(a: ModuleActor, b: ModuleActor) -> bool: return a.initiative > b.initiative)
        if turn_order.is_empty():
            return false
        next_index = 0
    return false

func _check_finished() -> void:
    var party_alive: bool = false
    var enemy_alive: bool = false
    for actor: ModuleActor in combatants:
        if actor.alive():
            if actor.team == "party":
                party_alive = true
            else:
                enemy_alive = true
    if not party_alive or not enemy_alive:
        finished = true
        outcome = "VICTORY!" if party_alive else "DEFEAT."

func to_dict() -> Dictionary:
    var data: Array[Dictionary] = []
    for actor: ModuleActor in combatants:
        data.append(actor.to_dict())
    return {
        "actors": data, "round": round_number, "turn": turn_index,
        "finished": finished, "outcome": outcome, "rng": str(_rng.state)
    }

func restore(data: Dictionary) -> bool:
    var entries: Variant = data.get("actors")
    if not entries is Array or entries.size() != 3:
        return false
    var expected_ids: Array[String] = ["hero", "companion", "foe"]
    var restored: Array[ModuleActor] = []
    for i: int in range(3):
        if not entries[i] is Dictionary:
            return false
        var actor: ModuleActor = ModuleActor.from_dict(entries[i])
        if actor == null or actor.id != expected_ids[i]:
            return false
        if actor.team != ("enemy" if actor.id == "foe" else "party"):
            return false
        restored.append(actor)
    var next_turn: int = int(data.get("turn", -1))
    var next_round: int = int(data.get("round", 0))
    if next_turn < 0 or next_turn >= 3 or next_round < 1 or next_round > 100000:
        return false
    combatants = restored
    turn_order = combatants.duplicate()
    turn_order.sort_custom(func(a: ModuleActor, b: ModuleActor) -> bool: return a.initiative > b.initiative)
    turn_index = next_turn
    round_number = next_round
    finished = bool(data.get("finished", false))
    outcome = str(data.get("outcome", ""))
    _rng.state = int(data.get("rng", "0"))
    changed.emit("Battle restored from save.")
    return true
