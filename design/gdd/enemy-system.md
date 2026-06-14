# GDD: Enemy AI System

## 1. Overview
El sistema de enemigos define el comportamiento y patrones de inteligencia artificial de las tres criaturas hostiles del juego: el Jabalí (embestidor de tierra), el Zorro (perseguidor terrestre) y el Búho (faro de vigilancia rotativo y aéreo con patrulla de exploración periódica). Los enemigos terrestres y aéreos pueden detectar al jugador tanto visualmente (cono de visión) como acústicamente (escuchando el ruido de sus pasos).

## 2. Player Fantasy
Los enemigos terrestres deben infundir peligro directo, forzando al jugador a aprender sus rutas de patrullaje. El Búho actúa como una "cámara de vigilancia móvil" que rota en un punto fijo del escenario y, periódicamente, despega en un vuelo circular para escanear el bosque, obligando al jugador a planificar sus movimientos según el ciclo de escaneo y patrulla.

## 3. Detailed Rules
- **Línea de Visión (LoS):** Todos los enemigos usan raycasts para determinar si hay visión directa con el jugador, colisionando con el terreno (Capa 1) y el jugador (Capa 2). Los arbustos no bloquean el raycast (son transparentes para la visión), pero el jugador es indetectable visualmente si está dentro de uno de ellos en el grupo `hide_spot`.
- **Detección Acústica (Oído):** Todos los enemigos (Zorro, Jabalí y Búho) pueden escuchar el ruido del jugador. Si la distancia entre el enemigo y el jugador es menor o igual al radio de ruido actual del jugador (`noise_radius`), el enemigo "escucha" los pasos.
  - Al escuchar ruido estando en `PATROL` (o `WATCH`/`EXPLORE` en el caso del Búho) sin estar alertado, el enemigo cambia a un estado de alerta/investigación hacia el punto del sonido.
- **Zorro (Fox):**
  - **Patrulla en Racetrack (Cápsula):** Patrulla describiendo una trayectoria en forma de cápsula. Al llegar a los extremos, su cono de visión rota suavemente 180 grados barriendo el entorno.
  - **Persecución (CHASE):** Si detecta al jugador con LoS y el jugador no está oculto dentro de un arbusto, lo persigue directamente a velocidad rápida.
  - **Investigación (INVESTIGATE):** Se activa al perder LoS en persecución, al ser alertado por un Búho, o al escuchar ruido del jugador. El Zorro corre hacia la posición del ruido/última visual y busca allí durante 3.0s.
- **Jabalí (Boar):**
  - **Patrulla en Racetrack (Cápsula):** Patrulla en la misma trayectoria de cápsula horizontal. El cono de visión barre los extremos de la pista al dar la vuelta.
  - **Reacción al Ruido:** Si escucha ruido del jugador, detiene su patrulla, gira hacia la fuente del ruido y se prepara para embestir (entra en estado `WINDUP`).
  - **Windup:** Se congelela durante 0.4s para preparar su ataque.
  - **Embestida (Charge):** Carga a alta velocidad en línea recta con capacidad de corrección de trayectoria mínima (lerp de 0.05).
  - **Aturdimiento (Stun):** Si colisiona con un muro u obstáculo durante la embestida, o si expira el tiempo de carga, se detiene y queda aturdido 1.5s.
- **Búho (Owl):**
  - **Vigilancia (WATCH):** Permanece estacionario en su punto de anclaje, girando lentamente sobre su propio eje.
  - **Exploración (EXPLORE):** Cada 60.0 segundos, realiza un vuelo circular alrededor de su anclaje. Su cabeza y cono de visión apuntan tangencialmente.
  - **Reacción al Ruido (Oído del Búho):** Si el Búho escucha un ruido estando en WATCH o EXPLORE:
    - Detiene su rotación automática o su vuelo de órbita y gira su cono de visión directamente hacia la fuente del sonido para inspeccionar la zona durante 2.0s.
    - Si al girar el cono de visión detecta visualmente al jugador (porque este no está en un arbusto y hay LoS), activa la alarma de forma instantánea.
    - Si no detecta visualmente al jugador (está oculto o tras un muro), reanuda su patrulla/rotación habitual después de 2.0s.
  - **Alarma:** Al detectar al jugador dentro de su cono de visión (siempre que el jugador no esté oculto en un arbusto o intangible y haya LoS), emite una onda expansiva roja y alerta a los enemigos terrestres en el mapa (`on_player_spotted`).

## 4. Formulas
- **Detección en Cono de Visión (Búho y Enemigos Terrestres):**
  El jugador es detectado visualmente si se cumplen las tres condiciones:
  1. Distancia: $d = \|\vec{Pos}_{player} - \vec{Pos}_{enemy}\| \le Radius_{detection}$
  2. Ángulo: El ángulo $\alpha$ entre la dirección del enemigo y el vector hacia el jugador es menor o igual a la mitad de su cono de visión.
  3. No Oculto: El jugador no se encuentra en estado oculto (`is_hidden() == false` dentro de un arbusto).
- **Detección por Oído (Todos los Enemigos):**
  El enemigo escucha al jugador si se cumple:
  $$\|\vec{Pos}_{enemy} - \vec{Pos}_{player}\| \le Radius_{noise}$$
- **Patrulla en Pista de Carreras / Cápsula ($Pos_{patrol}$):**
  Definido por la longitud de la recta horizontal $L$ (`patrol_capsule_length`) y el radio del semicírculo de giro $R$ (`patrol_capsule_radius`). El perímetro total es $P = 4L + 2\pi R$. El parámetro de progreso $s$ incrementa por $s = \text{fmod}(t \times Speed_{patrol}, P)$.
  - **Recta Superior ($0 \le s < 2L$):**
    $$X = -L + s, \quad Y = -R, \quad \vec{Dir}_{vision} = \begin{pmatrix} 1 \\ 0 \end{pmatrix}$$
  - **Curva Derecha ($2L \le s < 2L + \pi R$):**
    $$\theta = -\frac{\pi}{2} + \frac{s - 2L}{R}, \quad X = L + R \cos(\theta), \quad Y = R \sin(\theta), \quad \vec{Dir}_{vision} = \begin{pmatrix} -\sin(\theta) \\ \cos(\theta) \end{pmatrix}$$
  - **Recta Inferior ($2L + \pi R \le s < 4L + \pi R$):**
    $$X = L - (s - 2L - \pi R), \quad Y = R, \quad \vec{Dir}_{vision} = \begin{pmatrix} -1 \\ 0 \end{pmatrix}$$
  - **Curva Izquierda ($4L + \pi R \le s < P$):**
    $$\theta = \frac{\pi}{2} + \frac{s - 4L - \pi R}{R}, \quad X = -L + R \cos(\theta), \quad Y = R \sin(\theta), \quad \vec{Dir}_{vision} = \begin{pmatrix} -\sin(\theta) \\ \cos(\theta) \end{pmatrix}$$

## 5. Edge Cases
- **Jugador en Sigilo en Arbusto:** Si el jugador se mueve en un arbusto sin presionar `C`, emite ruido. Los enemigos cercanos no lo verán, pero podrán escuchar los pasos e ir a investigar esa posición.
- **Muros bloqueando ruido:** Los muros y árboles no mitigan ni bloquean el sonido. La detección acústica es puramente radial.
- **Jabalí aturdido por sonido:** Si el Jabalí escucha un ruido mientras está en estado de aturdimiento (`STUN`), ignorará el ruido hasta recuperar el conocimiento.

## 6. Dependencies
- Requiere interactuar con la posición global y el radio de ruido del Jugador (`player.gd`).
- Depende del sistema de física 2D de Godot.

## 7. Tuning Knobs
- **Zorro:** `patrol_speed` (80.0), `chase_speed` (160.0), `detection_radius` (150.0), `investigate_duration` (3.0s), `patrol_capsule_length` (180.0), `patrol_capsule_radius` (30.0).
- **Jabalí:** `patrol_speed` (60.0), `charge_speed` (260.0), `detection_radius` (100.0), `charge_duration` (1.0s), `stun_duration` (1.5s), `patrol_capsule_length` (160.0), `patrol_capsule_radius` (25.0).
- **Búho:** `rotation_speed` (45.0 grados/s), `detection_radius` (250.0), `cone_angle` (60.0 grados), `explore_cooldown` (60.0s), `patrol_radius` (200.0), `patrol_speed` (100.0).

## 8. Acceptance Criteria
- El Zorro patrulla en pista de cápsula, persigue visualmente al jugador no oculto y corre a investigar cualquier ruido escuchado.
- El Jabalí patrulla en cápsula y entra en `WINDUP` para embestir inmediatamente hacia la fuente si escucha pasos del jugador.
- El Búho patrulla en WATCH, despega a realizar una órbita en EXPLORE, y si escucha un ruido, congela su movimiento y gira su cabeza hacia el origen del sonido para inspeccionar durante 2.0s.
- Los enemigos terrestres ignoran visualmente al jugador si este se encuentra dentro de un arbusto (grupo `hide_spot`) con opacidad al 55%.
