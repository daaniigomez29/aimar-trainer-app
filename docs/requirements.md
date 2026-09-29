# Requisitos funcionales y casos de uso

Extracto operativo del ERS: qué debe construirse, caso de uso a caso de uso.
El "cómo" (convenciones, arquitectura, esquema) vive en `AGENTS.md` y en los
demás archivos de `docs/`. Actores: **Administrador**, **Entrenador**,
**Cliente**.

## Requisitos funcionales

### Gestión de cuentas
- **RF-01** — Iniciar sesión con usuario/correo y contraseña, validando credenciales antes de dar acceso según rol.

### Biblioteca de ejercicios
- **RF-02** — Añadir ejercicio (nombre, grupo muscular, descripción), sin nombres duplicados entre activos.
- **RF-03** — Editar un ejercicio existente sin afectar referencias ya usadas en plannings anteriores.
- **RF-04** — Eliminar (baja lógica) un ejercicio, avisando si está referenciado en bloques activos.

### Planificación semanal
- **RF-05** — Crear planning semanal para un cliente (fecha de inicio, cliente).
- **RF-06** — Añadir sesiones de entrenamiento (con fecha real) dentro de un planning.
- **RF-07** — Añadir bloques de entrenamiento dentro de una sesión (tipo: calentamiento/fuerza/cardio/movilidad/otro).
- **RF-08** — Añadir ejercicios de la biblioteca a un bloque, con series/reps/peso/descanso (Fuerza) o minutos (Cardio).
- **RF-09 a RF-12** — Editar planning, sesión, bloque y ejercicio dentro de un bloque, respectivamente.
- **RF-13 a RF-16** — Eliminar planning, sesión, bloque y ejercicio dentro de un bloque, respectivamente (con confirmación y cascada donde aplique).

### Gestión de clientes
- **RF-17** — Dar de alta cliente (datos personales y objetivos), creando su cuenta e invitándolo por correo.
- **RF-18** — Dar de baja cliente (lógica), conservando histórico y bloqueando su acceso.
- **RF-19** — Editar ficha de cliente existente.

### Progreso y bienestar
- **RF-20** — El cliente registra el resultado de cada sesión (series/reps/peso/RIR reales, o minutos en cardio).
- **RF-21** — Mostrar al cliente y al entrenador la evolución histórica de sus métricas.
- **RF-22** — Notificar al cliente los días con sesión programada.
- **RF-23** — El entrenador consulta el histórico completo de plannings de un cliente, incluidos los archivados.
- **RF-24** — Recuperar contraseña mediante el correo asociado.

### Requisitos no funcionales
- **RNF-01** — Prever anonimización/eliminación de datos de un cliente a petición (derecho de supresión RGPD); la baja lógica no lo cubre por sí sola.
- **RNF-02** — Datos de salud alojados en infraestructura de la Unión Europea.
- **RNF-03** — Código específico de plataforma aislado tras interfaces, para poder añadir Android sin refactorizar el dominio.

## Casos de uso

Formato por caso de uso: precondición, descripción, secuencia normal,
postcondición, excepciones.

### Gestión de cuentas y biblioteca de ejercicios

**CU-01 Iniciar sesión**
- Precondición: el actor tiene cuenta creada.
- Descripción: el sistema solicita credenciales, identifica el rol y da acceso a sus funciones.
- Secuencia: (1) pantalla de login (2) pide usuario/contraseña (3) el actor las introduce (4) el sistema valida (5) identifica el rol (6) accede a su pantalla principal.
- Postcondición: actor autenticado según su rol.
- Excepciones: credenciales incorrectas → error y vuelta al paso 2; cuenta dada de baja/bloqueada → mensaje de cuenta no disponible, sin acceso.

**CU-02 Añadir ejercicio**
- Precondición: el entrenador ha iniciado sesión.
- Secuencia: (1) solicita añadir ejercicio (2) sistema pide nombre/grupo muscular/equipamiento/descripción (3) el entrenador los introduce (4) valida datos y nombre no duplicado (5) guarda (6) notifica éxito.
- Excepciones: datos incompletos o nombre duplicado → error, vuelta al paso 2.

**CU-03 Editar ejercicio**
- Precondición: el ejercicio existe.
- Secuencia: selecciona ejercicio → muestra datos → modifica → valida → guarda → notifica.
- Excepciones: datos inválidos → error, vuelta a editar.

**CU-04 Eliminar ejercicio**
- Secuencia: selecciona y solicita eliminar → confirmación → confirma → comprueba uso en bloques activos → elimina (lógico) → notifica.
- Excepciones: cancelación → sin cambios; referenciado en bloques activos → aviso explícito, confirmación adicional para continuar.

### Planificación semanal

**CU-05 Añadir planning semanal**
- Precondición: cliente dado de alta.
- Secuencia: solicita crear planning → pide cliente/fecha de inicio/objetivo → valida sin duplicar semana activa → crea vacío → notifica.
- Excepciones: ya existe planning activo esa semana → error, vuelta a introducir datos.

**CU-06 Añadir sesión de entrenamiento**
- Precondición: existe un planning.
- Secuencia: selecciona planning, solicita añadir sesión → pide fecha y nombre → valida fecha dentro de la semana y sin duplicar → añade → notifica.
- Excepciones: fecha ya usada en ese planning o fuera de semana → error.

**CU-07 Añadir bloque de entrenamiento**
- Secuencia: selecciona sesión → pide tipo y orden → valida orden no repetido → añade → notifica.

**CU-08 Añadir ejercicio (a bloque)**
- Secuencia: selecciona bloque → muestra biblioteca → elige ejercicio e indica parámetros (series/reps/peso/descanso o minutos según tipo) → valida → añade → notifica.
- Excepciones: parámetros inválidos → error; biblioteca vacía → ofrece ir a CU-02.

**CU-09 a CU-12 Editar planning / sesión / bloque / ejercicio en bloque**
- Mismo patrón: seleccionar → mostrar datos actuales → modificar → validar → guardar → notificar. Excepción común: datos inválidos o conflicto (fecha/orden duplicado) → error, vuelta a editar.

**CU-13 a CU-16 Eliminar planning / sesión / bloque / ejercicio en bloque**
- Mismo patrón: seleccionar y solicitar eliminar → advertencia de cascada (salvo CU-16, que no elimina de biblioteca) → confirmar → eliminar → notificar. Excepción común: cancelación → sin cambios.

### Gestión de clientes

**CU-17 Dar de alta cliente**
- Precondición: entrenador o administrador con sesión iniciada.
- Secuencia: solicita alta → pide datos personales y objetivos → valida sin correo duplicado (activos) → crea ficha y cuenta de acceso vía Edge Function → envía invitación por correo → notifica al alta.
- Postcondición: cliente registrado, invitación pendiente de aceptar.
- Excepciones: datos incompletos o correo duplicado → error, vuelta a introducir datos.

**CU-18 Dar de baja cliente**
- Secuencia: selecciona cliente, solicita baja → confirmación → confirma → desactiva ficha (lógico), conserva histórico y bloquea acceso en Auth → notifica.
- Postcondición: cliente inactivo, sin poder iniciar sesión, histórico accesible al entrenador.
- Excepciones: cancelación → sin cambios; planning activo en curso → aviso y confirmación explícita.

**CU-19 Editar ficha cliente**
- Secuencia: selecciona ficha → muestra datos → modifica → valida → guarda → notifica.

### Progreso y bienestar

**CU-20 Registrar resultado de sesión**
- Precondición: cliente con sesión programada ese día.
- Secuencia: abre sesión del día → muestra ejercicios previstos → introduce, por ejercicio, resultado real (series/reps/peso/RIR o minutos) → valida → guarda → notifica.
- Postcondición: resultado disponible para CU-21.
- Excepciones: valor no numérico o negativo → error, vuelta a introducir. Un ejercicio puede quedar sin registrar (pendiente).

**CU-21 Consultar progreso de métricas**
- Precondición: al menos un resultado registrado.
- Secuencia: accede a progreso del cliente → filtra ejercicio/métrica y rango de fechas → recupera resultados → muestra gráfica/histórico.
- Excepciones: sin datos en el rango → mensaje informativo.

**CU-22 Recibir notificación de sesión programada**
- Precondición: planning activo con sesiones y notificaciones activadas.
- Secuencia (automática): comprueba sesiones del día siguiente → localiza clientes → genera y envía notificación.
- Excepciones: notificaciones desactivadas → no se envía, se registra como omitido.

**CU-23 Consultar histórico de plannings de cliente**
- Secuencia: selecciona cliente → recupera plannings activos y archivados → lista por fecha con estado → selecciona uno → muestra su detalle completo.
- Excepciones: sin plannings registrados → mensaje informativo.

**CU-24 Recuperar contraseña**
- Secuencia: "He olvidado mi contraseña" → pide correo → valida cuenta existente → envía enlace de restablecimiento → el actor fija nueva contraseña → notifica éxito.
- Excepciones: correo no existente → mensaje genérico (no confirma si la cuenta existe, por seguridad); enlace caducado → error, vuelta al inicio.

## Fuera de alcance (explícito)

- Multi-entrenador y campo `entrenadorId`.
- Modo offline.
- Registro libre de clientes (siempre lo crea entrenador/administrador).
- Apps nativas Android/iOS (solo PWA en esta fase).
- Gestión de cuentas de entrenador/administrador vía la propia app (se hace desde el panel de Supabase).
- Derecho de supresión RGPD como flujo completo (solo anotado como RNF-01 pendiente).
