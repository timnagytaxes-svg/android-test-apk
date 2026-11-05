class_name ModuleAbilityRules
extends RefCounted

const SPECIAL_COST: int = 2

func damage_for(kind: String, source: ModuleActor, target: ModuleActor, rng: RandomNumberGenerator) -> int:
    var base: int = 4 + source.power + rng.randi_range(0, 3)
    if kind == "special":
        base += 6
    if target.guarding:
        base -= 4
    return maxi(1, base - target.armor)
