# Modelo de dominio

Resumen técnico de las 10 entidades de dominio del ERS, más las 3 de los packs
de entrenamiento (RF-25, secciones 11 a 13): atributos y reglas de negocio
que cada una debe garantizar por sí misma. Referencia rápida para el código;
el detalle de casos de uso y RF vive en el ERS (Doc del proyecto).

## 1. Cliente

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Mismo id que `auth.users` (relación 1:1) |
| nombre | text | Nombre completo |
| correo | text | Contacto, login, recuperación de contraseña |
| fechaNacimiento | date | Para cálculos de métricas |
| alturaCm | numeric | Altura |
| pesoInicialKg | numeric | Peso de referencia al alta |
| objetivos | text | Objetivo del cliente |
| diaControlPreferido | enum día de semana | Día recomendado para notificar registro de medidas/check-in |
| estado | enum (activo / baja) | Alta/baja lógica |
| fechaAlta | timestamptz | Fecha de alta |
| fechaBaja | timestamptz? | Fecha de baja, si aplica |

**Reglas de dominio**
- No puede haber dos clientes **activos** con el mismo correo (un correo dado de baja puede reutilizarse).
- Un cliente en "Baja" no recibe nuevos plannings, pero conserva su histórico completo.
- Baja siempre **lógica**: nunca se elimina físicamente al cliente ni sus datos.
- `fechaBaja` solo existe si `estado = baja`, y debe ser posterior a `fechaAlta`.

## 2. Planning semanal

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| clienteId | referencia a Cliente | Propietario |
| fechaInicio | date | Inicio de la semana planificada |
| nombreObjetivo | text? | Nombre/objetivo del planning |
| estado | enum (activo / archivado) | Para histórico |
| sesiones | colección de Sesión de entrenamiento | Composición |

**Reglas de dominio**
- No pueden coexistir dos plannings **activos** del mismo cliente con la misma `fechaInicio` (un archivado con la misma fecha no cuenta como conflicto).
- Eliminar un planning elimina en cascada sesiones, bloques y ejercicios planificados.
- Un planning archivado no admite añadir/editar/eliminar sesiones (solo consulta).
- **Lo pasado no se toca**: el entrenador no crea, modifica, borra ni duplica el planning de una semana que ya ha terminado. Se trabaja la semana en curso y las siguientes. Dos excepciones, cada una por un motivo distinto: el **cliente sí registra** lo que hizo en una semana pasada que siga activa (si entrena el domingo y lo apunta el lunes, tiene que poder), y el entrenador **sí puede archivarla**, porque archivar no cambia el plan y una semana se archiva justo cuando acaba.
- Consecuencia asumida: un error en una semana pasada ya no se deshace.

## 3. Sesión de entrenamiento

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| planningId | referencia | Planning al que pertenece |
| orden | integer | Su número dentro del planning: Día 1, Día 2… |
| nombre | text | Nombre de la sesión ("Empuje", "Pierna") |
| fechaRealizada | date? | Día en que el cliente la hizo. `null` mientras no la empiece |
| resultadoRegistrado | boolean | Derivado: todos sus ejercicios registrados |

**Reglas de dominio**
- **La sesión no tiene fecha planificada.** El entrenador decide cuántas sesiones tiene la semana y en qué orden, no en qué día caen: si el cliente no puede ir el miércoles y acaba yendo el jueves, es la misma sesión.
- No puede haber dos sesiones con el mismo `orden` dentro de un planning.
- `fechaRealizada` la escribe un **trigger** en cuanto hay un ejercicio registrado, y vuelve a `null` si el cliente deshace todo lo registrado. La app no la escribe nunca, y hoy no condiciona ninguna regla: solo queda guardada y sirve de eje en la gráfica de progreso (CU-21).
- `resultadoRegistrado` es derivado, igual que antes: lo mantienen los triggers de recálculo.

## 4. Bloque de ejercicio

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| sesionId | referencia a Sesión de entrenamiento | Propietario |
| tipo | enum (calentamiento / fuerza / cardio / movilidad / otro) | Tipo de bloque |
| orden | integer | Posición dentro de la sesión |
| notas | text? | Indicaciones del entrenador |
| ejerciciosPlanificados | colección de Ejercicio planificado | Composición |

**Reglas de dominio**
- No puede haber dos bloques con el mismo `orden` en la misma sesión.
- El `orden` lo cambia el entrenador **con flechas** (arriba / abajo; hasta el 2026-10-19 se arrastraba), y se renumera el conjunto entero de una vez: no se mueve un bloque suelto dejando huecos ni repetidos. El cliente no reordena lo que le han planificado.
- **Sin huecos**: al quitar un bloque, los demás de la sesión se renumeran solos (trigger en la base, desde el 2026-10-21). Un bloque nuevo va en la posición más alta + 1.
- Eliminar un bloque elimina en cascada sus ejercicios planificados (no afecta a la biblioteca general de Ejercicio).

## 5. Ejercicio (biblioteca)

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| nombre | text | Único entre ejercicios activos |
| grupoDeclarado | enum (pierna / pecho / espalda / hombro / brazo / core)? | Grupo guardado a mano, **solo** cuando no hay músculo principal |
| musculoPrincipal | enum Músculo? | El músculo que trabaja el ejercicio |
| musculosSecundarios | colección de Músculo | Los que entran además del principal |
| equipamiento | text? | Material necesario |
| descripcion | text? | Técnica de ejecución |
| videoEjemploUrl | text? | Vídeo de ejemplo. Si es de YouTube se reproduce dentro de la app; cualquier otro enlace se queda como enlace |
| imagenRuta | text? | Ilustración o foto de la ejecución. Ruta dentro del bucket público `imagenes-ejercicios`, no la URL |
| tipo | enum (fuerza / cardio / fortalecimiento) | Su **modo de planificación** determina series vs. minutos |
| estado | enum (activo / eliminado) | Baja lógica |

**Taxonomía muscular.** Dos niveles: el grupo y sus músculos. Cada músculo sabe
a qué grupo pertenece, así que el grupo de un ejercicio **se deriva** de su
músculo principal (`Ejercicio.grupo`) en lugar de guardarse por duplicado.

| Grupo | Músculos |
| --- | --- |
| Pierna | Cuádriceps · Isquiotibiales · Glúteo · Aductores · Abductores · Gemelo |
| Pecho | Porción esterno-clavicular · Porción esterno-costal |
| Espalda | Dorsal ancho · Trapecio · Romboides · Lumbar |
| Hombro | Deltoides anterior · Deltoides lateral · Deltoides posterior |
| Brazo | Bíceps · Tríceps · Antebrazo |
| Core | Recto abdominal · Oblicuos · Transverso |

**Tipos de ejercicio.** Fuerza y Cardio son los de siempre; **Fortalecimiento**
es trabajo para clientes con una lesión. Lo que cambia el comportamiento no es
el tipo sino su **modo de planificación**: Fuerza y Fortalecimiento van por
series, Cardio por minutos.

**Reglas de dominio**
- No puede haber dos ejercicios activos con el mismo `nombre`.
- Baja siempre lógica: un ejercicio "eliminado" no puede añadirse a nuevos bloques, pero sigue visible en los que ya lo usaban.
- Editar nombre/descripción/clasificación muscular no altera parámetros ya guardados en ejercicios planificados existentes.
- Solo el **nombre** y el **tipo** son obligatorios. La descripción es opcional: hay ejercicios que se explican solos y exigirla solo conseguía rellenos. Vacía se guarda como cadena vacía, no como `null`, porque la columna es `not null` y eso no merecía una migración; la ficha oculta el apartado cuando no hay nada que contar.
- La clasificación muscular es **opcional en sus tres campos**: un cardio puede declarar solo el grupo (la cinta de correr es de Pierna, sin un músculo concreto), y un ejercicio puede quedarse sin clasificar.
- El grupo y el músculo principal **no conviven**: con principal, el grupo se deriva de él.
- El músculo principal no puede repetirse entre los secundarios.
- Al filtrar, **los secundarios cuentan**: buscar "glúteo" encuentra también la sentadilla. Se listan primero los que lo tienen como principal.
- En la pantalla de biblioteca, el filtro principal es uno de **Todos / Fuerza / Cardio / Fortalecimiento / Dados de baja** (`PestanaBiblioteca`, que se deduce del filtro, no se guarda aparte). El filtro muscular **solo** existe con Fuerza o Fortalecimiento, que lo **comparten**: el músculo elegido se conserva al pasar de uno a otro y se suelta en los demás.
- Todos los usuarios autenticados (incluidos clientes) pueden **leer** la biblioteca completa (para ver la imagen y el vídeo de ejemplo).
- La imagen es material de la biblioteca, no dato personal: su bucket es público y cualquiera con el enlace la ve. Subirla, reemplazarla o borrarla es solo del entrenador.
- La imagen acompaña al ejercicio **allá donde se muestre**: la biblioteca, la planificación del entrenador y la pantalla con la que el cliente registra su resultado. Donde no la haya, un hueco con el icono de su tipo.

## 6. Ejercicio planificado

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| bloqueId | referencia a Bloque de ejercicio | Propietario |
| ejercicioId | referencia a Ejercicio | Ejercicio de la biblioteca usado |
| orden | integer | Posición dentro del bloque |
| descansoPlanificado | integer (seg)? | Solo en los tipos que van por series |
| minutosPlanificados | numeric? | Solo Cardio, define el entrenador |
| minutosRealizados | numeric? | Solo Cardio, registra el cliente |
| seriesPlanificadas | colección de Serie planificada | Solo en los tipos que van por series |
| estadoRegistro | enum (pendiente / registrado) | Derivado, mantenido por trigger |

**Reglas de dominio**
- **Series y minutos son mutuamente excluyentes**, y lo que decide cuál se usa es el **modo de planificación** del tipo: Fuerza y Fortalecimiento usan series (no minutos); Cardio usa minutos (no series). La pregunta no es por el tipo a propósito: con un tercer tipo, preguntar "¿es cardio?" convierte a Fortalecimiento en Fuerza sin que nadie lo decida.
- No puede haber dos "Ejercicio planificado" con el mismo `orden` en el mismo bloque. Se reordena con flechas, igual que los bloques, y también es cosa solo del entrenador.
- **Sin huecos**: al quitar un ejercicio, los demás del bloque se renumeran solos, igual que los bloques. Antes se quedaba el hueco y el siguiente ejercicio, en "cuántos hay + 1", chocaba con una posición ocupada (le pasó a Aimar el 2026-10-21).
- **Lo planificado puede quedarse sin rellenar**: un Cardio puede no tener minutos, igual que uno por series puede no tener series. Pasa al aplicar un pack que no los traía (2026-10-19): la base ya no exige los minutos, para no inventarse una cifra que el entrenador no puso. Añadido a mano desde el formulario de CU-08, en cambio, se siguen pidiendo.
- `estadoRegistro` pasa a "registrado" si existe al menos una Serie realizada (tipos por series) o si `minutosRealizados` tiene valor (Cardio).
- Eliminarlo no elimina el Ejercicio de la biblioteca, solo la referencia en ese bloque.

## 7. Serie planificada

Vive como colección dentro de Ejercicio planificado (tabla propia en SQL, sin RLS independiente: su seguridad depende de quién puede tocar el Ejercicio planificado).

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| numeroSerie | integer | 1ª, 2ª, 3ª serie... |
| repeticionesPlanificadas | integer | Objetivo de esa serie |
| pesoPlanificado | numeric? | Carga orientativa |
| rirPlanificado | integer? (0–10) | RIR objetivo |

**Reglas de dominio**
- No puede haber dos series con el mismo `numeroSerie` en el mismo Ejercicio planificado.
- `repeticionesPlanificadas` positiva; `pesoPlanificado` y `rirPlanificado` opcionales.

## 8. Serie realizada (entidad propia)

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| ejercicioPlanificadoId | referencia | A qué ejercicio pertenece |
| numeroSerie | integer | Serie correspondiente |
| repeticionesRealizadas | integer | Repeticiones reales |
| pesoReal | numeric? | Carga real |
| rirReal | integer? (0–10) | RIR real percibido (sustituye a RPE) |
| fechaHoraRegistro | timestamptz | Cuándo se registró |

**Reglas de dominio**
- No puede haber dos series realizadas con el mismo `numeroSerie` para el mismo Ejercicio planificado.
- El número de series realizadas no tiene que coincidir con el de planificadas.
- **Lo planificado (entrenador) y lo realizado (cliente) son independientes**: no se fuerza coincidencia; la diferencia es información válida para medir rendimiento y adherencia.
- Solo el cliente propietario registra sus series, únicamente sobre sesiones de un planning activo suyo.

## 9. Registro de medidas corporales

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| clienteId | referencia a Cliente | Propietario |
| fecha | date | Día del registro |
| pesoKg | numeric | Obligatorio |
| pechoCm, cinturaCm, caderaCm, cuadricepsCm, brazosCm | numeric? | Perímetros opcionales |
| fotos | colección de referencias a archivo | Storage, opcional |

**Reglas de dominio**
- No puede haber dos registros del mismo cliente con la misma `fecha`.
- `pesoKg` obligatorio; el resto de perímetros y fotos opcionales.
- Solo el cliente propietario (o el entrenador, en consulta) gestiona sus registros.

## 10. Check-in semanal de recuperación

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| clienteId | referencia a Cliente | Propietario |
| fecha | date | Día del check-in |
| horasSueno | numeric | Horas de sueño medias, sin tope superior fijado |
| estres, agujetas, fatiga | integer (1–10) | Percepción del cliente |
| notas | text? | Notas libres |

**Reglas de dominio**
- No puede haber dos check-in del mismo cliente con la misma `fecha`.
- `estres`, `agujetas`, `fatiga` deben estar entre 1 y 10.
- **Sin relación (FK) con Registro de medidas corporales**: comparten `fecha` por convención de uso de la interfaz, no por restricción de dominio. El front hace las dos inserciones una vez rellenados ambos formularios, sin transacción que las una en base de datos.

## 11. Pack de entrenamiento (RF-25)

Plantilla de ejercicios que el entrenador reutiliza al planificar. **No forma
parte de la cadena del planning**: tiene tablas propias (`packs`,
`pack_ejercicios`, `pack_series`), porque un pack no se entrena ni se registra,
y lo que un planning lleva encima para eso (`estadoRegistro`,
`minutosRealizados`, `fechaRealizada`) no tiene sentido en él.

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| nombre | text | Único entre packs, sin distinguir mayúsculas ni espacios de los extremos |
| tipos | colección de enum (fuerza / cardio / fortalecimiento) | Etiquetas, al menos una. **Solo descriptivas** (desde el 2026-10-27) |
| creadoEn | timestamptz | Fecha de creación |
| ejercicios | colección de Ejercicio del pack | Composición |

**Reglas de dominio**
- **Puede mezclar tipos de ejercicio** (por ejemplo, cardio y fuerza). Sus etiquetas de tipo dicen de qué va, para reconocerlo en la lista, pero **no limitan** qué ejercicios admite, y se pueden cambiar al editar. Al menos una; sin repetidos. Hasta el 2026-10-27 el tipo era uno y mandaba sobre los ejercicios.
- Solo lo ve y lo toca el **entrenador**: ni el cliente ni el administrador (RLS).
- **Aplicar un pack a un bloque copia** sus ejercicios, con lo que tuvieran preparado, **al final** del bloque, en una sola transacción (`aplicar_pack_a_bloque`). A partir de ahí lo copiado es del planning: **editar el pack después no cambia lo ya planificado**.
- Al aplicar, los ejercicios **dados de baja se omiten** (un ejercicio eliminado no se añade a bloques nuevos) y se informa de cuántos. Un pack **sin ejercicios no se puede aplicar**.
- El tipo del bloque no restringe qué pack se le aplica.
- Borrado **físico**, como el de un planning: es una plantilla, no un dato de nadie. Se lleva sus ejercicios y sus series; lo ya planificado a partir de él no se toca, porque se copió.

## 12. Ejercicio del pack

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| packId | referencia a Pack | Propietario |
| ejercicioId | referencia a Ejercicio | Ejercicio de la biblioteca |
| orden | integer (> 0) | Posición dentro del pack |
| descansoSeg | integer (> 0)? | Descanso preparado |
| minutos | numeric (> 0)? | Solo en ejercicios que van por minutos (Cardio) |
| series | colección de Serie del pack | Solo en ejercicios que van por series |

**Reglas de dominio**
- **Todo lo preparado es opcional**, a diferencia del planning: un pack puede ser solo la lista de ejercicios. Lo que falte se rellena en el planning después de aplicarlo.
- **Series y minutos son excluyentes**, según el modo de planificación del tipo **del ejercicio** (no del pack): un cardio no lleva series y lo que va por series no lleva minutos (triggers).
- No puede haber dos con el mismo `orden` en el mismo pack. Se reordena con **flechas**, renumerando el conjunto entero de una vez (`reordenar_pack_ejercicios`).
- Un ejercicio que se da de baja en la biblioteca **se queda** en el pack, marcado, pero no se copia al aplicarlo.
- Se guarda con sus series de una pieza (`guardar_ejercicio_del_pack`): o entra todo, o nada.

## 13. Serie del pack

Hermana de la Serie planificada, colgando del pack en vez de una semana.

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| numeroSerie | integer (> 0) | 1ª, 2ª, 3ª serie... |
| repeticiones | integer (> 0) | Objetivo |
| peso | numeric (> 0)? | Carga orientativa |
| rir | integer? (0–10) | RIR objetivo |

**Reglas de dominio**
- No puede haber dos series con el mismo `numeroSerie` en el mismo Ejercicio del pack.
- Mismas validaciones que una Serie planificada (en Dart se reutiliza `DatosSerie` entera).

## Restricciones transversales

- Un único entrenador: ninguna entidad lleva `entrenadorId`.
- Sin modo offline en esta versión.
- El administrador **no** tiene acceso a medidas, fotos ni check-in de los clientes (ausencia de política RLS = sin acceso).
