class_name ModuleCombat
extends RefCounted

signal changed(message: String)
signal resolved(event: Dictionary)

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
    combatants.append(ModuleActor.new("companion", "Mira", "party", 29, 4, 1, 8))
    combatants.append(ModuleActor.new("foe", "Ashfang", "enemy", 85, 5, 2, 10))
    turn_order = combatants.duplicate()
    turn_order.sort_custom(func(a: ModuleActor, b: ModuleActor) -> bool: return a.initiative > b.initiative)
    turn_index = 0
    round_number = 1
    finished = false
    outcome = ""
    _rng.randomize()
    current_actor().begin_turn()
    changed.emit("Warden and Mira challenge Ashfang!")

func actor_by_id(actor_id: String) -> ModuleActor:
    for actor: ModuleActor in combatants:
        if actor.id == actor_id:
            return actor
    return null

func current_actor() -> ModuleActor:
    if finished or turn_order.is_empty():
        return null
    return turn_order[turn_index]

func max_hp_for(actor: ModuleActor) -> int:
    return actor.max_hp + int(_inventory.modifiers()["hp"]) if actor.id == "hero" else actor.max_hp

func power_for(actor: ModuleActor) -> int:
    return actor.power + int(_inventory.modifiers()["power"]) if actor.id == "hero" else actor.power

func armor_for(actor: ModuleActor) -> int:
    return actor.armor + int(_inventory.modifiers()["armor"]) if actor.id == "hero" else actor.armor

func actor_view(actor: ModuleActor) -> Dictionary:
    var result: Dictionary = actor.to_dict()
    result["max_hp"] = max_hp_for(actor)
    result["power"] = power_for(actor)
    result["armor"] = armor_for(actor)
    return result

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
        # The established action economy: a bonus action follows a regular action.
        if not actor.action_used or actor.bonus_used or actor.hp >= max_hp_for(actor):
            return false
        if not _inventory.consume_potion():
            return false
        actor.bonus_used = true
        var healed: int = actor.heal(12, max_hp_for(actor))
        resolved.emit({"kind": "potion", "source": actor.id, "target": actor.id, "amount": healed})
        changed.emit("%s uses a potion (+%d HP)." % [actor.display_name, healed])
        return true
    if actor.action_used:
        return false
    if not _rules.COSTS.has(kind) or actor.stamina < _rules.cost(kind):
        return false
    if kind == "guard":
        actor.guarding = true
        actor.action_used = true
        resolved.emit({"kind": kind, "source": actor.id, "target": actor.id, "amount": 0})
        changed.emit("%s takes a defensive stance." % actor.display_name)
        return true
    var target: ModuleActor = actor_by_id(target_id)
    if target == null or not target.alive():
        return false
    if kind == "mend":
        if target.team != actor.team or target.hp >= max_hp_for(target):
            return false
    elif target.team == actor.team:
        return false
    actor.action_used = true
    actor.stamina -= _rules.cost(kind)
    var applied: int = 0
    if kind == "mend":
        applied = target.heal(10 + _rng.randi_range(0, 4), max_hp_for(target))
    else:
        applied = target.receive_damage(_rules.damage_for(kind, power_for(actor), armor_for(target), actor.chilled, target.guarding, _rng))
        if kind == "frost" and target.alive():
            target.chilled = true
    actor.chilled = false
    _check_finished()
    var message: String = "%s casts %s on %s: %d %s." % [actor.display_name, _rules.label(kind), target.display_name, applied, "healed" if kind == "mend" else "damage"]
    if kind == "frost" and target.alive():
        message += " Chilled!"
    if finished:
        message += " " + outcome
    resolved.emit({"kind": kind, "source": actor.id, "target": target.id, "amount": applied})
    changed.emit(message)
    return true

func change_gear(item_id: String, slot: String, equip_item: bool) -> bool:
    var actor: ModuleActor = current_actor()
    if actor == null or actor.id != "hero" or actor.action_used:
        return false
    var ok: bool = _inventory.equip(item_id) if equip_item else _inventory.unequip(slot)
    if not ok:
        return false
    actor.hp = mini(actor.hp, max_hp_for(actor))
    actor.action_used = true
    changed.emit("Warden adjusts equipment (uses an action).")
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
    if not finished and not current_actor().alive():
        return false
    changed.emit("Battle restored from save.")
    return true
