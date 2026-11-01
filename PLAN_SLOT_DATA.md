# Plan: opciones de la seed al conectar (`slot_data`)

Plan para que el tracker se configure solo al conectar a Archipelago con las opciones de la seed: meta, area rando, Buddies, 1-Ups, estrellas de 100 monedas y cuadros bloqueados. Cada tarea es independiente y se puede implementar por separado.

---

## Contexto: qué manda Archipelago y qué no

Según el código del mundo de SM64 en Archipelago (`worlds/sm64ex/__init__.py`, función `fill_slot_data`), el `slot_data` contiene **solo** estas claves:

| Clave | Valor | Estado en el pack |
|---|---|---|
| `CompletionType` | `0` = último Bowser, `1` = los 3 Bowsers | ❌ No se usa → **Tarea 1** |
| `AreaRando` | **Tabla** `entrada → nivel` (no es un número) | ⚠️ Mal leída → **Tarea 2** |
| `MoveRandoVec` | Bits de los movimientos aleatorizados | ✅ Se usa (si es 0 marca todos) |
| `PaintingRando` | `0` / `1` (cuadros bloqueados) | ❌ No se usa → **Tarea 5** |
| `DeathLink` | `0` / `1` | No se usa (no hace falta) |
| `FirstBowserDoorCost`, `BasementDoorCost`, `SecondFloorDoorCost`, `StarsToFinish`, `MIPS1Cost`, `MIPS2Cost` | Estrellas | ✅ Implementado (`items/doors.json`) |

**No se mandan**: Bob-omb Buddies, bloques de 1-Up, estrellas de 100 monedas, requisitos estrictos (caps / cañones / movimientos), número total de estrellas ni llaves progresivas.

Por eso, en `onClear` de `scripts/autotracking/archipelago.lua`, estos bloques **nunca se ejecutan**:

```lua
if slot_data["StrictMovesRequirements"] then ...   -- no existe
if slot_data["StrictCapsRequirements"] then ...    -- no existe
if slot_data["StrictCannonsRequirements"] then ... -- no existe
if slot_data["enable_coin_stars"] then ...         -- no existe
if slot_data["1UpMushroom"] then ...               -- no existe
if slot_data["Buddy_Checks"] then ...              -- no existe
```

Y este tiene un error:

```lua
if slot_data["AreaRando"] then
    Tracker:FindObjectForCode("area").Active = slot_data["AreaRando"] ~=0
end
```

`AreaRando` es una tabla, y una tabla nunca es igual a `0`. Así que `area` se activa **siempre**, aunque la seed no tenga area rando.

---

## Tarea 1 — Meta de la partida (`CompletionType`)

**Qué hace:** muestra si hay que derrotar solo al último Bowser o a los 3, y se ajusta solo al conectar.

### 1.1 Ítem — `items/settings.json`

Se añade al final de la lista. Es un `progressive` de 2 etapas; el orden de las etapas coincide con el valor de `CompletionType` (etapa 0 = valor 0).

```json
{
    "name": "Goal",
    "type": "progressive",
    "allow_disabled": false,
    "loop": true,
    "stages": [
        {
            "name": "Goal: Last Bowser Stage",
            "img": "img/paintings/Bowser in the Sky Painting.png",
            "codes": "goal_last"
        },
        {
            "name": "Goal: All Bowser Stages",
            "img": "img/paintings/Bowser in the Sky Painting.png",
            "img_mods": "overlay|img/text/3.png",
            "codes": "goal_all"
        }
    ]
}
```

- `allow_disabled: false`: siempre muestra una de las dos etapas, nunca aparece "apagado".
- `loop: true`: al hacer clic pasa de una etapa a la otra, para cambiarlo a mano sin conexión.
- Las imágenes son provisionales. La de "los 3" pone un `3` encima del cuadro de BitS; hay que comprobar que `img_mods` con `overlay` se ve bien, y si no, usar otra imagen.

### 1.2 Lectura — `scripts/autotracking/archipelago.lua` (en `onClear`)

```lua
        -- Meta: 0 = último Bowser, 1 = los 3 Bowsers
        if slot_data["CompletionType"] then
            Tracker:FindObjectForCode("goal_last").CurrentStage = slot_data["CompletionType"]
        end
```

Basta con buscar cualquiera de los dos códigos: los dos apuntan al mismo ítem.

### 1.3 Layout — `layouts/grids.json`

Añadir `"goal_last"` a una fila de `tracker_settings`. Por ejemplo, en la última fila:

```json
[
    "area",
    "goal_last"
]
```

### 1.4 Lógica (opcional) — `scripts/logic.lua`

Para cuando existan ubicaciones de victoria:

```lua
-- true si la meta exige derrotar a los 3 Bowsers
function goal_all_bowsers()
	return has("goal_all")
end
```

### Cómo probarlo

1. Recargar el pack sin conectar: debe verse "Last Bowser Stage", y al hacer clic debe cambiar.
2. Conectar a una seed con `completion_type: all_bowser_stages`: debe pasar sola a "All Bowser Stages".

---

## Tarea 2 — Arreglar la detección de Area Rando

**Qué hace:** activa `area` solo si de verdad hay entradas mezcladas.

### 2.1 Función auxiliar — `scripts/autotracking/archipelago.lua` (antes de `onClear`)

`AreaRando` es una tabla `entrada → nivel`. Las claves llegan como texto (`"91"`) porque vienen de JSON, y los valores como número (`91`), por eso se comparan con `tostring`. Así ya lo hace `EntranceMapper:Fill` en `scripts/entranceMapper.lua`. Si alguna entrada lleva a un nivel distinto del suyo, hay area rando.

```lua
-- true si alguna entrada lleva a un nivel distinto del suyo
local function is_area_rando(area_map)
    if type(area_map) ~= "table" then
        return false
    end
    for entrance, course in pairs(area_map) do
        if tostring(entrance) ~= tostring(course) then
            return true
        end
    end
    return false
end
```

### 2.2 Sustituir en `onClear`

Antes:

```lua
        if slot_data["AreaRando"] then
            Tracker:FindObjectForCode("area").Active = slot_data["AreaRando"] ~=0
        end
```

Después:

```lua
        if slot_data["AreaRando"] then
            Tracker:FindObjectForCode("area").Active = is_area_rando(slot_data["AreaRando"])
        end
```

### Cómo probarlo

1. Seed **sin** area rando: `area` debe quedar apagado.
2. Seed **con** area rando: `area` debe quedar encendido.
3. Si en el paso 1 sale encendido, imprimir la tabla con `print(dump_table(slot_data["AreaRando"]))` para ver su formato real y ajustar la comparación.

---

## Tarea 3 — Detectar Buddies, 1-Ups y estrellas de 100 monedas

**Qué hace:** como Archipelago no manda estas opciones, se deducen de las ubicaciones de la seed. Si la opción está activada, sus ubicaciones existen.

PopTracker da todas las ubicaciones de la partida en dos listas de IDs:
- `Archipelago.MissingLocations`: las que faltan por hacer.
- `Archipelago.CheckedLocations`: las ya hechas.

Si un ID está en alguna de las dos, esa ubicación forma parte de la seed.

| Opción | Toggle del tracker | ID que lo delata |
|---|---|---|
| Bob-omb Buddies | `pinkbomb` | `3626200` (Buddy de BoB) |
| Bloques de 1-Up | `1upbox` | `3626215` (1-Up de CCM, cerca del muñeco de nieve) |
| Estrellas de 100 monedas | `100coins` | `3626006` (100 monedas de BoB) |

### 3.1 Función auxiliar — `scripts/autotracking/archipelago.lua` (antes de `onClear`)

```lua
-- true si la ubicación forma parte de la seed (pendiente o ya hecha)
local function seed_has_location(location_id)
    for _, id in ipairs(Archipelago.MissingLocations or {}) do
        if id == location_id then
            return true
        end
    end
    for _, id in ipairs(Archipelago.CheckedLocations or {}) do
        if id == location_id then
            return true
        end
    end
    return false
end
```

### 3.2 Uso en `onClear`

Sustituye los bloques de `enable_coin_stars`, `1UpMushroom` y `Buddy_Checks`:

```lua
        -- Opciones que Archipelago no manda: se deducen de las ubicaciones de la seed
        local location_options = {
            ["pinkbomb"] = 3626200, -- Bob-omb Buddies
            ["1upbox"] = 3626215,   -- Bloques de 1-Up
            ["100coins"] = 3626006  -- Estrellas de 100 monedas
        }
        for code, location_id in pairs(location_options) do
            Tracker:FindObjectForCode(code).Active = seed_has_location(location_id)
        end
```

### Riesgos a comprobar

- **¿Están las listas llenas cuando se llama a `onClear`?** PopTracker llama a `onClear` después de conectar, así que deberían estarlo. Para comprobarlo, añadir temporalmente:
  ```lua
  print("missing:", #(Archipelago.MissingLocations or {}), "checked:", #(Archipelago.CheckedLocations or {}))
  ```
  Si sale `0` y `0`, hay que hacer la detección más tarde, por ejemplo la primera vez que se llame a `onItem` o a `onLocation`, guardando una variable `OPTIONS_DETECTED = false` que se ponga a `true` al hacerlo.
- **Estrellas de 100 monedas en modo `vanilla`:** la opción tiene tres valores (`off` / `on` / `vanilla`). Con `vanilla` las ubicaciones podrían seguir existiendo, y el toggle saldría encendido. Hay que comprobarlo con una seed en `vanilla` y decidir si eso es lo que se quiere mostrar.

### Cómo probarlo

1. Seed con Buddies y 1-Ups activados y sin estrellas de 100 monedas: `pinkbomb` y `1upbox` encendidos, `100coins` apagado.
2. Seed con todo lo contrario: al revés.

---

## Tarea 4 — Limpiar los bloques que nunca se ejecutan

**Qué hace:** quita de `onClear` el código que lee claves inexistentes, para que no confunda.

Los de Buddies, 1-Ups y 100 monedas los sustituye la Tarea 3. Los de requisitos estrictos **no se pueden deducir** de ninguna forma, así que esos toggles (`moves`, `caps`, `cannons`) se quedan como manuales. Se comentan con una nota, por si una versión futura de Archipelago empieza a mandarlos:

```lua
        -- Archipelago (worlds/sm64ex) no manda estas opciones en el slot_data:
        -- los toggles "moves", "caps" y "cannons" se marcan a mano.
        -- if slot_data["StrictMovesRequirements"] then
        --     Tracker:FindObjectForCode("moves").Active = slot_data["StrictMovesRequirements"]~=0
        -- end
        -- if slot_data["StrictCapsRequirements"] then
        --     Tracker:FindObjectForCode("caps").Active = slot_data["StrictCapsRequirements"]~=0
        -- end
        -- if slot_data["StrictCannonsRequirements"] then
        --     Tracker:FindObjectForCode("cannons").Active = slot_data["StrictCannonsRequirements"]~=0
        -- end
```

`strict_cap_requirements`, `strict_cannon_requirements` y `strict_move_requirements` están **activados por defecto** en Archipelago. Para que el tracker arranque con el valor más probable, se puede añadir `"initial_active_state": true` a los tres toggles (`moves`, `caps`, `cannons`) en `items/settings.json`. El esquema de PopTracker incluye ese campo:

```json
{
    "name": "Strict Cap Requirements",
    "type": "toggle",
    "img": "img/boxes/Block.png",
    "codes": "caps",
    "initial_active_state": true
}
```

---

## Tarea 5 — Cuadros bloqueados (`PaintingRando`)

**Qué hace:** muestra si la seed tiene los cuadros bloqueados (`enable_locked_paintings`), es decir, si hay que encontrar el ítem de cada cuadro para entrar a su nivel.

### 5.1 Ítem — `items/settings.json`

```json
{
    "name": "Locked Paintings",
    "type": "toggle",
    "img": "img/paintings/Unknown Painting.png",
    "codes": "lockedpaintings"
}
```

`img/paintings/Unknown Painting.png` ya lo usa `area`. Habría que buscar otra imagen para diferenciarlos.

### 5.2 Lectura en `onClear`

```lua
        if slot_data["PaintingRando"] then
            Tracker:FindObjectForCode("lockedpaintings").Active = slot_data["PaintingRando"] ~= 0
        end
```

### 5.3 Layout

Añadir `"lockedpaintings"` a `tracker_settings` en `layouts/grids.json`.

### 5.4 Relación con los cuadros (`items/entrances.json`)

Si los cuadros **no** están bloqueados, los toggles de `entrances.json` (`WF-P`, `JRB-P`, ...) no tienen sentido, porque todos los niveles se pueden abrir. Más adelante se podría:
- ocultar el grupo "Entrances" cuando `lockedpaintings` esté apagado, o
- usar `has("lockedpaintings")` en la lógica: `not has("lockedpaintings") or has("WF-P")`.

---

## Tarea 6 — Corregir `ESTRUCTURA.md`

La sección **2.3** tiene una tabla de "Claves que manda SM64" que incluye claves que **no existen** (`StrictMovesRequirements`, `enable_coin_stars`, `1UpMushroom`, `Buddy_Checks`...). Además, describe `AreaRando` como un número. Al implementar las tareas anteriores, hay que reemplazar esa tabla por la de "Contexto" de este plan y añadir el truco de `MissingLocations` / `CheckedLocations` como forma de detectar opciones que no se mandan.

---

## Orden recomendado

| # | Tarea | Por qué en este orden |
|---|---|---|
| 1 | Tarea 2 (Area Rando) | Es un error real: ahora mismo `area` siempre sale activado |
| 2 | Tarea 1 (Meta) | El dato llega seguro; es lo más sencillo |
| 3 | Tarea 3 + Tarea 4 | Van juntas: la 3 sustituye los bloques que limpia la 4. Hay que comprobar antes el riesgo de las listas vacías |
| 4 | Tarea 5 (Cuadros) | Útil pero no urgente |
| 5 | Tarea 6 (Documentación) | Al final, con lo que de verdad haya funcionado |

## Checklist

- [ ] Tarea 2: `is_area_rando` + sustitución en `onClear`, probada con y sin area rando
- [ ] Tarea 1: ítem `goal` en `items/settings.json`, lectura de `CompletionType`, añadido a `tracker_settings`
- [ ] Tarea 3: `seed_has_location` + tabla `location_options`; comprobado que las listas no llegan vacías
- [ ] Tarea 3: comprobado el caso de estrellas de 100 monedas en `vanilla`
- [ ] Tarea 4: bloques de requisitos estrictos comentados con su nota
- [ ] Tarea 5: ítem `lockedpaintings`, lectura de `PaintingRando`, añadido a `tracker_settings`
- [ ] Tarea 6: sección 2.3 de `ESTRUCTURA.md` corregida
- [ ] Recargar el pack y probar con al menos dos seeds de opciones distintas
