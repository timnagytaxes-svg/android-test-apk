class_name ModuleAbilityRules
extends RefCounted

const COSTS: Dictionary = {
    "attack": 0, "special": 2, "ember": 1, "frost": 2, "mend": 2, "guard": 0
}
const LABELS: Dictionary = {
    "attack": "Attack", "special": "Arc Strike",
    "ember": "Ember Bolt", "frost": "Frost Shard", "mend": "Mend", "guard": "Guard"
}
func cost(kind: String) -> int:
    return int(COSTS.get(kind, 999))

func label(kind: String) -> String:
    return str(LABELS.get(kind, kind))

func damage_for(kind: String, power: int, armor: int, chilled: bool, guarding: bool, rng: RandomNumberGenerator) -> int:
    var base: int = 3 + power + rng.randi_range(0, 3)
    if kind == "special":
        base += 6
    elif kind == "ember":
        base += 4
    elif kind == "frost":
        base += 2
    if chilled:
        base -= 3
    if guarding:
        base -= 4
    var mitigation: int = armor
    if kind == "ember" or kind == "frost":
        mitigation = armor / 2
    return maxi(1, base - mitigation)
