# My Little Buddy

A fun pet care simulation game where you raise and care for a virtual dog. Manage your pet's needs, handle your finances, chat with NPCs, and experience a complete day cycle. Built with Godot 4.5.

## Quick Navigation

- [**Comments & Formatting**](#1-appropriate-use-of-comments-naming-conventions-and-formatting) (1. Appropriate Use of Comments, Naming Conventions, and Formatting)
- [**Program Modularity**](#2-program-modularity-and-readable-design) (2. Program Modularity and Readable Design)
- [**Data Storage**](#3-data-storage-and-scope-management) (3. Data Storage and Scope Management)
- [**Report Generation**](#4-report-generation) (4. Report Generation)
- [**File Directory**](#5-file-directory-details) (5. File Directory Details)
- [**Libraries & Attribution**](#6-templates-libraries-and-attribution) (6. Templates, Libraries, and Attribution)

---

## 1. Appropriate Use of Comments, Naming Conventions, and Formatting

The codebase follows consistent styling and standard naming conventions to maintain readability. 

- **Naming Conventions**: Variables and functions use `snake_case` (e.g., `dog_breed`, `current_day`, `spend_money()`). Classes and script nodes use `PascalCase` (e.g., `GameState`, `DogState`).
- **Formatting**: Scripts maintain strict indentation and structure based on GDScript guidelines. Signals, variables, and engine hook functions (`_ready`, `_process`) remain grouped sequentially at the top of files.
- **Comments**: Inline comments explain non-obvious logic constraints. Section headers (e.g., `# Finance System`, `# Customizable Costs`) break large files into manageable, readable blocks.

**Example Code (from `scripts/GameState.gd`):**
```gdscript
# Finance System
var weekly_allowance: int = 150
var savings_balance: int = 200 # Starts at $200
```

## 2. Program Modularity and Readable Design

The program separates logic into independent, focused modules. This structure leverages core Object-Oriented Programming (OOP) concepts:

| OOP Concept | Project Implementation |
|-------------|------------------------|
| **Encapsulation (data hiding)** | Internal states like the dog's pathfinding array (`action_path`) or the financial log (`transaction_history`) remain private. Outside nodes interface with these states strictly through public methods like `start_action()` or `spend_money()`. |
| **Inheritance (reusing code)** | Project scripts inherit logic from Godot's built-in nodes. The `dog.gd` script extends `CharacterBody2D` to cleanly inherit physics and collision detection, while `finance_menu.gd` extends `CanvasLayer` to inherit viewport rendering capabilities. |
| **Polymorphism (multiple forms)** | Interaction scripts treat all clickable entities uniformly. Different NPCs execute distinct dialogue trees while sharing a standardized interaction interface mapping to the Dialogue Manager. |
| **Abstraction (simplifying complexity)** | Complex mechanical procedures are masked behind simple references. Calling `GameState.advance_day()` instantly processes supply decay, increments timers, resets local budgets, and fires event signals without exposing the underlying operations to the caller. |

**Example Code (from `scripts/dog.gd`):**
```gdscript
extends CharacterBody2D

# State machine encapsulation
enum DogState {FOLLOWING_PLAYER, GOING_TO_FOOD, GOING_TO_WATER, GOING_TO_SLEEP, SLEEPING}
var current_state: DogState = DogState.FOLLOWING_PLAYER

func start_action(path_name: String, state: DogState, callback: Callable):
	# Abstracted state change and pathfinding initialization
	action_callback = callback
	current_state = state
```

## 3. Data Storage and Scope Management

The project handles game states using precise variable scoping and complex data structures. Variables serve single, clear purposes using explicit data types. For example, `has_prescription: bool` strictly tracks medication requirements, while `target_distance: float` purely controls movement spacing. Variables reliably store data that updates dynamically when necessary, such as adjusting `money -= amount` during item purchases.

- **Arrays and Lists**: A Godot `Array` stores the `transaction_history` chronological ledger (e.g., `[{ "day": 1, "amount": 150 }]`). Map waypoints for AI movement populate into an `Array[Vector2]`.
- **Dictionaries**: Dictionaries hold categorized datasets. The `budget_data` dictionary maps specific spending categories to targeted limits and current expenditures (e.g., `"Food": {"limit": 50, "spent": 0}`).
- **Variable Scope**: Local variables execute isolated temporary math (e.g., calculating `food_pct` exclusively inside `update_overview()`). Persistent cross-scene variables operate safely inside the `GameState` global singleton.

These storage techniques reinforce core OOP principles:

| OOP Concept | Project Implementation |
|-------------|------------------------|
| **Encapsulation (data hiding)** | Write access to internal arrays like `transaction_history` is restricted. New ledger array entries must filter through the `record_transaction()` function wrapper. |
| **Inheritance (reusing code)** | Data serialization mechanisms inherit from Godot's native `FileAccess` class to handle complex dictionary parsing during save state read/write operations. |
| **Polymorphism (multiple forms)** | The `transaction_history` array dynamically holds mixed data classes within its dictionaries (integers for timestamps, floating points for calculations, strings for semantic descriptions). |
| **Abstraction (simplifying complexity)** | Reading complex nested dictionary trees is abstracted. Evaluating the budget abstracts the deep lookup process into a simple function query via `get_budget_status(category)`. |

**Example Code (from `scripts/GameState.gd`):**
```gdscript
# Complex data storage using dictionaries
var budget_data: Dictionary = {
	"Food": {"limit": 50, "spent": 0},
	"Vet": {"limit": 50, "spent": 0}
}

# Transaction history list using arrays
var transaction_history: Array = []

func record_transaction(description: String, amount: int, category: String):
	var entry = {
		"day": current_day,
		"description": description,
		"amount": amount,
		"category": category
	}
	transaction_history.push_front(entry) # Encapsulated array modification
```

## 4. Report Generation

The application dynamically produces a "Weekly Financial Report" module inside the `finance_menu.gd` script. 

- **Calculation**: Computes total player expenditures against base income allowances. Segmented by operational categories such as Food and Vet visits.
- **Presentation**: Generates a consolidated breakdown containing total income received, gross spending, categorical expenditures, and emergency fund depletion.
- **Visuals**: Translates numerical budget consumption into visual UI progress bars. These indicators dynamically shift colors based on hard spending thresholds (e.g., transitioning to red upon passing 100% allocation).

| Presentation Element | Visual Output | Purpose |
|----------------------|---------------|---------|
| **String Formatting** | `Food & Water (80%)` | Clearly maps raw numerical budget percentages into readable UI labels. |
| **Progress Bars** | Visual fill gauge | Transforms abstract category spending logic into an immediately scannable visual format. |
| **Dynamic Colors** | Green / Yellow / Red | Visually alerts the player as their spending thresholds increase toward the weekly limit. |


## 5. File Directory Details

The file tree directly maps to functional project boundaries. 

* **`/addons/`**: Third-party plugin dependencies required for core game mechanics.
* **`/assets/`**: Raw rendering assets, 2D sprites, font families, and audio tracks.
* **`/scenes/`**: Serialized Godot nodes (`.tscn`). Segmented into `/ui/` (interface menus, HUD overlays) and `/maps/` (navigable game environments).
* **`/scripts/`**: Primary logic controllers (`.gd`). 
  - `GameState.gd`: Global singleton managing save files, system time, and core metrics.
  - `finance_menu.gd`: Interface logic translating player actions into the visualized budget logic.
  - `dog.gd`: State machine and vector pathfinding computation for the AI pet.
* **`/dialogues/`**: Dialogue node configurations (`.dialogue`).
* **`project.godot`**: Runtime execution configuration and environment settings.

#### Key Scripts

| Script | Purpose |
|--------|---------|
| `GameState.gd` | Central data hub (money, pet stats, day counter) |
| `MainGame.gd` | Main game loop |
| `player.gd` | Player movement |
| `dog.gd` | Pet AI and needs system |
| `shop_menu.gd` | Shop interface |
| `finance_menu.gd` | Budget tracking |
| `day1_tutorial.gd` | Tutorial system |

## 6. Templates, Libraries, and Attribution

This project operates on Godot Engine v4.5 and integrates open-source dependencies distributed under the MIT License.

| Library | Author | License | Function |
|---------|---------|---------|---------|
| **Godot Engine** | Godot Foundation | MIT | Core engine runtime operation. |
| **Dialogue Manager** | Nathan Hoad | MIT | Parses and executes `.dialogue` syntax for NPC interaction UI. |
| **Scene Manager** | GlassBrick | MIT | Asynchronous scene processing and visual transition effects. |
| **SimpleTODO** | KoBeWi | MIT | In-editor project task tracking and management overlay. |

*Note: Visual game assets (app sprites, environments, audio) are governed by original purchase agreements and remain excluded from generalized open-source redistribution.*
