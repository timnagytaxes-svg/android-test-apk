class_name V6CompanionStories
extends RefCounted

# Nine original camp conversations reveal the party's motivations over 3 acts.
const STORIES: Dictionary = {
    "mira": [
        {"title": "The Last Lantern",
         "text": "Mira sits beside the fire, polishing a battered silver lantern. \"I carried this through the night the infirmary burned. We saved everyone but the light went out. I promised I wouldn't lose another home.\"\n\nShe smiles. \"You don't have to carry this quest alone.\""},
        {"title": "The Mirror Beneath the Ice",
         "text": "Mira looks over Glimmerfen's frozen water. \"The Oracle says the marsh remembers every promise. I once believed strength meant being untouched by fear. Now I think it means choosing to heal while you're afraid.\""},
        {"title": "A Dawn Worth Keeping",
         "text": "Mira offers the lantern to the morning wind. \"There is no perfect victory,\" she says softly. \"But if the children in Hearthwood grow up never knowing the sound of this war, that will be enough.\""}
    ],
    "lyra": [
        {"title": "The Map of Falling Stars",
         "text": "Lyra spreads an ink-stained star chart across the camp table. \"My academy called these comets a mathematical impossibility. I said the sky was trying to warn us. They laughed.\"\n\nShe traces a line. \"I would rather be wrong beside friends than right in a locked tower.\""},
        {"title": "An Unwritten Spell",
         "text": "Lyra closes her grimoire. \"The ice in this marsh doesn't obey the laws I know. Maybe magic isn't about controlling the world. Maybe it's about listening until it tells you what it needs.\""},
        {"title": "The Last Equation",
         "text": "Lyra tears the page from her notebook. \"I used to calculate everything. But I cannot calculate courage, or why a person stays when they could run.\" She looks around at the party. \"I'm glad my calculations were incomplete.\""}
    ],
    "kestrel": [
        {"title": "An Honest Thief",
         "text": "Kestrel tosses a copper coin into the firelight. \"I stole from the Rift cult before anyone knew what they were. They hired me to deliver a letter. I opened it instead. That's how I learned where the patrols were going.\"\n\nHe catches the coin. \"It's about time I used these hands for something decent.\""},
        {"title": "A Promise in the Reeds",
         "text": "Kestrel checks the straps on his boots. \"I grew up in a marsh like this. Back then, every bridge was a way out. Funny thing. Now I spend my days building ways back for the people who got lost.\""},
        {"title": "The Door Left Open",
         "text": "Kestrel sets down a bundle of keys. \"No one trusted me when I arrived. I didn't even trust myself. When this is over, I might open a place for those who have nowhere to return to. Keep a door open for someone.\""}
    ]
}

func conversation(actor_id: String, chapter: int) -> Dictionary:
    if not STORIES.has(actor_id) or chapter < 0 or chapter >= 3:
        return {}
    return STORIES[actor_id][chapter].duplicate()
