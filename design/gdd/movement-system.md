# GDD: Movement and Stealth System

## 1. Overview
El sistema de movimiento y sigilo del jugador permite desplazarse en perspectiva top-down en 8 direcciones (incluyendo diagonales), correr (sprint), camuflarse en el entorno (sigilo) y volverse intangible temporalmente usando un poder etéreo. La recolección de almas afecta de forma dinámica la velocidad del jugador. Además, el jugador posee un campo de visión limitado bloqueado dinámicamente por obstáculos del entorno (árboles, muros), proyectando sombras de visión (Niebla de Guerra).

## 2. Player Fantasy
El jugador debe sentirse rápido y ágil al principio, pero altamente vulnerable. A medida que recolecta espíritus, el peso físico de estas almas debe transmitir una sensación de tensión creciente. El sistema de campo de visión limitado intensifica esta tensión, forzando al jugador a explorar esquinas con cuidado y calcular sus movimientos, ya que los enemigos ocultos tras árboles o ruinas no serán visibles hasta tener línea de visión directa.

## 3. Detailed Rules
- **Movimiento de 8 Direcciones:** Movimiento bidimensional libre en 8 direcciones (ortogonales y diagonales). El vector de entrada se normaliza para evitar que el movimiento diagonal sea más rápido.
- **Mapeo de Animaciones:** Al moverse en diagonal, el motor de animación selecciona la dirección cardinal dominante (arriba, abajo, izquierda, derecha) según el ángulo de inclinación para reproducir la animación correspondiente.
- **Sprint:** Presionar `SHIFT` incrementa la velocidad actual multiplicándola por el modificador de sprint, siempre que el jugador no esté en estado de sigilo, intangible o inmóvil.
- **Sigilo:** Presionar `C` reduce la velocidad y activa el estado de sigilo. Si el jugador está dentro de una zona de escondite (`hide_spot`) bajo este estado, se vuelve invisible para los enemigos.
- **Intangibilidad:** Activar la habilidad etérea otorga inmunidad al daño durante 3.0 segundos y desactiva las colisiones físicas, reduciendo la opacidad a 0.45.
- **Penalización por Orbes:** Cada orbe recolectado reduce la velocidad base de forma acumulativa hasta un límite mínimo de velocidad (`min_speed`).
- **Muerte:** El contacto directo con cualquier enemigo en estado no intangible causa la muerte inmediata (1-hit kill), soltando todas las almas recolectadas que retornan a sus posiciones originales.
- **Campo de Visión Dinámico (LoS del Jugador):** El jugador posee un radio de visión circular (`vision_radius`). Los obstáculos físicos (Capa 1: muros, ruinas, troncos de árboles) bloquean la luz/visión proyectando sombras geométricas de oclusión 2D. Las áreas obstruidas se renderizan oscurecidas (Niebla de Guerra). Los enemigos y almas ubicados dentro de las áreas de sombra u oscurecidas quedan completamente ocultos a la vista del jugador.

## 4. Formulas
- **Vector de Dirección Normalizado:**
  $$\vec{dir} = \text{normalize}(\vec{input\_raw})$$
- **Velocidad Efectiva Normal/Cargada:**
  $$Speed_{normal} = \max(Speed_{min}, Speed_{base} - Orbs \times Penalty_{orb})$$
- **Velocidad Efectiva con Sprint:**
  $$Speed_{sprint} = Speed_{normal} \times Multiplier_{sprint}$$
- **Velocidad en Sigilo:**
  $$Speed_{effective\_stealth} = Speed_{stealth\_base}$$ (Ignora penalizaciones de orbes y multiplicadores de sprint).
- **Velocidad Intangible:**
  $$Speed_{effective\_intangible} = Speed_{base}$$ (Ignora penalizaciones de orbes y multiplicadores de sprint).
- **Visibilidad de un Objetivo:**
  Un objetivo en $\vec{Pos}_{target}$ es visible para el jugador en $\vec{Pos}_{player}$ si y solo si:
  1. Distancia: $\|\vec{Pos}_{target} - \vec{Pos}_{player}\| \le Radius_{vision}$
  2. Línea de visión libre: No existen intersecciones con colisionadores del terreno (Capa 1) en el segmento que une $\vec{Pos}_{player}$ con $\vec{Pos}_{target}$.

## 5. Edge Cases
- **Entrar en Sigilo bajo persecución:** Si el jugador se oculta en una zona de escondite mientras un enemigo le persigue, el enemigo pierde la línea de visión directa e investiga el último punto conocido del jugador en lugar de continuar la persecución.
- **Muerte con múltiples almas:** Al morir el jugador, todos los orbes que le seguían regresan instantáneamente a sus posiciones iniciales en el nivel, evitando que se pierdan o queden en posiciones inaccesibles.
- **Intangibilidad justo al colisionar:** Si se activa la intangibilidad en el mismo frame que ocurre una colisión con un enemigo, se procesa primero la inmunidad, evitando la muerte del jugador.
- **Enemigo atacando desde la Niebla:** Un enemigo que embiste (Jabalí) o persigue (Zorro) puede entrar al cono de visión del jugador repentinamente desde una zona de sombra si el jugador hace ruido o es alertado por un Búho.

## 6. Dependencies
- Requiere zonas de escondite físicas en el escenario que pertenezcan al grupo `hide_spot`.
- Depende del sistema de enemigos para registrar eventos y colisiones en el grupo `enemy`.
- Requiere interactuar con los orbes del grupo `orb`.
- Requiere un nodo de luz 2D (`PointLight2D` con sombras habilitadas) y colisionadores de luz (`LightOccluder2D`) en los objetos del terreno para proyectar la oclusión física en tiempo real.

## 7. Tuning Knobs
- `base_speed` (Default: 200.0) - Velocidad de movimiento básica del jugador.
- `sprint_multiplier` (Default: 2.0) - Multiplicador aplicado al correr.
- `stealth_speed` (Default: 80.0) - Velocidad reducida al estar en modo sigilo.
- `speed_penalty_per_orb` (Default: 18.0) - Velocidad restada por cada orbe en posesión.
- `min_speed` (Default: 60.0) - Límite inferior de velocidad por peso de orbes.
- `intangible_duration` (Default: 3.0) - Duración en segundos de la intangibilidad.
- `vision_radius` (Default: 220.0) - Radio de luz/visión circular del jugador.

## 8. Acceptance Criteria
- El jugador puede moverse en 8 direcciones y el vector de entrada se normaliza correctamente.
- Las animaciones se mapean dinámicamente a la dirección cardinal dominante en movimientos diagonales.
- Recoger orbes reduce de forma verificable la velocidad de movimiento del jugador hasta un mínimo de `min_speed`.
- Activar el sigilo (`C`) reduce la velocidad a `stealth_speed` y activa la emisión de partículas.
- Al estar dentro de un `hide_spot` en modo sigilo, el método `is_hidden()` devuelve `true`.
- Activar el poder de intangibilidad deshabilita colisiones contra enemigos, ajusta la opacidad y previene la muerte durante exactamente 3.0 segundos.
- Los obstáculos con `LightOccluder2D` proyectan sombras realistas en tiempo real que oscurecen el escenario fuera de la línea de visión directa. Los enemigos en zonas oscurecidas no son renderizados.
