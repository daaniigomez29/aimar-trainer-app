# docs/ui-design.md — Guía de diseño de la interfaz (Aimar)
 
Especificación visual para implementar las pantallas de la app en Flutter,
derivada del prototipo diseñado en Claude Design. Este documento da los
valores exactos (colores, tipografía, espaciado) y la estructura de cada
pantalla; las capturas exportadas del canvas son la referencia visual y este
documento es la referencia de implementación. Úsalos juntos.
 
No copies la paginación HTML del prototipo: tradúcela a widgets nativos de
Flutter (`BottomNavigationBar`, `Card`, `Slider`, `ListView`, etc.) siguiendo
la estructura de carpetas y convenciones ya definidas en `AGENTS.md`.
 
## 1. Temas
 
La app usa **dos temas**, elegidos por rol, no por preferencia del sistema:
 
- **Tema oscuro** → todas las pantallas de **cliente** (Mi planning, Registro
  de ejercicio, Control semanal, Configuración, Biblioteca).
- **Tema oscuro también** para el **entrenador** (se igualó al del cliente
  para que la app se sienta como una sola pieza).
Define ambos como `ThemeData` (o `ColorScheme`) en `lib/core/theme/`, con un
único juego de tokens ya que ambos roles comparten el tema oscuro.
 
## 2. Tokens de color
 
| Token | Valor | Uso |
|---|---|---|
| `bg` | `#050404` | Fondo de pantalla |
| `surface` | `#121214` | Tarjetas, barras, inputs |
| `surface2` | `#1B1C1F` | Fondos secundarios (iconos, chips inactivos) |
| `surface3` | `#26282C` | Pistas de sliders, placeholders de imagen |
| `border` | `#2D2F33` | Bordes de tarjetas e inputs |
| `text` | `#F5F6F7` | Texto principal |
| `textMuted` | `#9CA2A9` | Texto secundario |
| `textFaint` | `#6C7278` | Texto terciario / deshabilitado |
| `accent` | `#1C85FF` | Color de marca: CTAs, foco, elementos activos |
| `accentInk` | `#FFFFFF` | Texto/iconos sobre fondo `accent` |
| `accentSoft` | `#1C85FF` al 16% opacidad | Fondos de estado activo/seleccionado |
| `secondary` | `#FFB136` (ámbar) | Dato "planificado" por el entrenador, distinto de lo que registra el cliente |
| `secondarySoft` | `#FFB136` al 16% opacidad | Chips/etiquetas secundarias |
| `success` | `#4ADE80` | Serie completada |
| `danger` | `#FF5A5F` | Errores / avisos |
 
Sombra estándar de tarjetas: `0 16px 32px rgba(0,0,0,0.45)` (puede
aproximarse con `BoxShadow` o un `elevation` moderado en Material).
 
## 3. Tipografía
 
- **Títulos / cifras destacadas**: Space Grotesk, 500–700. Úsala en nombres
  de ejercicio, títulos de pantalla y números grandes (ej. contador de
  series completadas).
- **Resto de la interfaz**: IBM Plex Sans, 400–600.
- Ambas están en Google Fonts; añade el paquete `google_fonts` o incrusta
  las fuentes como assets si se prefiere no depender de red.
Escala orientativa: 22–24px títulos de pantalla, 17–19px títulos de tarjeta,
14–15px cuerpo, 11–13px metadatos/etiquetas.
 
## 4. Espaciado y forma
 
- Radio de tarjetas grandes: 16–20px. Botones/CTAs: 14–16px. Chips/pastillas: 999px (circular).
- Padding exterior de pantalla: 20px horizontal.
- Separación entre bloques de una pantalla: 14–18px.
- Botones de acción principal (CTA): altura 52px, ancho completo, fondo `accent`, texto `accentInk`.
## 5. Patrones de componente
 
- **Chip de filtro**: borde + fondo sutil cuando está activo (`accentSoft`/`accent`), texto `textMuted` cuando inactivo.
- **Tarjeta**: fondo `surface`, borde 1px `border`, radio 16px, sombra estándar.
- **Slider** (usado en Control semanal): pista fina `surface3`, relleno y pulgar en `accent`, valor numérico alineado a la derecha de la etiqueta.
- **Interruptor (toggle)**: pista `surface3` apagado / `accent` encendido, círculo blanco.
- **Barra de navegación inferior (cliente)**: 5 destinos — Mi planning, Mi progreso, Control semanal, Biblioteca, Configuración. Icono + etiqueta, color `accent` en el ítem activo, `textFaint` en el resto.
- **Navegación del entrenador**: barra lateral en escritorio (4 destinos: Planificación, Clientes, Biblioteca, Ajustes); en móvil, los mismos 4 destinos como barra inferior.
## 6. Pantallas
 
### 6.1 Mi planning (cliente, móvil — pantalla de entrada tras login)
Cabecera con saludo y avatar. Tira horizontal de 7 días (el día actual resaltado en `accent`). Tarjeta de la sesión de hoy: título, progreso circular (series completadas), lista de ejercicios con estado (hecho / en curso / pendiente). Fila de estadísticas rápidas (próximo control, sesiones de la semana). CTA "Continuar entrenamiento". Barra de navegación inferior.
 
### 6.2 Registro de ejercicio (cliente, móvil)
Cabecera con flecha atrás, contador "Ejercicio X de N" y puntos de progreso. Fila superior: imagen del ejercicio (100×100, de la entidad `Ejercicio`) a la izquierda + grupo muscular, nombre y enlace "Ver vídeo" a la derecha. Por cada serie: una tarjeta con lo **planificado** por el entrenador (etiqueta discreta en color secundario) y, debajo, los campos editables de **kg / reps / RIR** que rellena el cliente, más un botón de check para marcarla completada. Aviso de descanso recomendado. Nota de texto del entrenador. CTA fijo "Guardar y siguiente ejercicio".
 
### 6.3 Control semanal (cliente, móvil — flujo de 2 pasos, uno visible a la vez)
**Paso 1 — Medidas corporales**: fecha + "Cambiar día", campos de peso (obligatorio) y medidas opcionales (pecho, cintura, cadera, cuádriceps, brazos), botón "Continuar".
**Paso 2 — Check-in de recuperación**: sliders para horas de sueño, estrés, agujetas y fatiga (valor numérico a la derecha de cada uno), campo de notas opcional, botón "Guardar check-in". La flecha atrás del paso 2 regresa al paso 1 sin perder los datos introducidos.
 
### 6.4 Biblioteca (cliente, móvil)
Buscador, chips de filtro por grupo muscular (funcionales: filtran la lista), lista de ejercicios con miniatura, nombre, grupo muscular, tipo (fuerza/cardio) e indicador de vídeo disponible.
 
### 6.5 Configuración (cliente, móvil)
Sección "Cómo te avisamos": notificaciones en el dispositivo (interruptor) y correo electrónico (siempre activo, de respaldo). Texto explicativo de cuándo se notifica.
 
### 6.6 Planificación semanal — entrenador, escritorio
Barra superior: marca, selector de cliente, navegación de semana, botón "Guardar cambios". Barra lateral de navegación. Área principal: pestañas de día, bloques de ejercicios con series editables (kg/reps/RIR) en cuadrícula. Panel fijo a la derecha con la biblioteca de ejercicios (buscador, filtros, lista con botón "+" para añadir a la sesión).
 
### 6.7 Planificación semanal — entrenador, móvil
Misma información que la vista de escritorio en una sola columna. El panel de biblioteca **no se muestra inline**: un botón flotante "+" abre un modal (hoja inferior) con buscador, filtros y lista de ejercicios para añadir. Barra de navegación inferior del entrenador.