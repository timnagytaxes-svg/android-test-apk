extends SceneTree

var errors: int = 0

func _init() -> void:
    var campaign := V6Campaign.new()
    var bag := ModuleInventory.new()
    var progress := V4Progression.new()
    _check(campaign.chapter == 0 and campaign.zones.size() == 3,"Three independent story chapters")
    _check(not campaign.travel(1),"Next area locked until main quest")
    _check(campaign.current_zone().terrain(Vector2i(2,2)) == "grass","Hearthwood meadow palette")
    _check(campaign.current_zone().location_id(V6ZoneWorld.MERCHANT) == "merchant","Merchant on map")
    _check(campaign.current_zone().location_id(V6ZoneWorld.CAMP) == "camp","Camp on map")
    _check(campaign.current_zone().location_id(V6ZoneWorld.GATE_FORWARD) == "gate_forward","Chapter gate available")
    _check(campaign.current_zone().path_to(V6ZoneWorld.MERCHANT).size() > 0,"Merchant can be reached by touch pathfinding")

    var potion_before: int = bag.potions
    var gold_before: int = campaign.gold
    _check(campaign.shop_purchase("potion",bag),"Shop sells potions")
    _check(bag.potions == potion_before+1 and campaign.gold == gold_before-24,"Purchase is atomic")
    _check(not campaign.shop_purchase("forge_power",bag),"Cannot forge without gold and crystals")
    campaign.gold = 250
    campaign.crystals = 4
    _check(campaign.shop_purchase("forge_power",bag),"Weapon forging succeeds")
    _check(campaign.forge_power == 1 and campaign.crystals == 2,"Forging charges required crystals")
    _check(campaign.shop_purchase("forge_armor",bag),"Armor forging succeeds")
    _check(campaign.forge_armor == 1 and campaign.crystals == 0,"Armor upgrade applies")
    _check(not campaign.shop_purchase("forge_armor",bag),"Forging requires remaining crystals")

    var patrol := V3Battle.new(bag)
    patrol.create(progress,"raider")
    campaign.apply_battle_modifiers(patrol)
    _check(patrol.attack_power(patrol.unit_by_id("warden")) >= 10,"Permanent forged power added")
    _check(patrol.armor(patrol.unit_by_id("warden")) >= 5,"Permanent forged armor added")
    _check(patrol.unit_by_id("raider").alive() and not patrol.unit_by_id("shaman").alive(),"Single patrol battle")
    patrol.unit_by_id("warden").hurt(12)
    gold_before = campaign.gold
    var loot: Dictionary = campaign.record_battle("raider",true,patrol)
    _check(int(loot["gold"]) > 0 and campaign.gold > gold_before,"Secure-random victory loot awarded")
    _check(campaign.crystals >= 1 and campaign.achievements.has("first_victory"),"First victory unlocks crystal and badge")
    _check(int(campaign.party_wounds.get("warden",0)) == 12,"Wounds survive after battle")
    _check(campaign.shop_purchase("rest",bag),"Camp restores persistent wounds")
    _check(campaign.party_wounds.is_empty(),"Party full restoration works")
    gold_before = campaign.gold
    _check(not campaign.shop_purchase("rest",bag) and campaign.gold == gold_before,"Fully healed party cannot waste gold")
    _check(campaign.record_battle("raider",false,patrol)["gold"] <= 0,"Defeat penalizes gold fairly")

    campaign.zones[0].quest_started = true
    campaign.zones[0].cleared = {"raider":true,"shaman":true,"boss":true}
    campaign.zones[0].quest_claimed = true
    _check(campaign.travel(1) and campaign.chapter == 1,"Quest unlocks Glimmerfen")
    var fen: V6ZoneWorld = campaign.current_zone()
    _check(fen.terrain(Vector2i(2,2)) == "snow" and fen.passable(Vector2i(2,2)),"Glimmerfen is icy yet traversable")
    fen.player = V5WorldState.ELDER
    _check(fen.inspect(bag)["kind"] == "dialogue" and fen.quest_started,"Oracle offers second act quest")
    var frost := V3Battle.new(bag)
    frost.create(progress,fen.battle_key("raider"))
    _check(frost.encounter_tier == 1 and frost.unit_by_id("raider").alive() and not frost.unit_by_id("ashfang").alive(),
        "Icy patrol uses one enemy and distinct regional modifiers")
    _check(frost.unit_by_id("raider").name == "Frost Stalker","Regional enemy identity")
    fen.cleared = {"raider":true,"shaman":true,"boss":true}
    fen.quest_claimed = true
    _check(campaign.travel(2) and campaign.chapter == 2,"Second chapter unlocks Skyvault")
    var void_boss := V3Battle.new(bag)
    void_boss.create(progress,campaign.current_zone().battle_key("boss"))
    _check(void_boss.encounter_tier == 2,"Final battle tier recognized")
    _check(void_boss.unit_by_id("ashfang").name == "The Star-Eater","Final boss original identity")
    _check(void_boss.unit_by_id("ashfang").health > 95,"Final boss has scaled health")
    _check(campaign.journal().contains("Skyvault") and campaign.journal().contains("Glimmerfen"),"Journal shows all chapters")

    var save: Dictionary = campaign.to_dict()
    var revived := V6Campaign.new()
    _check(revived.restore(save),"Campaign restores three areas")
    _check(revived.chapter == 2 and revived.forge_power == 1,"World and forge state preserved")
    _check(revived.achievements.has("first_victory"),"Achievements survive save")
    var corrupted: Dictionary = save.duplicate(true)
    corrupted["zones"][1]["cleared"]["boss"] = true
    corrupted["zones"][1]["cleared"]["raider"] = false
    _check(not revived.restore(corrupted),"Corrupt story prerequisites rejected")
    _check(revived.chapter == 2,"Rejected save does not mutate previous state")

    campaign.difficulty = V6Campaign.VETERAN_DIFFICULTY
    var veteran := V3Battle.new(bag)
    veteran.create(progress,"void_shaman")
    var old_power: int = veteran.unit_by_id("shaman").power
    campaign.apply_battle_modifiers(veteran)
    _check(veteran.unit_by_id("shaman").power == old_power+2,"Veteran difficulty increases enemy power")
    _check(veteran.unit_by_id("shaman").alive() and not veteran.unit_by_id("ashfang").alive(),"Regional shaman encounter filtered")

    if errors == 0:
        print("V06 CAMPAIGN ECONOMY AND BATTLE RULES PASSED")
    quit(1 if errors > 0 else 0)

func _check(ok: bool, message: String) -> void:
    if ok:
        print("PASS V06: "+message)
    else:
        errors += 1
        push_error("FAIL V06: "+message)
