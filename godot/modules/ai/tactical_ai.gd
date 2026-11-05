class_name ModuleTacticalAI
extends RefCounted

# Pure decision maker: no scene knowledge and no state mutations.
func choose(combat: ModuleCombat) -> Dictionary:
    var actor: ModuleActor = combat.current_actor()
    if actor == null or actor.id == "hero":
        return {}
    var targets: Array[ModuleActor] = combat.living_targets(actor)
    if targets.is_empty():
        return {}
    if actor.id == "companion":
        var hero: ModuleActor = combat.actor_by_id("hero")
        if hero.alive() and hero.hp <= combat.max_hp_for(hero) - 12 and actor.stamina >= 2:
            return {"kind": "mend", "target": "hero"}
        return {"kind": "frost" if actor.stamina >= 2 and combat.round_number % 2 == 0 else "attack", "target": "foe"}
    var target: ModuleActor = targets[0]
    for candidate: ModuleActor in targets:
        if candidate.id == "hero" and candidate.alive():
            target = candidate
    return {"kind": "ember" if actor.stamina >= 1 and combat.round_number % 2 == 0 else "attack", "target": target.id}
