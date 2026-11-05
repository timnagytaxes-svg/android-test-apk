extends "res://v05/world_game.gd"

const GAME_SAVE_PREFIX: String = "user://ironbound_v06_slot_"
var campaign := V6Campaign.new()
var save_slot: int = 1
var overlay: Control
var overlay_title: Label
var overlay_text: Label
var overlay_actions: VBoxContainer
var overlay_mode: String = ""
var story_title: Label
var menu_row: HBoxContainer
var _returning: bool = false
var _save_store := V6SaveStore.new()
var _sound: V6Sound

func _ready() -> void:
    super._ready()
    _install_world()
    _install_menu()
    _install_overlay()
    _sound = V6Sound.new()
    add_child(_sound)
    game.animate.connect(_play_combat_sound)
    _refresh()
    _open_panel("title")

func _install_world() -> void:
    world = campaign.current_zone()
    world.changed.connect(_on_world_changed)
    campaign.changed.connect(_on_campaign_changed)
    var original: V5WorldView = map_view
    var parent: Node = original.get_parent()
    var position: int = original.get_index()
    parent.remove_child(original)
    original.queue_free()
    var art := V6OverworldArt.new()
    art.size_flags_vertical = Control.SIZE_EXPAND_FILL
    parent.add_child(art)
    parent.move_child(art,position)
    map_view = art
    art.tile_tapped.connect(_on_tile_tapped)
    art.set_world(world)

func _install_menu() -> void:
    var frame: MarginContainer = world_layer.get_child(0) as MarginContainer
    var column: VBoxContainer = frame.get_child(0) as VBoxContainer
    var old_controls: Node = column.get_child(column.get_child_count()-1)
    column.remove_child(old_controls)
    old_controls.queue_free()
    story_title = _label("",16,Color("#edd5a9"))
    story_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    story_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(story_title)
    column.move_child(story_title,2)
    menu_row = HBoxContainer.new()
    menu_row.add_theme_constant_override("separation",5)
    column.add_child(menu_row)
    for entry: Array in [["JOURNAL","journal"],["TOWN","shop"],["PACK","pack"],["SLOTS","slots"],["OPTIONS","settings"]]:
        var button: Button = _button(str(entry[0]),16,55)
        menu_row.add_child(button)
        button.pressed.connect(_open_panel.bind(str(entry[1])))

func _install_overlay() -> void:
    overlay = Control.new()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.visible = false
    add_child(overlay)
    var shade := ColorRect.new()
    shade.color = Color("#091425")
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side: String in ["left","right","top","bottom"]:
        margin.add_theme_constant_override("margin_"+side,22)
    overlay.add_child(margin)
    var panel := VBoxContainer.new()
    panel.add_theme_constant_override("separation",11)
    margin.add_child(panel)
    overlay_title = _label("",31,Color("#e8c681"))
    panel.add_child(overlay_title)
    var exit: Button = _button("RETURN TO ADVENTURE",19,60)
    exit.pressed.connect(_close_panel)
    panel.add_child(exit)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    panel.add_child(scroll)
    overlay_actions = VBoxContainer.new()
    overlay_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    overlay_actions.add_theme_constant_override("separation",11)
    scroll.add_child(overlay_actions)
    overlay_text = _label("",20,Color("#d6e5e9"))
    overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_actions.add_child(overlay_text)

func _close_panel() -> void:
    overlay.visible = false

func _section(content: String) -> void:
    overlay_actions.add_child(_label(content,24,Color("#e9c77e")))

func _panel_button(content: String, action: Callable) -> void:
    var button: Button = _button(content,19,65)
    overlay_actions.add_child(button)
    button.pressed.connect(action)

func _open_panel(kind: String) -> void:
    if not _active_encounter.is_empty():
        return
    overlay_mode = kind
    overlay.visible = true
    for child: Node in overlay_actions.get_children():
        overlay_actions.remove_child(child)
        child.queue_free()
    overlay_text = _label("",20,Color("#d6e5e9"))
    overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_actions.add_child(overlay_text)
    match kind:
        "title":
            overlay_title.text = "IRONBOUND CHRONICLES"
            overlay_text.text = "THE STARFORGER'S OATH\nA complete three-chapter tactical adventure. Explore the realms, master the classes, and restore the dawn."
            var art := TextureRect.new()
            art.texture = preload("res://v06/assets/title_art.svg")
            art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            art.custom_minimum_size = Vector2(0,320)
            overlay_actions.add_child(art)
            overlay_actions.move_child(art,1)
            _panel_button("BEGIN ADVENTURE",_close_panel)
            _panel_button("CONTINUE SAVED ADVENTURE",_open_panel.bind("slots"))
            _panel_button("OPTIONS",_open_panel.bind("settings"))
            _panel_button("CREDITS",_open_panel.bind("credits"))
        "credits":
            overlay_title.text = "IRONBOUND • CREDITS"
            overlay_text.text = "Design, code, world and vector illustrations created for Ironbound Chronicles.\nJRPG character and spell-sheet references were supplied by the game creator.\nEngine: Godot 4.4.1.\nThe game is offline-first and stores saves on the device.\nThis is a playable pre-release campaign."
            _panel_button("RETURN TO TITLE",_open_panel.bind("title"))
        "journal":
            overlay_title.text = "THE IRONBOUND CHRONICLE"
            overlay_text.text = campaign.journal()
            var chapter_data: Dictionary = V6ZoneWorld.ZONE_DATA[campaign.chapter]
            _section("THE WORLD REMEMBERS")
            overlay_actions.add_child(_label(str(chapter_data["lore"]),20,Color("#bbd9f0")))
            if campaign.completed():
                _panel_button("READ THE EPILOGUE",_open_panel.bind("ending"))
        "shop":
            overlay_title.text = "THE WANDERING FORGE"
            overlay_text.text = "A traveling artisan offers restoratives and lasting upgrades.\nGold: %d   Rift Crystals: %d\nUpgrades persist across every battle." % [campaign.gold,campaign.crystals]
            _panel_button("HEALING POTION  •  24 GOLD",_purchase.bind("potion"))
            _panel_button("THREE POTIONS  •  66 GOLD",_purchase.bind("bundle"))
            _panel_button("FORGE WEAPON +2 POWER  •  %d GOLD + 2 CRYSTALS" % (90+campaign.forge_power*70),_purchase.bind("forge_power"))
            _panel_button("FORGE ARMOR +2 ARMOR  •  %d GOLD + 2 CRYSTALS" % (90+campaign.forge_armor*70),_purchase.bind("forge_armor"))
            _section("CAMP")
            _panel_button("REST AND RECOVER  •  15 GOLD",_purchase.bind("rest"))
        "camp":
            overlay_title.text = "THE FIRESIDE CAMP"
            overlay_text.text = "Your companions share food and stories beneath the stars.\nGold: %d\nPersistent wounds: %s" % [campaign.gold, JSON.stringify(campaign.party_wounds)]
            _panel_button("REST FULL PARTY  •  15 GOLD",_purchase.bind("rest"))
            _panel_button("OPEN MERCHANT",_open_panel.bind("shop"))
        "pack":
            overlay_title.text = "THE ADVENTURER'S PACK"
            var summary: Dictionary = game.bag.modifiers()
            overlay_text.text = "Gold %d   •   Crystals %d   •   Potions %d\nEquipped bonuses: +%d POWER / +%d ARMOR / +%d HP\nEquip gear freely while exploring." % [
                campaign.gold,campaign.crystals,game.bag.potions,
                int(summary["power"])+campaign.forge_power*2,int(summary["armor"])+campaign.forge_armor*2,int(summary["hp"])]
            for slot: String in ModuleInventory.SLOTS:
                var worn: String = str(game.bag.equipped.get(slot,""))
                var display: String = "Empty" if worn.is_empty() else str(ModuleInventory.ITEMS[worn]["name"])
                _section("%s: %s" % [slot.to_upper(),display])
                if not worn.is_empty():
                    _panel_button("UNEQUIP "+display,_unequip_world.bind(slot))
            _section("INVENTORY")
            for item_id: String in ModuleInventory.ITEMS.keys():
                if int(game.bag.bag.get(item_id,0)) < 1:
                    continue
                var item: Dictionary = ModuleInventory.ITEMS[item_id]
                _panel_button("EQUIP %s  •  +%d ATK / +%d DEF / +%d HP" % [item["name"],item["power"],item["armor"],item["hp"]],
                    _equip_world.bind(item_id))
        "slots":
            overlay_title.text = "YOUR ADVENTURE • SAVE SLOTS"
            overlay_text.text = "Save the world, character levels, quest outcomes, equipment, gold and difficulty.\nCurrently selected slot: %d" % save_slot
            var chooser := OptionButton.new()
            chooser.custom_minimum_size = Vector2(0,58)
            for index: int in range(3):
                chooser.add_item("Adventure Slot %d" % (index+1))
            chooser.select(save_slot-1)
            chooser.item_selected.connect(_slot_selected)
            overlay_actions.add_child(chooser)
            _panel_button("SAVE CURRENT ADVENTURE",_slot_save)
            _panel_button("LOAD SELECTED ADVENTURE",_slot_load)
            _section("Use a different slot to start a second adventure.")
        "settings":
            overlay_title.text = "GAME OPTIONS"
            overlay_text.text = "Balanced for offline play and touch controls. All scenes are event-driven.\nDifficulty changes apply to new encounters."
            _panel_button("STORY DIFFICULTY",_difficulty.bind(0))
            _panel_button("VETERAN DIFFICULTY",_difficulty.bind(1))
            _panel_button("REDUCE COMBAT MOTION: %s" % ("ON" if campaign.reduced_motion else "OFF"),_toggle_motion)
            _panel_button("MUSIC & EFFECTS: %s" % ("ON" if campaign.sound_enabled else "OFF"),_toggle_sound)
            _panel_button("NEW GAME (UNSAVED PROGRESS RESETS)",_reset_campaign)
            _section("Current difficulty: %s" % ("Veteran" if campaign.difficulty == 1 else "Story"))
        "ending":
            overlay_title.text = "THE DAWN OF IRONBOUND"
            overlay_text.text = "THE END\n\nThe Star-Eater is no more. Hearthwood's fires settle, Glimmerfen's moon shines freely, and the Skyvault opens to a blue morning.\n\nRowan, Elira, and Caldor gather with your companions as the Hall of Ages records the names of the four who stood against the end of night.\n\nYour journey is complete. Adventure remains in the places you saved.\n\nCREDITS\nWorld, systems and original vector illustrations created for Ironbound Tactics.\nOriginal character and effect references supplied by the game creator.\nBuilt in Godot 4 with GDScript."
            _panel_button("VIEW YOUR ACHIEVEMENTS",_open_panel.bind("journal"))
            _panel_button("RETURN TO THE WORLD",_close_panel)

func _purchase(product: String) -> void:
    if campaign.shop_purchase(product,game.bag):
        if _sound != null:
            _sound.play_sfx("shop")
        _save_world(true)
    _refresh()
    _open_panel("camp" if overlay_mode == "camp" else "shop")

func _equip_world(item_id: String) -> void:
    if game.bag.equip(item_id):
        _message = "%s equipped." % str(ModuleInventory.ITEMS[item_id]["name"])
        _save_world(true)
    _open_panel("pack")
    _refresh()

func _unequip_world(slot: String) -> void:
    if game.bag.unequip(slot):
        _message = "Equipment returned to your pack."
        _save_world(true)
    _open_panel("pack")
    _refresh()

func _slot_selected(index: int) -> void:
    save_slot = index+1
    _open_panel("slots")

func _slot_save() -> void:
    var ok: bool = _save_world()
    overlay_text.text = "Adventure saved to Slot %d." % save_slot if ok else "Save failed. Check device storage."

func _slot_load() -> void:
    if _load_world():
        _close_panel()
    else:
        overlay_text.text = "This slot has no valid saved adventure."

func _difficulty(value: int) -> void:
    campaign.difficulty = value
    _message = "Difficulty is now %s for future battles." % ("Veteran" if value == 1 else "Story")
    _save_world(true)
    _refresh()
    _open_panel("settings")

func _toggle_sound() -> void:
    campaign.sound_enabled = not campaign.sound_enabled
    if _sound != null:
        _sound.set_enabled(campaign.sound_enabled)
    _save_world(true)
    _open_panel("settings")

func _play_combat_sound(event: Dictionary) -> void:
    if _sound == null:
        return
    var kind: String = str(event.get("kind","attack"))
    _sound.play_sfx("potion" if kind in ["mend","potion"] else ("spell" if kind in ["ember","frost","arc","surge"] else "hit"))

func _toggle_motion() -> void:
    campaign.reduced_motion = not campaign.reduced_motion
    _save_world(true)
    _open_panel("settings")

func _reset_campaign() -> void:
    _stop_walk()
    campaign = V6Campaign.new()
    campaign.changed.connect(_on_campaign_changed)
    game.generation += 1
    game.bag = ModuleInventory.new()
    game.progression = V4Progression.new()
    _change_world(campaign.current_zone())
    if _sound != null:
        _sound.set_enabled(true)
    _message = "A new adventure begins. Your saved slot remains until you save again."
    _close_panel()
    _refresh()

func _on_campaign_changed(message: String) -> void:
    _message = message
    _refresh()

func _change_world(next: V6ZoneWorld) -> void:
    world = next
    if not world.changed.is_connected(_on_world_changed):
        world.changed.connect(_on_world_changed)
    map_view.set_world(world)
    _refresh()

func _refresh() -> void:
    super._refresh()
    if story_title == null or campaign == null or title_label == null:
        return
    var info: Dictionary = V6ZoneWorld.ZONE_DATA[campaign.chapter]
    title_label.text = "IRONBOUND  •  %s" % str(info["name"]).to_upper()
    story_title.text = "CHAPTER %d OF 3  •  %s" % [campaign.chapter+1, str(info["subtitle"])]
    status_label.text = "LV %d  •  %s  •  %d GOLD  •  %d POTIONS  •  %d CRYSTALS" % [
        int(game.progression.heroes["warden"]["level"]),
        str(V4Progression.CLASSES[game.progression.hero_class]["name"]).to_upper(),
        campaign.gold, game.bag.potions, campaign.crystals]

func _interact_here() -> void:
    var place: String = (world as V6ZoneWorld).location_id(world.player)
    match place:
        "merchant":
            if _sound != null:
                _sound.play_sfx("ui")
            _open_panel("shop")
        "camp":
            if _sound != null:
                _sound.play_sfx("ui")
            _open_panel("camp")
        "chronicle": _open_panel("journal")
        "gate_forward":
            if campaign.travel(campaign.chapter + 1):
                if _sound != null:
                    _sound.play_sfx("portal")
                _stop_walk()
                _change_world(campaign.current_zone())
                _message = "A new chapter begins: " + str(V6ZoneWorld.ZONE_DATA[campaign.chapter]["story"])
                _save_world(true)
            else:
                _message = "The road is sealed. Complete this chapter and claim your reward first."
            _refresh()
        "gate_back":
            if campaign.travel(campaign.chapter - 1):
                if _sound != null:
                    _sound.play_sfx("portal")
                _stop_walk()
                _change_world(campaign.current_zone())
                _message = "You return to %s." % str(V6ZoneWorld.ZONE_DATA[campaign.chapter]["name"])
                _save_world(true)
            _refresh()
        _:
            var was_opened: bool = (world as V6ZoneWorld).chest_opened
            super._interact_here()
            if not was_opened and (world as V6ZoneWorld).chest_opened:
                campaign.treasures_found += 1
                campaign._award_badge("treasure_hunter")
                _save_world(true)
            if campaign.completed():
                _save_world(true)
                _open_panel("ending")

func _launch_battle(encounter: String) -> void:
    if not _active_encounter.is_empty():
        return
    _stop_walk()
    _close_panel()
    if _sound != null:
        _sound.set_theme("battle")
    _active_encounter = encounter
    _returning = false
    game.new_encounter(false, (world as V6ZoneWorld).battle_key(encounter))
    campaign.apply_battle_modifiers(game.battle)
    battle_screen = BATTLE_SCENE.instantiate() as Control
    battle_screen.set("injected_game", game)
    battle_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    battle_screen.connect("return_to_world", _return_from_battle)
    battle_layer.add_child(battle_screen)
    var combat_stage: V3Stage = battle_screen.get("stage") as V3Stage
    if combat_stage != null:
        combat_stage.reduced_motion = campaign.reduced_motion
    world_layer.visible = false
    battle_layer.visible = true
    game._publish()

func _return_from_battle() -> void:
    if _returning or _active_encounter.is_empty() or game.battle == null or not game.battle.finished:
        return
    _returning = true
    var result: bool = game.battle.result == "VICTORY"
    campaign.record_battle(_active_encounter,result,game.battle)
    if _sound != null:
        _sound.play_sfx("victory" if result else "defeat")
        _sound.set_theme("world")
    super._return_from_battle()
    _returning = false
    _refresh()

func _save_world(silent: bool = false) -> bool:
    if not _active_encounter.is_empty():
        return false
    var payload: Dictionary = {
        "schema": 6,
        "campaign": campaign.to_dict(),
        "inventory": game.bag.to_dict(),
        "progression": game.progression.to_dict()
    }
    var ok: bool = _save_store.save(save_slot, payload)
    if not silent:
        _message = "Adventure saved in Slot %d." % save_slot if ok else "Save failed."
    _refresh()
    return ok

func _load_world() -> bool:
    if not _active_encounter.is_empty():
        return false
    _stop_walk()
    var raw: Dictionary = _save_store.load(save_slot)
    if int(raw.get("schema",0)) != 6 or not raw.get("campaign") is Dictionary or not raw.get("inventory") is Dictionary or not raw.get("progression") is Dictionary:
        _message = "No valid adventure in Slot %d. Checked primary and backup." % save_slot
        _refresh()
        return false
    var next_campaign := V6Campaign.new()
    var next_bag := ModuleInventory.new()
    var next_progress := V4Progression.new()
    if not next_campaign.restore(raw["campaign"]) or not next_bag.restore(raw["inventory"]) or not next_progress.restore(raw["progression"]):
        _message = "Save validation failed. Existing progress was not changed."
        _refresh()
        return false
    campaign = next_campaign
    campaign.changed.connect(_on_campaign_changed)
    game.bag = next_bag
    game.progression = next_progress
    game.generation += 1
    _change_world(campaign.current_zone())
    if _sound != null:
        _sound.set_enabled(campaign.sound_enabled)
    _message = "Slot %d restored. Welcome back!" % save_slot
    _refresh()
    return true
