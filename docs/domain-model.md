# Modelo de dominio

Resumen técnico de las 10 entidades de dominio: atributos y reglas de negocio
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

## 3. Sesión de entrenamiento

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| planningId | referencia a Planning semanal | Propietario |
| fecha | date | Fecha real de la sesión (planificación por calendario) |
| nombre | text | Nombre descriptivo |
| resultadoRegistrado | boolean | Derivado: todos sus ejercicios planificados están "registrado" |
| bloques | colección de Bloque de ejercicio | Composición |

**Reglas de dominio**
- No puede haber dos sesiones con la misma `fecha` en el mismo planning.
- `fecha` debe caer dentro de la semana del planning (`fechaInicio` … `fechaInicio + 6`).
- Eliminar una sesión elimina en cascada sus bloques y ejercicios planificados.
- Se ordenan directamente por `fecha`; no tienen campo `orden` propio.

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
- Eliminar un bloque elimina en cascada sus ejercicios planificados (no afecta a la biblioteca general de Ejercicio).

## 5. Ejercicio (biblioteca)

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| nombre | text | Único entre ejercicios activos |
| grupoMuscular | text? | Grupo muscular principal |
| equipamiento | text? | Material necesario |
| descripcion | text | Técnica de ejecución |
| videoEjemploUrl | text? | Vídeo de ejemplo |
| tipo | enum (fuerza / cardio) | Determina series vs. minutos |
| estado | enum (activo / eliminado) | Baja lógica |

**Reglas de dominio**
- No puede haber dos ejercicios activos con el mismo `nombre`.
- Baja siempre lógica: un ejercicio "eliminado" no puede añadirse a nuevos bloques, pero sigue visible en los que ya lo usaban.
- Editar nombre/descripción/grupo muscular no altera parámetros ya guardados en ejercicios planificados existentes.
- Todos los usuarios autenticados (incluidos clientes) pueden **leer** la biblioteca completa (para ver vídeos de ejemplo).

## 6. Ejercicio planificado

| Atributo | Tipo | Descripción |
| --- | --- | --- |
| id | uuid | Clave |
| bloqueId | referencia a Bloque de ejercicio | Propietario |
| ejercicioId | referencia a Ejercicio | Ejercicio de la biblioteca usado |
| orden | integer | Posición dentro del bloque |
| descansoPlanificado | integer (seg)? | Solo Fuerza |
| minutosPlanificados | numeric? | Solo Cardio, define el entrenador |
| minutosRealizados | numeric? | Solo Cardio, registra el cliente |
| seriesPlanificadas | colección de Serie planificada | Solo Fuerza |
| estadoRegistro | enum (pendiente / registrado) | Derivado, mantenido por trigger |

**Reglas de dominio**
- **Fuerza y Cardio son mutuamente excluyentes**: si `Ejercicio.tipo = fuerza`, usa series (no minutos); si `= cardio`, usa minutos (no series).
- No puede haber dos "Ejercicio planificado" con el mismo `orden` en el mismo bloque.
- `estadoRegistro` pasa a "registrado" si existe al menos una Serie realizada (Fuerza) o si `minutosRealizados` tiene valor (Cardio).
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

## Restricciones transversales

- Un único entrenador: ninguna entidad lleva `entrenadorId`.
- Sin modo offline en esta versión.
- El administrador **no** tiene acceso a medidas, fotos ni check-in de los clientes (ausencia de política RLS = sin acceso).
