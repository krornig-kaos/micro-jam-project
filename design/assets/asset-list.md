# Asset List: Visuals, VFX and Audio

Este documento contiene la lista detallada de recursos artísticos y sonoros necesarios para el desarrollo completo del proyecto, estructurado para lograr un "game feel" fluido y profesional.

## 1. Sprites de Personajes (Multidireccionales)

Todos los personajes deben contar con variaciones de animación en las direcciones cardinales (Arriba, Abajo, Lados). Las animaciones "lado" (left/right) se gestionan en código mediante inversión horizontal (`flip_h`).

### Jugador (La Liebre)
- [x] **Idle**: `idle_up`, `idle_down`, `idle_left`, `idle_right`
- [x] **Caminar/Correr**: `run_up`, `run_down`, `run_left`, `run_right`
- [x] **Muerte**: `death` (No en bucle, se reproduce una vez)
- [ ] **Sigilo**: `stealth_up`, `stealth_down`, `stealth_left`, `stealth_right` (Caminado sigiloso agachado)

### Jabalí (Boar)
- [x] **Caminar (Patrulla)**: `walk_up`, `walk_down`, `walk_left`, `walk_right`
- [x] **Cargar (Embestida)**: `run_up`, `run_down`, `run_left`, `run_right`
- [ ] **Preparación (Windup)**: `windup_up`, `windup_down`, `windup_left`, `windup_right` (Escarbando tierra antes de correr)
- [ ] **Aturdido (Stun)**: `stun` (Mareado tras chocar contra un muro)

### Zorro (Fox)
- [x] **Caminar (Patrulla)**: `walk_up`, `walk_down`, `walk_left`, `walk_right`
- [x] **Correr (Persecución)**: `run_up`, `run_down`, `run_left`, `run_right`
- [ ] **Investigar (Oler)**: `sniff_up`, `sniff_down`, `sniff_left`, `sniff_right` (Oliendo el suelo al investigar sonidos)

### Búho (Owl)
- [x] **Vuelo (Exploración)**: `fly_up`, `fly_down`, `fly_left`, `fly_right`
- [x] **Reposo (Vigilancia)**: `idle_up`, `idle_down`, `idle_left`, `idle_right`

---

## 2. Efectos Visuales (VFX)

- [ ] **Polvo de Pasos**: Partículas de tierra al correr a alta velocidad.
- [ ] **Humo de Sigilo**: Partículas de humo/hojas sutiles al agacharse en arbustos.
- [ ] **Aura Intangible**: Brillo/Glow azul translúcido rodeando al jugador cuando es intangible.
- [ ] **Estrellitas de Aturdimiento**: Icono de mareo giratorio sobre la cabeza del Jabalí aturdido.
- [ ] **Oclusores de Sombra**: Texturas/Polígonos de sombras 2D asignados a la base de los árboles y ruinas.
- [ ] **Cono de Visión de Enemigos**: Un área poligonal semitransparente que muestre el campo visual del Zorro, Jabalí y Búho.
- [ ] **Icono de Alerta (`!`) / Duda (`?`)**: Exclamación roja cuando el Zorro/Jabalí detectan visualmente, e interrogación amarilla cuando investigan un sonido.
- [ ] **Estallido de Almas (Pop)**: Destello de luz al recoger un alma.
- [ ] **Estela de Almas (Trail)**: Partículas brillantes y flotantes que sigan a las almas mientras flotan detrás del jugador.

---

## 3. Efectos de Sonido (SFX)

### Jugador
- [ ] **Pasos en Pasto (Normal)**: Sonido ligero de pisadas de liebre en vegetación.
- [ ] **Pasos en Pasto (Rápido)**: Pisadas apresuradas y ruidosas al esprintar.
- [ ] **Activación de Sigilo**: Sonido sutil (como tela o fricción suave).
- [ ] **Intangibilidad (Cast)**: Efecto mágico de campana o eco cósmico al activarse.
- [ ] **Muerte**: Sonido trágico de golpe de impacto y almas liberándose.

### Jabalí
- [ ] **Gruñido de Patrulla**: Sonido animal bajo e inquisitivo.
- [ ] **Grito de Carga**: Chillido agresivo de jabalí durante el Windup.
- [ ] **Pezuñas al Correr**: Pasos rápidos y pesados en la embestida.
- [ ] **Impacto**: Sonido de golpe seco de madera/piedra al estrellarse contra un obstáculo.
- [ ] **Aturdimiento**: Silbido cómico de pajaritos o campanilla de mareo.

### Zorro
- [ ] **Ladrido de Alerta**: Sonido agudo de alerta de zorro al detectar al jugador.
- [ ] **Olfateo de Rastro**: Sonido de husmear repetitivo en el estado de investigación.

### Búho
- [ ] **Ulular (Hoot)**: Ulular clásico de búho silvestre como sonido ambiental.
- [ ] **Alarma (Screech)**: Chillido penetrante de alarma al detectar o ser tocado por el jugador.
- [ ] **Aleteo**: Sonido de alas batiéndose durante el vuelo de exploración.

### Entorno y Altar
- [ ] **Chime de Almas**: Campanilla mágica aguda y relajante al recolectar un alma.
- [ ] **Crujido de Arbusto**: Sonido de maleza moviéndose al entrar/salir de un arbusto.
- [ ] **Liberación del Altar**: Acorde místico o soplido de viento mágico al depositar las almas.

---

## 4. Banda Sonora y Música

- [ ] **Música de Bosque (Tranquila)**: Melodía melancólica e instrumental (cuerdas/flautas) de volumen bajo, con pocos instrumentos cuando la saturación es casi nula (blanco y negro).
- [ ] **Música de Bosque (Salvada)**: Transición fluida a una instrumentación cálida y alegre a medida que la saturación aumenta al 100%.
- [ ] **Pista de Persecución (Tensión)**: Percusión tensa que hace crossfade automático cuando entras en modo persecución (CHASE).
- [ ] **Jingle de Victoria**: Melodía corta alegre y triunfal al rescatar todas las almas.
- [ ] **Jingle de Derrota**: Melodía corta sombría y de bajo tono al aparecer el Game Over.
