# Stage 1 Introduction Dialogue

**Title:** Stage 1 Introduction Dialogue

**What it does:** Provides all spoken and narrated dialogue for Level 1 (The Neighborhood). It introduces the mystery, teaches movement and interaction, runs the Mrs. Willow cat quest (box puzzle + notebook reward), and sends the player to Mr. Pines for the park hint. Dialogue is written for the Godot Dialogue Manager addon and is used by NPCs and the tutorial balloon.

**Where it lives:**

- **Dialogue scripts:** `dialogue/introduction/characters/*.dialogue` — one file per character (MC, Mrs_Willow, Mr_Pines).
- **Character info:** `dialogue/introduction/characters/*.md` — one markdown file per character with role, personality, appearance, and voice notes.
- **Reference:** `context/dialogue/Basic_Dialogue.md` (syntax), `context/dialogue/dialouge_generator_prompt.md` (generation rules).

**How to use / key behavior:**

- **Entry point:** Each NPC’s conversation starts at the title `start`. Use `DialogueManager.show_dialogue_balloon(dialogue_resource, "start")` with the correct resource (e.g. Mrs_Willow.dialogue).
- **MC.dialogue:** Use for tutorial / spawn narration (e.g. “Mom says some strange things…”). MC lines in NPC conversations appear as player choices inside the NPC’s `.dialogue` file.
- **Mrs. Willow:** Main quest giver. Branches: help vs refuse (failure branch), push crate vs find latch (hidden interaction), pick up cat vs wait. Ends with notebook gift and hint to talk to Mr. Pines.
- **Mr. Pines:** Second NPC. Discusses night noises, gives park and gate hints. Optional “shop secrets” branch foreshadows the inventor (Level 3). “Just browsing” loops back to `start`.
- **Nodes used:** `~ start`, `~ searchYard`, `~ lookForCat`, `~ failureState`, `~ hiddenInteraction`, `~ tutorialComplete` (Mrs. Willow); `~ start`, `~ noiseTopic`, `~ adviceTopic`, `~ parkHint`, `~ shopSecrets` (Mr. Pines). All conversations end with `=> END`.

**Notes:**

- Dialogue Manager expects `.dialogue` files; ensure each resource is added in the Godot project and the balloon/scene is configured to show the correct resource and title.
- Character names in the script (e.g. “Mrs. Willow”, “Mr. Pines”) must match what the balloon or UI uses for the speaker label.
