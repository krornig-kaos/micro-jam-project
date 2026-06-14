# GDD: Enemy AI System

## 1. Overview
El sistema de enemigos define el comportamiento y patrones de inteligencia artificial de las tres criaturas hostiles del juego: el Jabalí (embestidor de tierra), el Zorro (perseguidor terrestre) y el Búho (faro de vigilancia rotativo y aéreo con patrulla de exploración periódica).

## 2. Player Fantasy
Los enemigos terrestres deben infundir peligro directo, forzando al jugador a aprender sus rutas de patrullaje. El Búho actúa como una "cámara de vigilancia móvil" que rota en un punto fijo del escenario y, periódicamente, despega en un vuelo circular para escanear el bosque, obligando al jugador a planificar sus movimientos según el ciclo de escaneo y patrulla.

## 3. Detailed Rules
- **Línea de Visión (LoS):** Todos los enemigos usan raycasts para determinar si hay visión directa con el jugador, colisionando con el terreno (Capa 1) y el jugador (Capa 2).
- **Zorro (Fox):**
  - **Patrulla:** Se mueve cíclicamente entre puntos definidos a velocidad de patrulla.
  - **Persecución:** Si detecta al jugador con LoS y el jugador no está en sigilo activo, lo persigue directamente.
  - **Investigación:** Si pierde LoS durante la persecución, se dirige a la última posición conocida y espera 3.0s antes de regresar a patrullar.
- **Jabalí (Boar):**
  - **Patrulla:** Se mueve en una trayectoria fija a velocidad lenta.
  - **Windup:** Al detectar al jugador con LoS sin sigilo activo, se congela durante 0.4s para preparar su ataque.
  - **Embestida (Charge):** Carga a alta velocidad en línea recta con capacidad de corrección de trayectoria mínima (lerp de 0.05).
  - **Aturdimiento (Stun):** Si colisiona con un muro u obstáculo durante la embestida, o si expira el tiempo de carga, se detiene y queda aturdido 1.5s.
- **Búho (Owl):**
  - **Vigilancia (WATCH):** Permanece estacionario en su punto de anclaje, girando lentamente sobre su propio eje (rotación de 360 grados).
  - **Exploración (EXPLORE):** Cada 60.0 segundos, el Búho sale de su estado de vigilancia para describir una órbita circular completa (360 grados) alrededor de su punto de anclaje. Durante este vuelo, la rotación automática se detiene y la cabeza del búho (junto con su cono de visión) se orienta tangencialmente en la dirección del vuelo. Al completar la órbita, retorna a su anclaje y reanuda el estado WATCH.
  - **Detección Direccional (Cono de Visión):** Su área de detección está limitada a un cono de visión orientado hacia donde apunta su mirada. El cono gira sincronizado con la orientación del Búho.
  - **Alarma:** Al detectar al jugador dentro de su cono de visión (siempre que el jugador no esté oculto o intangible y haya LoS), el Búho emite un anillo de onda expansiva roja y alerta a los enemigos terrestres llamando a sus métodos `on_player_spotted` pasándoles la ubicación del jugador.

## 4. Formulas
- **Detección en Cono de Visión (Búho):**
  El jugador es detectado si se cumplen ambas condiciones:
  1. Distancia: $d = \|\vec{Pos}_{player} - \vec{Pos}_{owl}\| \le Radius_{detection}$
  2. Ángulo: El ángulo $\alpha$ entre la dirección del Búho ($\vec{Dir}_{owl}$) y el vector hacia el jugador ($\vec{Dir}_{player}$) es menor o igual a la mitad del cono de visión ($\theta_{cone} / 2$):
     $$\cos(\alpha) = \frac{\vec{Dir}_{owl} \cdot \vec{Dir}_{player}}{\|\vec{Dir}_{owl}\| \|\vec{Dir}_{player}\|}$$
     $$\text{Detectado si } \alpha \le \frac{\theta_{cone}}{2}$$
- **Vuelo Circular en EXPLORE:**
  $$\theta(t) = \theta_0 + \frac{Speed_{patrol}}{Radius_{patrol}} \times t$$
  $$\vec{Pos}_{owl}(t) = \vec{Anchor} + \begin{pmatrix} \cos(\theta(t)) \\ \sin(\theta(t)) \end{pmatrix} \times Radius_{patrol}$$
  $$\vec{Dir}_{owl}(t) = \begin{pmatrix} -\sin(\theta(t)) \\ \cos(\theta(t)) \end{pmatrix} \quad (\text{Dirección de la cabeza orientada al frente del vuelo})$$
- **Corrección de Dirección de la Carga del Jabalí:**
  $$\vec{Dir}_{charge} = \text{lerp}(\vec{Dir}_{charge}, \vec{Dir}_{target\_desired}, 0.05)$$

## 5. Edge Cases
- **Jugador en Sigilo durante la Carga:** Si el jugador activa el sigilo a mitad de una embestida del Jabalí, este pierde el objetivo de forma inmediata y pasa al estado de aturdimiento (`STUN`).
- **Punto Ciego del Búho:** Si el jugador está muy cerca del Búho pero detrás de su espalda (fuera del ángulo del cono), no es detectado a pesar de la corta distancia.
- **Rotación/Vuelo Interrumpidos por Alerta:** Al emitir la alarma, el Búho congela temporalmente su rotación o vuelo circular para enfocar su cono de visión directamente hacia el jugador detectado hasta perderlo de vista.

## 6. Dependencies
- Requiere interactuar directamente con la posición global del Jugador (`player.gd`).
- Depende del sistema de física 2D de Godot (Raycasting y Collision Masks).
- Requiere nodos hijos configurados (`Area2D` y `Line2D` para el anillo de alerta).

## 7. Tuning Knobs
- **Zorro:** `patrol_speed` (80.0), `chase_speed` (160.0), `detection_radius` (150.0), `investigate_duration` (3.0s).
- **Jabalí:** `patrol_speed` (60.0), `charge_speed` (260.0), `detection_radius` (100.0), `charge_duration` (1.0s), `stun_duration` (1.5s).
- **Búho:** `rotation_speed` (45.0 grados/s), `detection_radius` (250.0), `cone_angle` (60.0 grados), `explore_cooldown` (60.0s), `patrol_radius` (200.0), `patrol_speed` (100.0).

## 8. Acceptance Criteria
- El Zorro patrulla, persigue y realiza la fase de investigación en la última posición conocida al perder de vista al jugador.
- El Jabalí inicia el windup al detectar al jugador, embiste con alta velocidad y entra en estado de aturdimiento al chocar con muros o expirar el tiempo de la carga.
- El Búho permanece estacionario rotando en WATCH, despega a realizar una órbita completa en EXPLORE cada 60.0s orientando su cono tangencialmente, y regresa a su punto inicial.
- El Búho congela su comportamiento para seguir con la mirada al jugador en cuanto emite la alarma del grupo `enemy`.
