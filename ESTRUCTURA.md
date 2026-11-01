# Estructura del pack y cómo añadir elementos nuevos

Guía para añadir un elemento nuevo al tracker, desde el ítem hasta que aparece en cada variante.

```
SM64AP-PopTracker/
├── manifest.json              ← variantes (Vertical, Horizontal, ...)
├── settings.json
├── img/<categoria>/...png     ← imágenes de los ítems
├── items/*.json               ← DEFINICIÓN de ítems (qué es cada cosa)
├── layouts/
│   ├── grids.json             ← BLOQUES reutilizables (grids de ítems)
│   ├── layout.json            ← ventana principal  — Vertical (base)
│   ├── broadcast_layout.json  ← ventana broadcast  — Vertical (base)
│   ├── layout_horizontal.json
│   ├── broadcast_layout_horizontal.json
│   ├── layout_vertical_complete.json
│   ├── broadcast_layout_vertical_complete.json
│   ├── layout_horizontal_complete.json
│   ├── broadcast_layout_horizontal_complete.json
│   └── layout_exp.json
└── scripts/
    ├── init.lua               ← carga items y layouts según la variante
    ├── logic.lua              ← funciones de lógica (has, ddd_door, ...)
    └── autotracking/
        ├── archipelago.lua    ← onClear (slot_data al conectar), onItem, onLocation
        ├── item_mapping.lua   ← ID de ítem de Archipelago → code
        └── location_mapping.lua ← ID de ubicación de Archipelago → code
```

El flujo siempre es:

```
img/  →  items/*.json  →  layouts/grids.json (bloque)  →  layout.json / layout_horizontal.json (ventana)  →  init.lua  →  manifest.json
          (code)            (tracker_x)                    (tracker_default)                                (carga)     (variante)
```

---

## 1. Imagen

Pon la imagen en `img/<categoria>/`, usando una carpeta existente si encaja (`mario`, `boxes`, `settings`, `varios`, `paintings`, ...).

- PNG cuadrado, de preferencia.
- Se permiten espacios en el nombre (`Whomp's Fortress Painting.png`), pero es más fácil escribirlo sin ellos: `Koopa-Shell.png`.

---

## 2. Definir el ítem — `items/*.json`

Cada archivo de `items/` es una **lista** de ítems. Mete el ítem nuevo en el archivo de su categoría o crea uno nuevo (ver el paso 2.1).

```json
{
    "name": "Koopa Shell",
    "type": "toggle",
    "img": "img/varios/Koopa-Shell.png",
    "codes": "shell"
}
```

| Campo | Para qué sirve |
|---|---|
| `name` | Texto del tooltip. Es libre. |
| `type` | `toggle` (sí/no), `consumable` (contador), `progressive` (por etapas) o `static` (solo decorativo). |
| `img` | Ruta desde la raíz del pack. |
| `codes` | **Identificador único.** Es lo que usan los layouts, la lógica y el autotracking. |

Campos extra según el tipo:
- `consumable`: `max_quantity`, `overlay_font_size`, `font` (mira `powerstar` en `items/items.json`).
- `progressive`: `stages: [ { "img": ..., "codes": ... }, ... ]` en vez de `img`/`codes`.
- `toggle`: `"loop": "true"` hace que el clic derecho también lo cambie.

PopTracker acepta comentarios `//` dentro de los JSON (como en `items/stars.json`). Sirven para separar secciones.

### 2.1 Si creaste un archivo nuevo en `items/`

Regístralo en `scripts/init.lua` junto a los demás `AddItems`, **antes** de los `AddLayouts`:

```lua
Tracker:AddItems("items/shells.json")
```

### 2.2 Autotracking (si el ítem existe en Archipelago)

Añade su ID en `scripts/autotracking/item_mapping.lua`:

```lua
[3626999] = {"shell", "toggle"},
```

Usa el **mismo** `code` y el **mismo** `type` del JSON.

### 2.3 Valores que llegan al conectar (`slot_data`)

Además de los ítems que vas recibiendo, Archipelago manda **una sola vez al conectar** las opciones de la partida: el `slot_data`. Sirve para que el tracker se ajuste solo a cada seed. Ejemplos: si está activado Area Rando, cuántas estrellas cuesta cada puerta, etc.

PopTracker lo entrega a la función `onClear(slot_data)` de `scripts/autotracking/archipelago.lua`. `slot_data` es una tabla Lua: `slot_data["Clave"]` devuelve el valor de esa opción, o `nil` si la seed no la manda.

#### Claves que manda SM64 y dónde se usan

| Clave | Tipo | Ítem del tracker |
|---|---|---|
| `AreaRando` | número (0 = desactivado) | `area` (toggle) |
| `StrictMovesRequirements` / `StrictCapsRequirements` / `StrictCannonsRequirements` | número | `moves` / `caps` / `cannons` (toggle) |
| `enable_coin_stars` | número | `100coins` (toggle) |
| `1UpMushroom` | número | `1upbox` (toggle) |
| `Buddy_Checks` | número | `pinkbomb` (toggle) |
| `MoveRandoVec` | número (bits) | si es 0, marca todos los movimientos |
| `FirstBowserDoorCost` | estrellas | `cost_bitdw` (consumable) |
| `BasementDoorCost` | estrellas | `cost_basement` |
| `SecondFloorDoorCost` | estrellas | `cost_floor2` |
| `StarsToFinish` | estrellas | `cost_final` |
| `MIPS1Cost` / `MIPS2Cost` | estrellas | `cost_mips1` / `cost_mips2` |

Para ver todas las claves que manda tu seed, activa `AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP` en `scripts/autotracking.lua`: `onClear` imprime el `slot_data` completo en la consola de PopTracker.

#### Cómo añadir una opción nueva

**1. Crea el ítem que la va a mostrar** (paso 2), con el tipo según el valor:

| Valor de la opción | Tipo de ítem | Cómo se asigna |
|---|---|---|
| Sí/no (0 o 1) | `toggle` | `obj.Active = slot_data["Clave"] ~= 0` |
| Un número (coste, cantidad) | `consumable` | `obj.AcquiredCount = slot_data["Clave"]` |
| Uno entre varios modos | `progressive` | `obj.CurrentStage = slot_data["Clave"]` |

En un `consumable`, pon el valor por defecto del juego como `initial_quantity`. Así el tracker muestra algo razonable aunque no estés conectado, y al conectar se sobrescribe. Ejemplo de `items/doors.json`:

```json
{
    "name": "Basement Star Door (DDD)",
    "type": "consumable",
    "img": "img/varios/PowerStarModelSM64.png",
    "codes": "cost_basement",
    "min_quantity": 0,
    "max_quantity": 120,
    "initial_quantity": 30,
    "overlay_font_size": 25,
    "font": "MARIO Font v3_2 Solid"
}
```

**2. Léela en `onClear`**, después del `if SLOT_DATA == nil then return end`. Comprueba siempre que la clave exista, porque las seeds de otras versiones pueden no mandarla:

```lua
if slot_data["AreaRando"] then
    Tracker:FindObjectForCode("area").Active = slot_data["AreaRando"] ~= 0
end
```

Si son varias del mismo tipo, usa una tabla `clave → code`, como con los costes de estrellas:

```lua
local star_costs = {
    ["FirstBowserDoorCost"] = "cost_bitdw",
    ["BasementDoorCost"] = "cost_basement",
    -- ...
}
for key, code in pairs(star_costs) do
    if slot_data[key] then
        Tracker:FindObjectForCode(code).AcquiredCount = slot_data[key]
    end
end
```

**3. Úsala en la lógica (opcional)** desde `scripts/logic.lua`, leyendo el ítem del tracker. Así la lógica funciona igual si el valor vino de Archipelago o si el jugador lo cambió a mano:

```lua
function has_stars_for(cost_code)
	local cost = Tracker:FindObjectForCode(cost_code)
	return has("powerstar", cost and cost.AcquiredCount or 0)
end

function ddd_door()
	return has("basementkey") and has_stars_for("cost_basement")
end
```

En las ubicaciones se usa con `$` delante del nombre de la función: `"access_rules": ["$ddd_door"]`.

Funciones de costes que ya existen en `logic.lua`:

| Función | Condición |
|---|---|
| `has_stars_for(code)` | `powerstar` ≥ el valor del contador `code` |
| `bitdw_door()` | estrellas ≥ `cost_bitdw` |
| `ddd_door()` | llave del sótano y estrellas ≥ `cost_basement` |
| `floor3_door()` | llave del segundo piso y estrellas ≥ `cost_floor2` |
| `final_door()` | `floor3_door()` y estrellas ≥ `cost_final` |
| `mips1_ready()` / `mips2_ready()` | llave del sótano y estrellas ≥ `cost_mips1` / `cost_mips2` |

> No confundas `slot_data` con `item_mapping.lua`. `item_mapping.lua` traduce los **ítems que recibes** durante la partida (llegan por `onItem`, uno a uno). `slot_data` son las **opciones de la seed** (llegan una vez, en `onClear`).

---

## 3. Bloque de layout — `layouts/grids.json`

`layouts/grids.json` guarda los **bloques reutilizables**: grids pequeños que no son una ventana, solo un trozo que las ventanas insertan. Así un mismo grid sirve en Vertical, Horizontal, Completo y Experimental sin copiarlo.

- Se llama `grids.json` (y no `items.json`) para no confundirlo con `items/items.json`, que **define** los ítems. `grids.json` solo decide **dónde se colocan**.
- Se carga siempre en `init.lua`, fuera del `if` de variantes, así que todas las ventanas pueden usar cualquier bloque.
- Si el archivo crece mucho, se puede partir siguiendo el mismo patrón de nombres que las ventanas: `grids_<variante>.json` (por ejemplo `grids_horizontal.json` con los `horizontal_tracker_*`). Cada archivo nuevo necesita su línea `Tracker:AddLayouts(...)`, también fuera del `if`.

Añade una clave nueva al objeto principal (sin olvidar la coma con la clave anterior):

```json
"tracker_shells": {
    "type": "array",
    "orientation": "vertical",
    "content": [
        {
            "type": "itemgrid",
            "item_size": "5",
            "item_margin": "1,1",
            "rows": [
                ["shell", "", "bobc"]
            ]
        }
    ]
}
```

- Cada string de `rows` es un `codes` del paso 2.
- `""` deja un hueco vacío. Sirve para alinear columnas entre filas, no para centrar el grid (para eso, ver "Centrar un bloque" en 4.1).
- Cada lista interna es una fila.

### 3.1 ¿Necesita versión horizontal distinta?

Solo si el grid cambia de forma, por ejemplo 3 columnas en vertical y 5 en horizontal:

```json
"tracker_shells":            { ... rows de 3 columnas ... },
"horizontal_tracker_shells": { ... rows de 5 columnas ... }
```

Si el grid sirve igual en las dos, deja **solo** `tracker_shells` y úsalo en las dos ventanas, como se hace ya con `tracker_entrances`, `tracker_cannons` y `tracker_settings`.

---

## 4. Meterlo en una ventana

Las ventanas son las claves reservadas que PopTracker busca:

| Clave reservada | Ventana |
|---|---|
| `tracker_default` | Ventana principal |
| `tracker_broadcast` | Ventana de broadcast (OBS) |
| `settings_popup` | Ventana de opciones (botón de engranaje) |

**Estas claves nunca se renombran.** Lo que distingue una variante de otra es el **archivo** donde están, no la clave.

Para que el bloque aparezca, insértalo con `"type": "layout"` en el archivo de cada variante:

```json
{
    "type": "group",
    "header": "Shells",
    "dock": "top",
    "content": {
        "type": "layout",
        "key": "tracker_shells"
    }
}
```

Archivos que hay que tocar según dónde quieras verlo:

| Variante | Ventana principal | Broadcast | Bloque a usar |
|---|---|---|---|
| Vertical | `layout.json` | `broadcast_layout.json` | `tracker_shells` |
| Horizontal | `layout_horizontal.json` | `broadcast_layout_horizontal.json` | `horizontal_tracker_shells` (o `tracker_shells` si es compartido) |
| Vertical-Completo | `layout_vertical_complete.json` | `broadcast_layout_vertical_complete.json` | igual que Vertical |
| Horizontal-Completo | `layout_horizontal_complete.json` | `broadcast_layout_horizontal_complete.json` | igual que Horizontal |
| Experimental | `layout_exp.json` | `broadcast_layout_horizontal.json` | igual que Horizontal |

En broadcast normalmente no se usa `group`; se pone el `layout` directo con su `dock` (mira `broadcast_layout.json`).

### 4.1 Filas, columnas y cómo combinarlas

Si todos los hijos de un `dock` tienen `"dock": "top"`, se apilan uno debajo de otro. Para colocarlos en una misma fila se usa `array`:

| `orientation` | Resultado |
|---|---|
| `"horizontal"` | **fila**: hijos de izquierda a derecha |
| `"vertical"` | **columna**: hijos de arriba abajo |

**Regla: cada nivel decide una sola dirección.** Para combinar los dos sentidos, mete un `array` dentro de otro. Cada `array` solo coloca a sus hijos directos.

Ejemplo: Items y Moves en una fila, y Entrances debajo.

```
┌───────────────┬───────────────┐
│     Items     │     Moves     │   ← array horizontal (fila)
├───────────────┴───────────────┤
│           Entrances           │
└───────────────────────────────┘
  ↑ todo dentro de un array vertical (columna)
```

```json
"content": {
    "type": "array",
    "orientation": "vertical",
    "content": [
        {
            "type": "array",
            "orientation": "horizontal",
            "content": [
                { "type": "group", "header": "Items",
                  "content": { "type": "layout", "key": "horizontal_tracker_items" } },
                { "type": "group", "header": "Moves",
                  "content": { "type": "layout", "key": "horizontal_tracker_moves" } }
            ]
        },
        { "type": "group", "header": "Entrances",
          "content": { "type": "layout", "key": "tracker_entrances" } }
    ]
}
```

Dentro de un `array` la propiedad `"dock"` no hace nada, así que se puede quitar.

**Alternativa con `dock`:** sirve cuando una parte tiene que **rellenar el espacio sobrante** al cambiar el tamaño de la ventana.

| `"dock"` del hijo | Qué hace |
|---|---|
| `top` / `bottom` | Ocupa todo el ancho y se apila hacia abajo / hacia arriba. |
| `left` / `right` | Ocupa todo el alto y se coloca hacia la derecha / hacia la izquierda. |
| último hijo | Se queda con el espacio sobrante (como `center`). |

Para hacer una fila con `dock`, mete un `dock` con hijos `left` dentro de otro con hijos `top`. Así está hecho `layout_exp.json`.

En resumen: **`array`** para filas y columnas simples; **`dock`** cuando algo tiene que estirarse para llenar la ventana.

#### Alinear grupos entre sí: columnas mejor que filas

En una fila (`array` horizontal) cada grupo mide lo que miden sus ítems, y cada fila calcula sus anchos por su cuenta. Si apilas varias filas, los grupos de arriba y de abajo no coinciden.

Para que queden alineados, **organiza por columnas**: un `array` horizontal que contiene varios `array` verticales. Una columna estira a todos sus hijos al ancho del más ancho, así que los grupos de una misma columna miden lo mismo. El contenido de cada grupo sigue empezando a la izquierda; para centrarlo, ver "Centrar un bloque" más abajo.

```
Filas (desparejo):                     Columnas (alineado):
┌Items┬Moves──────┐                    ┌─────Items─────┬──Moves──┐
├Entrances──┬Cannons───┐               ├───Entrances───┼─Cannons─┤
                                        columna 1        columna 2
```

```json
"content": {
    "type": "array",
    "orientation": "horizontal",
    "content": [
        { "type": "array", "orientation": "vertical", "content": [ <Items>, <Entrances> ] },
        { "type": "array", "orientation": "vertical", "content": [ <Moves>, <Cannons> ] }
    ]
}
```

Así está hecho `layout_horizontal_complete.json`. Pon en la misma columna los grupos que deben compartir ancho. Las columnas pueden tener alturas distintas; lo que se alinea es el ancho.

#### Centrar un bloque: `margin`, no `h_alignment`

**PopTracker no centra contenedores.** Esto está comprobado en su código fuente y probado en este pack:

| Elemento | Cómo coloca su contenido |
|---|---|
| `array` vertical | Estira cada hijo a todo el ancho, pero lo dibuja desde la izquierda (x = 0 + `margin`). |
| `array` horizontal | Coloca los hijos uno tras otro desde la izquierda, cada uno con su ancho. |
| `dock` | Pega cada hijo a un borde o lo estira para rellenar. Nunca lo centra. |
| `group`, `layout` | Solo envuelven. No colocan nada. |
| `itemgrid` | Dibuja los ítems desde la izquierda, en posiciones fijas. |

Por eso **`h_alignment` / `v_alignment` / `item_h_alignment` no hacen nada** en `group`, `array`, `layout` ni `dock`, y no vale la pena ponerlos. Solo tienen efecto en el `itemgrid`:

- `h_alignment` del `itemgrid`: centra las **filas cortas** respecto a la fila más larga del mismo grid, como la segunda fila de Entrances. `center` ya es el valor por defecto, así que no hace falta escribirlo. Solo se pone para cambiarlo a `left` o `right`.
- `item_h_alignment` / `item_v_alignment` del `itemgrid`: alinean la imagen **dentro de su casilla**, útil si la casilla es más grande que la imagen.

**Para centrar un bloque dentro de su grupo, se le pone un `margin` izquierdo al `itemgrid`** (`"izq,arriba,der,abajo"`, en píxeles):

```json
"horizontal_tracker_items": {
    "type": "array",
    "orientation": "vertical",
    "content": [
        {
            "type": "itemgrid",
            "margin": "100,0,0,10",
            "item_size": "5",
            "item_margin": "1,1",
            "rows": [ ... ]
        }
    ]
}
```

Cómo calcular el margen:

1. Un `itemgrid` mide: `columnas × (tamaño del ítem + 2 × item_margin)`.
2. Margen izquierdo = **(ancho del bloque más ancho de la columna − ancho de este bloque) / 2**.
3. Si no sabes el tamaño exacto en píxeles, ajusta probando y mirando el resultado. 10–20 px apenas se notan, así que empieza con valores grandes y luego afina.

Valores actuales en `grids.json`:

| Bloque | Margen | Respecto a |
|---|---|---|
| `horizontal_tracker_items` | `100,0,0,10` | Entrances (misma columna) |
| `horizontal_tracker_moves` | `20,0,0,10` | Cannons (misma columna; mismas 5 columnas, pero `item_margin` 1 contra 5 → 40 px menos de ancho) |

**Cuidado:** el margen es fijo. Si cambias el `item_size`, el `item_margin`, el número de columnas de un bloque o lo pones en otra columna, hay que recalcularlo.

Otros apuntes:
- El `array` que envuelve al `itemgrid` en `grids.json` puede ser `vertical` u `horizontal`; con un solo hijo se ve igual.
- No uses casillas vacías `""` al principio de las filas para centrar: no se pueden poner medias casillas y descuadran el grid. Úsalas solo para huecos con sentido.

### Elementos de layout más usados

| `type` | Uso |
|---|---|
| `container` | Envoltorio exterior, con `background`. |
| `dock` | Coloca a sus hijos con `"dock": "top" / "bottom" / "left" / "right" / "center"`. |
| `array` | Apila a sus hijos en `orientation` `vertical` u `horizontal`. |
| `group` | Caja con título (`header`). |
| `tabbed` | Pestañas: `tabs: [ { "title": ..., "content": ... } ]`. |
| `itemgrid` | Cuadrícula de ítems (`rows`). |
| `item` | Un solo ítem (`"item": "code"`). |
| `layout` | Inserta otro layout por su `key`. |

Propiedades comunes: `margin` (`"izq,arriba,der,abajo"`, en píxeles), `item_size`, `item_margin`, `background`. `h_alignment` / `item_h_alignment` solo tienen efecto en un `itemgrid` (ver "Centrar un bloque" en 4.1).

---

## 5. Crear una ventana / variante nueva

Ejemplo: una variante "Compacta".

**5.1** Crea `layouts/layout_compact.json` (y `layouts/broadcast_layout_compact.json` si va a tener broadcast propio). Dentro, usa **las claves reservadas**:

```json
{
    "tracker_default": {
        "type": "container",
        "background": "#000000",
        "content": {
            "type": "dock",
            "content": [
                { "type": "layout", "dock": "top", "key": "tracker_items" },
                { "type": "layout", "dock": "top", "key": "tracker_moves" }
            ]
        }
    }
}
```

Si la variante necesita grids con otra forma, añádelos en `layouts/grids.json` como `compact_tracker_x` (ver la sección 6).

**5.2** Añade la variante en `manifest.json`, dentro de `"variants"`:

```json
"compact": {
    "display_name": "Compacta",
    "flags": ["ap"]
}
```

La primera variante de la lista es la que se abre por defecto (ahora mismo es `vertical`).

**5.3** Añade su rama en `scripts/init.lua`. El texto del `if` tiene que ser **exactamente** la clave del manifest:

```lua
elseif variant == "compact" then
    Tracker:AddLayouts("layouts/layout_compact.json")
    Tracker:AddLayouts("layouts/broadcast_layout_horizontal.json")
```

Ponla antes del `else` final. El `else` es la variante Vertical y también recoge cualquier variante que no tenga rama.

`layouts/grids.json` se carga siempre, fuera del `if`. Por eso todas las variantes ven todos los bloques.

---

## 6. Reglas de nombres

| Qué | Formato | Ejemplos | Dónde tiene que coincidir |
|---|---|---|---|
| Imagen | `img/<categoria>/Nombre-Con-Guiones.png` | `img/mario/Wall-Kick.png` | campo `img` del ítem |
| `codes` de ítem | minúsculas, corto, sin espacios, **único** | `tj`, `wc`, `basementkey`, `bobc` | `rows` de los grids, `item_mapping.lua`, lógica (`accessRules.lua` / `logic.lua`) |
| Contador de un coste del `slot_data` | `cost_<qué>` | `cost_basement`, `cost_mips1` | `onClear` en `archipelago.lua`, `has_stars_for(...)` en `logic.lua` |
| Función de lógica | minúsculas con `_`; **distinta de cualquier `code`** | `ddd_door`, `mips1_ready` | `"$nombre"` en las `access_rules` |
| Archivo de ítems | `items/<categoria>.json` en minúsculas | `items/moves.json` | `Tracker:AddItems` en `init.lua` |
| Archivo de bloques | `layouts/grids.json` (o `layouts/grids_<variante>.json` si se parte) | `grids.json` | `Tracker:AddLayouts` en `init.lua`, fuera del `if` |
| Bloque base (Vertical) | `tracker_<bloque>` | `tracker_items`, `tracker_moves` | `"key"` en las ventanas |
| Bloque horizontal | `horizontal_tracker_<bloque>` | `horizontal_tracker_items` | `"key"` en las ventanas horizontales |
| Bloque de otra variante | `<variante>_tracker_<bloque>` | `compact_tracker_moves` | `"key"` en esa variante |
| Bloque compartido | `tracker_<bloque>` (sin prefijo) | `tracker_entrances` | se usa en todas |
| Ventana base (Vertical) | `layouts/layout.json`, `layouts/broadcast_layout.json` | — | `init.lua` (rama `else`) |
| Ventana de otra variante | `layouts/layout_<variante>.json`, `layouts/broadcast_layout_<variante>.json` | `layout_horizontal.json`, `broadcast_layout_horizontal.json` | `init.lua` |
| Claves de ventana | **siempre** `tracker_default`, `tracker_broadcast`, `settings_popup` | — | no se cambian nunca |
| ID de variante | minúsculas, sin espacios | `vertical`, `horizontal`, `vertical-complete`, `horizontal-complete`, `exp` | clave en `manifest.json` = texto del `if` en `init.lua` |
| Nombre visible de variante | libre | `"Horizontal-Completo"` | solo `display_name` |

Resumen: **sin variante = Vertical / compartido; con variante = la variante que lo usa.**

- **Claves de bloque:** la variante va **delante** (`horizontal_tracker_items`).
- **Archivos de ventana:** el orden es fijo: `[broadcast_]layout[_<variante>].json`.
  1. `broadcast_`: solo si es la ventana de broadcast.
  2. `layout`: siempre.
  3. `_<variante>`: solo si no es la base (Vertical). Es el mismo ID que en `manifest.json`.

| Archivo | broadcast | layout | variante |
|---|---|---|---|
| `layout.json` | — | ✔ | — (Vertical) |
| `broadcast_layout.json` | ✔ | ✔ | — (Vertical) |
| `layout_horizontal.json` | — | ✔ | `horizontal` |
| `broadcast_layout_horizontal.json` | ✔ | ✔ | `horizontal` |
| `layout_vertical_complete.json` | — | ✔ | `vertical-complete` |
| `broadcast_layout_vertical_complete.json` | ✔ | ✔ | `vertical-complete` |
| `layout_horizontal_complete.json` | — | ✔ | `horizontal-complete` |
| `broadcast_layout_horizontal_complete.json` | ✔ | ✔ | `horizontal-complete` |
| `layout_exp.json` | — | ✔ | `exp` |

> Excepción heredada: los `codes` de las entradas (`WF-P`, `JRB-P`, ...) usan mayúsculas. Funcionan igual. Si los renombras, cambia también todas las referencias de la tabla.

### Si renombras algo, revisa:

- **Un `code`:** el JSON en `items/`, todos los `rows` de `layouts/*.json`, `item_mapping.lua` y las reglas de lógica en `scripts/`.
- **Una clave de bloque:** su definición en `layouts/grids.json` y cada `"key"` que la usa en `layouts/*.json`.
- **Un archivo de layout:** su línea `Tracker:AddLayouts` en `init.lua`.
- **Un ID de variante:** su clave en `manifest.json` y el `if variant == "..."` en `init.lua`.

Para buscar todas las referencias, busca el nombre entre comillas en todo el pack (por ejemplo `"tracker_moves"`).

---

## 7. Checklist rápido

1. [ ] Imagen en `img/<categoria>/`
2. [ ] Ítem en `items/<categoria>.json` con un `codes` único
3. [ ] Si es un archivo de ítems nuevo: `Tracker:AddItems(...)` en `init.lua`
4. [ ] Si tiene autotracking: entrada en `item_mapping.lua`
   - Si es una opción de la seed: bloque `if slot_data["Clave"]` en `onClear` (sección 2.3), y su función en `logic.lua` si afecta a la lógica
5. [ ] Bloque `tracker_<bloque>` en `layouts/grids.json` (y `horizontal_tracker_<bloque>` si cambia de forma)
6. [ ] `"key"` añadido en `layout.json`, `layout_horizontal.json`, `layout_vertical_complete.json`, `layout_horizontal_complete.json`, `layout_exp.json` y en los broadcast que correspondan
7. [ ] Si es una variante nueva: archivo `layouts/layout_<variante>.json` (y `layouts/broadcast_layout_<variante>.json` si lo necesita), entrada en `manifest.json` y rama en `init.lua`
8. [ ] Recargar el pack en PopTracker y probar cada variante
