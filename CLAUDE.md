# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

**Case#0** is a first-person horror/exploration game built in Godot 4.6. The player explores an environment, manages an inventory system, and avoids an enemy AI (vii) that roams and hunts the player.

## Building and Running

- **Open the project:** Use Godot 4.6+ and open the project directory. The engine will load `project.godot`.
- **Run the game:** Press F5 or click the Play button in the editor. The main scene is `res://Scenes/Test Platform.tscn`.
- **Run in fullscreen:** The game launches in exclusive fullscreen automatically (set in `Scripts/Player.gd` _ready).
- **Debug with editor:** Any GDScript changes are hot-reloaded. Use the Output console (View > Output) to see print() statements and errors.

## Project Structure

```
.
├── Scripts/                    # Core gameplay systems
│   ├── Player.gd             # Player movement, camera, interaction, audio
│   ├── Flashlight.gd         # Flashlight mechanics with battery system
│   ├── door.gd               # Door interaction logic
│   ├── Objective UI.gd       # Objective UI display
│   └── Test Platform.gd      # Main scene setup
├── Scenes/                     # Scene files (.tscn)
│   ├── Player.tscn           # Player character scene
│   ├── vii.tscn              # Enemy AI scene
│   ├── ItemPickup.tscn       # Item pickup interaction scene
│   ├── Flashlight.tscn       # Flashlight item scene
│   ├── Test Platform.tscn    # Main level/test scene
│   └── ...
├── Assets/                     # Art and item assets
│   └── items/
│       ├── flashlight.tres    # Flashlight ItemData resource
│       ├── flashlight_icon.jpg
│       └── Bed.tscn          # Bed model scene
├── Audio/                      # Sound effects and ambience
│   └── Player/
│       ├── footstep1.mp3
│       ├── heartbeat-sound-chase.mp3
│       └── ...
├── MansionThingsGodot/        # Mansion-specific models/logic
│   └── drawer.gd             # Drawer interaction
├── Inventory.gd              # Autoload (singleton) for inventory management
├── ItemData.gd               # Custom resource class for item definitions
└── project.godot             # Godot project configuration
```

## Core Systems

### Player Controller (Scripts/Player.gd)
- **Movement:** WASD keys for movement, Spacebar to jump, mouse for camera
- **Input mapping:** Defined in project.godot (move_forward, move_backward, move_left, move_right, jump, pick_up, drop, flashlight, interact, slot_1-4)
- **Features:**
  - Head bob while walking (configurable bobFrequency, bobAmplitudeX/Y)
  - Footstep audio at intervals (footstepInterval = 0.25s)
  - Heartbeat audio when near enemy (heartbeatRadius = 7.5 units)
  - Random ambience sounds
  - Physics-based movement with gravity and jump force
  - Object pickup/drop mechanics (pickedObject, objectPullPower)
  - Hand and ItemHand visual nodes for first-person view

### Inventory System (Inventory.gd)
- **Type:** Autoload (singleton) - accessible globally as `Inventory`
- **Structure:** 4-slot hotbar (configurable HOTBAR_SIZE)
- **Key signals:** `inventory_changed`, `slot_selected`
- **Battery system:** current_battery / max_battery (used by flashlight)
- **Methods:**
  - `add_item(item)` - Add item to first available slot
  - `select_slot(index)` - Select active hotbar slot
- **Default:** Flashlight starts equipped

### Enemy AI (Scenes/vii.gd)
- **States:** ROAMING → CHASING → STUNNED (state machine)
- **Navigation:** Uses NavigationAgent3D for pathfinding
- **Behavior:**
  - Roams within roam_radius (10 units) of origin
  - Detects player at detect_radius (12 units)
  - Chases at chase_speed (5.5) when player detected
  - Stuns for stun_duration (3s) when stunned
  - Picks random roam targets within radius
- **Detection:** Checks player distance every frame in _roaming state

### Item System
- **ItemData resource (ItemData.gd):** Defines item properties
  - item_name, icon, mesh_scene, item_type, target_use
- **ItemPickup (Scenes/ItemPickup.gd):** Area3D that calls player.pickup_item() on interact
  - Instantiates mesh_scene from ItemData when ready
  - Removes itself after pickup
- **Hotbar UI (Scenes/Hotbar.gd):** Displays active hotbar slots

### Flashlight (Scripts/Flashlight.gd)
- **Input:** C key to toggle on/off (when equipped)
- **Battery:** Drains 1 unit per frame when on; stops if battery empty
- **UI:** Battery progress bar displayed when equipped
- **Light:** SpotLight3D with 16x energy when on, 0 when off

### Interactive Objects
- **Doors (Scripts/door.gd):** Door opening/closing logic
- **Drawers (MansionThingsGodot/drawer.gd):** Drawer interaction
- **All use:** Interaction detection from player's Camera3D/Interaction node

## Key Patterns

### Input Handling
- Use Input.is_action_just_pressed() / Input.is_action_pressed() for input checks
- All actions defined in project.godot [input] section
- Actions: move_forward/backward/left/right, jump, pick_up, drop, flashlight, interact, slot_1-4

### Item Ownership and Usage
- Items have `target_use` field (string) that defines how they're used
- Player tracks `current_item` and `item_target_use` for active item behavior
- Items can be equipped in hotbar slots and interacted with via C key (flashlight) or E key (generic interact)

### Audio Management
- AudioStreamPlayer nodes in player scene for: footsteps, heartbeat, ambience
- Played via `player.play()` with optional stream parameter
- Ambience uses randomization (ambienceTimer, ambienceInterval)

### Physics and Movement
- Player extends CharacterBody3D for physics
- Enemy (vii) uses NavigationAgent3D for pathfinding
- Use velocity property and call move_and_slide() in _physics_process
- Gravity applied every frame

### Signals
- Inventory emits inventory_changed and slot_selected
- Connect in UI scripts to update display (Hotbar.gd)

## Important Settings

- **Main scene:** res://Scenes/Test Platform.tscn
- **Mouse mode:** Captured (Input.MOUSE_MODE_CAPTURED) for FPS
- **Display mode:** Exclusive fullscreen
- **Look sensitivity:** 0.2 (adjustable in Player.gd)
- **Gravity:** 30.0 (adjustable export var)

## Development Notes

- Scene files (.tscn) are the primary way to compose the game; GDScript provides logic
- Use @export vars in scripts for easy tweaking in the editor
- Use @onready for node references (loaded after _enter_tree)
- Use NavigationAgent3D for enemy/NPC pathfinding (requires NavigationRegion3D in the level)
- Camera is a child of the player; look angles managed in Player.gd
- Items are resources (ItemData) to allow reuse and easy configuration
