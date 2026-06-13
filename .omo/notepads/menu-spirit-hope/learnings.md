# Learnings: Main Menu UX Specification

- **Style Consistency**: The "Limpio / Etéreo" style requires a minimalist approach with translucent panels and no heavy borders, which has been integrated into the UX spec.
- **Godot 4.6 Dual-Focus**: Since the project uses Godot 4.6, the UX spec explicitly accounts for both mouse and keyboard/gamepad navigation (dual-focus), including focus_neighbor_* properties.
- **Localization Strategy**: All UI text is documented to use tr() keys (e.g., MENU_START) to ensure localization readiness from the design phase.
- **Layout Precision**: A centered VBoxContainer at 1920x1080 resolution ensures a balanced and focused presentation for the main navigation.
- **Boot Screen Implementation**: `src/ui/boot_screen.tscn` uses a full-rect `Control` root, black `ColorRect`, centered `VBoxContainer`, gray `Panel` logo placeholder, and localized placeholder label.
- **Boot Screen Transition**: `src/ui/boot_screen.gd` uses Godot 4.x `create_tween()` with fade in, 2s hold, fade out, then `get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")` per ADR guidance.
- **Main Menu Implementation**: `src/ui/main_menu.tscn` now follows the boot screen layout pattern with a full-rect themed `Control`, centered `VBoxContainer`, and three vertically focused buttons.
- **Main Menu Navigation**: Button focus neighbors are explicitly set in both directions to support Godot 4.6 keyboard/gamepad focus navigation, wrapping from Start to Quit and Quit to Start for complete vertical traversal.
- **Main Menu Script**: `src/ui/main_menu.gd` uses `@onready` button references, typed signal connections, `tr()` localization keys, default focus on Start, ADR-001 `change_scene_to_file()` transitions, and `get_tree().quit()` for Exit.
- **Credits Stub Implementation**: `src/ui/credits_stub.tscn` mirrors the main menu full-rect themed `Control` and centered `VBoxContainer`, with localized title/back controls and explicit self focus neighbors on the single Back button for Godot 4.6 focus behavior.
- **Credits Stub Script**: `src/ui/credits_stub.gd` uses `@onready` references, typed `pressed.connect(_on_back_pressed)`, `tr()` localization keys, default focus on Back, and ADR-001 `get_tree().change_scene_to_file()` to return to the main menu.
