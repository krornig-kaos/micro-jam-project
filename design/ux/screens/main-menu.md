# UX Specification: Main Menu

## Overview
The Main Menu is the primary navigation hub of "Spirit Hope". It provides access to the core gameplay, credits, and the option to exit. The design focuses on clarity and atmospheric immersion, following the "Limpio / Etéreo" style to establish a sense of calm and mystery from the start.

## Layout
The screen is designed for a base resolution of 1920x1080.

- **Root**: `Control` node with "Full Rect" anchors.
- **Background**: `ColorRect` or `TextureRect` with a subtle gradient or transparency to maintain the ethereal aesthetic.
- **Menu Container**: `VBoxContainer` centered within the root node.
  - **Alignment**: Centered horizontally and vertically.
  - **Spacing**: Adequate separation between buttons for clarity.

## Buttons
The menu features three primary buttons, each using localization keys for text.

1. **MENU_START**
   - **Text**: `tr("MENU_START")` ("Comenzar partida")
   - **Purpose**: Transitions to the main game scene.
2. **MENU_CREDITS**
   - **Text**: `tr("MENU_CREDITS")` ("Créditos")
   - **Purpose**: Opens the credits screen or overlay.
3. **MENU_QUIT**
   - **Text**: `tr("MENU_QUIT")` ("Salir")
   - **Purpose**: Closes the game application.

## Focus Flow
The menu supports both mouse and keyboard/gamepad input (dual-focus system).

- **Navigation**: Vertical flow.
- **Keyboard/Gamepad**: Up and Down arrows or D-pad to move focus between buttons.
- **Focus Neighbors**:
  - `MENU_START`: `focus_neighbor_bottom` points to `MENU_CREDITS`.
  - `MENU_CREDITS`: `focus_neighbor_top` points to `MENU_START`, `focus_neighbor_bottom` points to `MENU_QUIT`.
  - `MENU_QUIT`: `focus_neighbor_top` points to `MENU_CREDITS`.
- **Default Focus**: `MENU_START` is focused by default when the screen loads for non-mouse inputs.

## Visual Style
The "Limpio / Etéreo" style is characterized by minimalism and soft visuals.

- **Panels**: Use translucent backgrounds for any container panels.
- **Borders**: No heavy or high-contrast borders.
- **Typography**: Clean, readable sans-serif font.
- **Feedback**:
  - **Hover/Focus**: Subtle change in opacity or a soft glow effect.
  - **Pressed**: Gentle scale reduction or slight color shift.

## Behavior
- **MENU_START**: Triggers a fade-out transition before loading the initial game level.
- **MENU_CREDITS**: Switches scene to the credits screen or toggles a credits visibility layer.
- **MENU_QUIT**: Invokes `get_tree().quit()` after a brief confirmation (optional) or immediately.
