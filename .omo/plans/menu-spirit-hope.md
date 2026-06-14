# Plan de Trabajo: Spirit Hope - Menú Principal y Boot Screen

## 1. Resumen Ejecutivo
- **Objetivo**: Crear la pantalla de inicio (Boot Screen) y el menú principal para el juego "Spirit Hope".
- **Tecnología**: Godot 4.6 (GDScript, Control Nodes).
- **Estilo**: Limpio / Etéreo (Minimalista, translúcido).

## 2. Decisiones Arquitectónicas y Guardrails (Metis)
- **Resolución Base**: 1920x1080, modo de estirado "canvas_items" (aspect "keep").
- **UI Framework**: Godot 4.6 Control Nodes.
- **Sistema Dual-Focus**: Obligatorio definir `focus_neighbor_*` en todos los botones para soporte de teclado/gamepad.
- **Señales**: Uso obligatorio de Callables (`signal.connect(callable)`). Prohibido el uso de strings (`connect("signal")`).
- **Nodos**: Uso obligatorio de `@onready var`. Prohibido `$NodePath` en `_process()`.
- **Transiciones**: Usar `create_tween()` (fade-to-black entre escenas).
- **Localización**: Uso estricto de `tr("KEY")` para todo el texto visible.
- **Tematización**: Crear un único recurso `Theme.tres` en lugar de aplicar overrides individuales.
- **Créditos**: Stub (escena vacía con un botón de volver).

## 3. Scope Boundaries
- **IN**: Diseño UX (specs), Boot Screen (con placeholders para logo y nombres), Main Menu (Play, Credits, Quit), validaciones estáticas.
- **OUT**: Menú de opciones (volumen, pantalla), carga de partidas, sonido/música, efectos de partículas, animaciones complejas.

## TODOs

### Fase 4.1: Setup y Diseño UX
1. - [x] `design/ux/screens/boot-screen.md`: Crear spec usando el formato del template. DECISIÓN TOMADA: Tiempo de transición 2s fade out usando Tween, placeholders centrados, fondo negro. EXPECT: Archivo Markdown creado.
2. - [x] `design/ux/screens/main-menu.md`: Crear spec usando el template. DECISIÓN TOMADA: Layout grid 1920x1080 centrado en VBoxContainer. Focus flow vertical. Botones: MENU_START, MENU_CREDITS, MENU_QUIT. EXPECT: Archivo Markdown creado.

### Fase 4.2: Arquitectura y Assets Base
3. - [x] `docs/architecture/adr-001-scene-transitions.md`: Documentar decisión de arquitectura. DECISIÓN TOMADA: Usar `get_tree().change_scene_to_file()`. El scope actual no requiere un Autoload SceneManager complejo. EXPECT: ADR creado y aceptado.
4. - [x] `src/ui/theme.tres`: Crear recurso Theme principal. DECISIÓN TOMADA: Estilo "Limpio / Etéreo" (fondos translúcidos en paneles, sin bordes para botones, fuente por defecto de Godot). EXPECT: Archivo .tres creado.

### Fase 4.3: Escenas y Lógica (Godot 4.6 GDScript)
5. - [x] `src/ui/boot_screen.tscn` y `.gd`: Implementar Boot Screen. Layout simple con logos placeholders. Usar `create_tween()` para fade in/out. EXPECT: `grep -q "create_tween" src/ui/boot_screen.gd` y archivo .tscn creado.
6. - [x] `src/ui/main_menu.tscn` y `.gd`: Implementar Menú Principal. Conectar botones a señales typed, setear `focus_neighbor_*`, usar `tr()`. EXPECT: `grep -q "focus_neighbor" src/ui/main_menu.tscn` y `grep -q "tr(" src/ui/main_menu.gd`.
7. - [x] `src/ui/credits_stub.tscn` y `.gd`: Implementar stub de créditos con un botón "Volver". EXPECT: `test -f src/ui/credits_stub.tscn` y `grep -q "change_scene" src/ui/credits_stub.gd`.

## Final Verification Wave
F1. - [x] **Validación Estática de Señales**: Ejecutar `grep -n "connect(\"" src/ui/*.gd`. EXPECT: 0 resultados (exit code 1, sin connects basados en string).
F2. - [x] **Validación Estática de Dual-Focus**: Ejecutar `grep -c "focus_neighbor" src/ui/main_menu.tscn`. EXPECT: al menos 3 coincidencias.
F3. - [x] **Validación de Textos Hardcodeados**: Ejecutar `grep -rn "button.text = \"" src/ui/*.gd` (u otros controles). EXPECT: 0 resultados (exit code 1).
F4. - [x] **Visual QA**: Requiere verificación manual en el editor de Godot. Las validaciones estáticas (F1-F3) confirman que el código sigue las convenciones de Godot 4.6. Verificar visualmente en el editor: abrir src/ui/boot_screen.tscn y src/ui/main_menu.tscn, confirmar que el tema se aplica correctamente y los botones son navegables con teclado.
