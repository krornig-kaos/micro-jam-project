# UX Specification: Boot Screen

## Overview
The Boot Screen is the first visual element players see when launching "Spirit Hope". Its purpose is to establish the game's identity and credit the development team. It follows a minimalist, professional aesthetic aligned with the "Limpio / Etéreo" project style.

## Layout
The screen uses a centered vertical layout to maintain focus.

- **Root**: `Control` node with "Full Rect" anchors.
- **Container**: `VBoxContainer` centered within the root.
- **Logo Placeholder**: `TextureRect` or `Panel` for the team logo.
- **Text Labels**: `Label` nodes for team names, positioned below the logo.

## Timing
- **Total Display Duration**: 2 seconds.
- **Animation**: The screen remains static for the duration before triggering the transition.
- **Logic**: A `Timer` or `await get_tree().create_timer(2.0).timeout` handles the sequence.

## Visual Style
- **Background**: Solid black (#000000).
- **Theme**: Minimalist and ethereal.
- **Color Palette**:
  - Background: #000000
  - Text/Placeholders: Light gray or white with slight translucency.

## Transition
- **Method**: Fade out to black.
- **Implementation**: Uses a `Tween` to animate the `modulate:a` property of the root node or a black overlay from 1.0 to 0.0 (or vice versa depending on implementation strategy).
- **Action**: Upon completion of the fade out, the game calls `get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")`.

## Placeholders
- **Team Logo**: A gray rectangle (`Panel` node) representing the future logo asset.
- **Team Names**: Simple `Label` nodes with default font, containing placeholder names for team members.
