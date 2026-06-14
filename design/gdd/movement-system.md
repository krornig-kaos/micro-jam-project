# GDD: Movement and Stealth System

## 1. Overview
El sistema de movimiento y sigilo del jugador permite desplazarse en perspectiva top-down en 8 direcciones, correr (sprint), entrar en modo sigilo silencioso (tecla C) para evadir la detección acústica, y esconderse en arbustos (hierba/hongos) para evadir la visión. Además, incluye oclusión visual dinámica de sombras (Niebla de Guerra) y un sistema de emisión de ruido basado en el movimiento.

## 2. Player Fantasy
El jugador debe sentir tensión acústica y visual. Al correr o caminar, el sonido de sus pasos puede alertar a los enemigos a través de los obstáculos, forzándolo a activar el sigilo (`C`) para avanzar en silencio. Cuando el peligro acecha, buscar un arbusto cercano y ocultarse en él brinda un momento seguro de invisibilidad visual.

## 3. Detailed Rules
- **Movimiento de 8 Direcciones:** Movimiento bidimensional libre en 8 direcciones. El vector de entrada se normaliza.
- **Sprint:** Presionar `SHIFT` multiplica la velocidad actual, pero incrementa significativamente la emisión de ruido.
- **Modo Sigilo (Teclado - C):** Mantener presionada la tecla `C` reduce la velocidad de movimiento a `stealth_speed` y reduce la emisión de ruido del jugador a exactamente 0.0 (silencio absoluto).
- **Esconderse en Arbustos (Automático):** Al entrar físicamente en el área de un arbusto (representado por setos o grupos de hongos como *Chanterelles*), el jugador se oculta automáticamente (se vuelve invisible visualmente para el cono de visión de los enemigos) y su opacidad se reduce al 55%.
  - *Nota:* Los árboles físicos ya no ocultan al jugador automáticamente; solo sirven como oclusores visuales físicos que proyectan sombras.
- **Emisión de Ruido:** El jugador posee un radio de ruido (`noise_radius`) dinámico:
  - **Inmóvil:** 0.0 píxeles de ruido.
  - **En Sigilo (tecla C):** 0.0 píxeles de ruido.
  - **Caminando normal:** Ruido medio (`noise_walk_radius`).
  - **Corriendo (Sprint + SHIFT):** Ruido alto (`noise_sprint_radius`).
- **Intangibilidad:** Activar la habilidad etérea otorga inmunidad al daño durante 3.0 segundos y desactiva las colisiones físicas, reduciendo la opacidad a 0.45.
- **Penalización por Orbes:** Cada orbe recolectado reduce la velocidad base de forma acumulativa hasta un límite mínimo (`min_speed`).
- **Campo de Visión Dinámico:** El jugador posee un radio de visión circular (`vision_radius`). Los obstáculos físicos proyectan sombras geométricas de oclusión 2D (Niebla de Guerra). Los enemigos y almas ubicados dentro de las áreas de sombra quedan completamente ocultos.

## 4. Formulas
- **Velocidad Efectiva Normal/Cargada:**
  $$Speed_{normal} = \max(Speed_{min}, Speed_{base} - Orbs \times Penalty_{orb})$$
- **Velocidad Efectiva con Sprint:**
  $$Speed_{sprint} = Speed_{normal} \times Multiplier_{sprint}$$
- **Emisión de Ruido Dinámica ($Radius_{noise}$):**
  $$Radius_{noise} = \begin{cases} 
    0.0, & \text{si } \vec{Velocity} = 0 \text{ o } State = \text{STEALTH} \\
    Radius_{noise\_sprint}, & \text{si corriendo} \\
    Radius_{noise\_walk}, & \text{si caminando normal}
  \end{cases}$$

## 5. Edge Cases
- **Hacer ruido dentro de un arbusto:** Si el jugador se mueve dentro de un arbusto sin presionar `C` (sigilo), emitirá ruido. Los enemigos cercanos no lo verán (invisibilidad visual), pero podrán escuchar los pasos del arbusto e ir a investigar esa posición.
- **Esconderse bajo persecución:** Si el jugador entra a un arbusto mientras es perseguido visualmente, el enemigo pierde la visión directa del jugador y se dirigirá a investigar el arbusto.
- **Ruido a través de muros:** El ruido acústico del jugador ignora las colisiones físicas. Los enemigos pueden escuchar los pasos del jugador aunque estén separados por un gran muro o árbol.

## 6. Dependencies
- Requiere zonas de escondite físicas en el escenario que pertenezcan al grupo `hiding_spot` (como las *Chanterelles*).
- Depende del sistema de enemigos para transmitirles el valor actual del radio de ruido y la posición del jugador.
- Requiere un nodo de luz 2D (`PointLight2D` con sombras) y oclusores de luz (`LightOccluder2D`) en el terreno.

## 7. Tuning Knobs
- `base_speed` (Default: 200.0)
- `sprint_multiplier` (Default: 2.0)
- `stealth_speed` (Default: 80.0)
- `speed_penalty_per_orb` (Default: 18.0)
- `min_speed` (Default: 60.0)
- `vision_radius` (Default: 220.0)
- `noise_walk_radius` (Default: 120.0) - Radio de audición de pasos caminando.
- `noise_sprint_radius` (Default: 250.0) - Radio de audición de pasos corriendo.

## 8. Acceptance Criteria
- Mantener presionado `C` reduce la velocidad y pone a cero el radio de ruido.
- Entrar en un arbusto (`Chanterelles`) activa la opacidad al 55% y hace al jugador invisible visualmente.
- Los árboles sólidos y muros ya no hacen al jugador invisible; solo bloquean la línea de visión proyectando sombras 2D.
- Moverse a velocidad normal o corriendo emite un radio de ruido circular que se transmite al grupo `enemy`.
