# GDD: Soul Collection and Altar System

## 1. Overview
El sistema de recolección de almas y el Altar define las mecánicas para recolectar espíritus flotantes esparcidos en el escenario. Al ser recogidos, estos espíritus siguen físicamente al jugador y reducen su velocidad por su peso. El objetivo principal es llevar estas almas al Altar (Punto B) para entregarlas, lo que restaura progresivamente el color y la vida del mundo, que inicialmente comienza desaturado (blanco y negro).

## 2. Player Fantasy
La recolección de almas debe sentirse mística pero pesada. El jugador experimenta una gratificación visual inmediata al depositar las almas: ver cómo el mundo gris y hostil recobra su color y calidez de forma gradual, reforzando la idea de que está devolviendo la vida al bosque.

## 3. Detailed Rules
- **Almas Flotantes (Souls):** Los espíritus flotan estáticamente en el mapa con un movimiento oscilatorio vertical (senoidal) hasta ser recogidos.
- **Recolección y Seguimiento:** Al entrar en contacto con el jugador, el alma cambia de estado, se reduce su escala a 0.6 y su opacidad a 0.7, y sigue la posición del jugador usando una interpolación lineal (`lerp`).
- **Altar de Almas (Soul Altar):** Es una estructura fija en el escenario que define el Punto B. Si el jugador entra en su área con una o más almas (`orb_count > 0`), se ejecuta la entrega.
- **Entrega de Almas:** Al entregar las almas, el contador del jugador vuelve a cero, se reproduce un efecto visual en el Altar (brillo rápido) y se emite la señal `animals_revived` con la cantidad total entregada.
- **Efecto de Descolorización (Filtro de Saturación):** El nivel comienza con un filtro de pantalla (Shader de desaturación) configurado a un nivel de gris casi total (desaturado). Cada vez que se entregan almas en el Altar, el nivel de saturación del shader se incrementa proporcionalmente a las almas entregadas sobre el total del nivel.
- **Retorno por Muerte:** Si el jugador muere, todos los espíritus recolectados que le estaban siguiendo regresan automáticamente a sus coordenadas de inicio originales en el nivel.

## 4. Formulas
- **Efecto de Flotación (Idle):**
  $$Y(t) = Y_{inicial} + \sin(t \times Speed_{float}) \times Amplitude_{float}$$
- **Suavizado de Seguimiento (Follow Lerp):**
  $$\vec{Pos}_{soul}(t) = \text{lerp}(\vec{Pos}_{soul}(t-1), \vec{Pos}_{player} + \begin{pmatrix} 0 \\ -20 \end{pmatrix}, Speed_{follow} \times \Delta t)$$
- **Saturación del Mundo Dinámica:**
  $$Saturation = Saturation_{base} + (1.0 - Saturation_{base}) \times \frac{Souls_{delivered\_total}}{Souls_{level\_total}}$$

## 5. Edge Cases
- **Entregar almas mientras es perseguido:** Si el jugador llega al Altar mientras un enemigo lo persigue, la entrega se procesa instantáneamente al tocar el área. La velocidad del jugador se restablece a la base de inmediato, lo que le permite huir a velocidad completa.
- **Almas acumuladas en el mismo punto:** Múltiples almas recogidas siguen al jugador hacia el mismo punto de desfase relativo ($Y - 20$), creando visualmente una fila o cúmulo de espíritus detrás del jugador.
- **Entrega parcial de almas:** La entrega es "todo o nada". Todas las almas en posesión son depositadas simultáneamente al entrar en el área del Altar.

## 6. Dependencies
- Depende del sistema de movimiento del jugador para incrementar el contador `orb_count` y llamar al método `deliver_souls()`.
- Requiere de un nodo `Area2D` con colisiones físicas configuradas para la recolección y la entrega.
- Requiere un Shader de Pantalla (Post-processing shader en un `CanvasLayer` / `ColorRect`) para aplicar el control de saturación.

## 7. Tuning Knobs
- `float_speed` (Default: 2.0) - Velocidad de la oscilación vertical del alma.
- `float_amplitude` (Default: 5.0) - Amplitud en píxeles de la oscilación vertical.
- `follow_speed` (Default: 8.0) - Velocidad de lerp de seguimiento al jugador.
- `scale_multiplier` (Default: 0.6) - Escala visual del alma una vez recogida.
- `alpha_collected` (Default: 0.7) - Opacidad del alma una vez recogida.
- `base_saturation` (Default: 0.05) - Saturación de color inicial (0.0 es blanco y negro total, 1.0 es color normal).

## 8. Acceptance Criteria
- Las almas flotan arriba y abajo suavemente cuando están en estado libre.
- Al colisionar con el jugador, las almas pasan a seguirlo suavizadamente con tamaño y opacidad reducidos.
- Al iniciar el nivel, el entorno se visualiza descolorizado según la variable `base_saturation`.
- Al entregar almas en el altar, el color del entorno incrementa su viveza/saturación de forma proporcional al número de almas entregadas.
- Al morir el jugador, las almas regresan a sus posiciones iniciales exactas.
- Al entrar en el Altar con almas, se limpian del jugador, el Altar parpadea visualmente y se emite la señal `animals_revived`.
