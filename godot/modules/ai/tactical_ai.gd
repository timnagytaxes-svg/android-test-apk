class_name ModuleTacticalAI
extends RefCounted

# AI recommends a legal action; it never mutates combat state.
func choose(combat: ModuleCombat) -> Dictionary:
    var actor: ModuleActor = combat.current_actor()
    if actor == null or actor.id == "hero":
        return {}
    var targets: Array[ModuleActor] = combat.living_targets(actor)
    if targets.is_empty():
        return {}
    var target: ModuleActor = targets[0]
    # Enemy prefers the player; companion has only one foe in this demo.
    for candidate: ModuleActor in targets:
        if candidate.id == "hero":
            target = candidate
            break
    var kind: String = "attack"
    if actor.id == "companion" and actor.stamina >= 2:
        kind = "special"
    return {"kind": kind, "target": target.id}
