// CU-22 · Recordatorios diarios de sesión y de día de control.
//
// La invoca el job de pg_cron una vez al día (ver la migración
// `20261003110100_job_recordatorios.sql`). Hace dos barridos:
//
//   1. Clientes con una sesión programada para MAÑANA, en un planning activo.
//   2. Clientes cuyo `dia_control_preferido` es HOY.
//
// Y por cada aviso manda correo (siempre: es el respaldo universal) y push (solo
// si el cliente lo tiene activado). Todo queda anotado en `avisos_enviados`,
// incluidos los **omitidos**, que es lo que pide la excepción de CU-22.
//
// QUIÉN PUEDE LLAMARLA: no lleva JWT de usuario, porque quien llama es un job de
// la base de datos. Se identifica con la cabecera `x-secreto-cron`, que se
// compara con `SECRETO_CRON`. Sin ese secreto configurado la función no atiende a
// nadie, en lugar de quedar abierta.
//
// LAS FECHAS SE CALCULAN EN Europe/Madrid (architecture.md), no en UTC: a las
// 23:30 de Madrid en verano, en UTC todavía es el día anterior, y "mañana"
// saldría mal.

import {
  clienteAdministrativo,
  respuestaError,
  respuestaJson,
  respuestaPreflight,
} from "../_shared/autorizacion.ts";
import {
  correoDeControlSemanal,
  correoDeSemanaNueva,
  enviarCorreo,
} from "../_shared/correo.ts";
import {
  enviarPush,
  pushConfigurado,
  type SuscripcionPush,
} from "../_shared/push.ts";

const ZONA = "Europe/Madrid";

/** Día de la semana tal y como lo guarda el enum `dia_semana` de Postgres. */
const DIAS = [
  "domingo",
  "lunes",
  "martes",
  "miercoles",
  "jueves",
  "viernes",
  "sabado",
] as const;

type TipoAviso = "sesion" | "control";
type CanalAviso = "correo" | "push";
type EstadoAviso = "enviado" | "omitido" | "fallido";

/** Lo que devuelve la consulta de plannings que arrancan hoy. */
interface FilaPlanning {
  readonly id: string;
  readonly fecha_inicio: string;
  readonly sesiones_entrenamiento: readonly { readonly id: string }[] | null;
  readonly clientes: ClienteAvisado | null;
}

interface ClienteAvisado {
  readonly id: string;
  readonly nombre: string;
  readonly correo: string;
}

interface Aviso {
  readonly clienteId: string;
  readonly tipo: TipoAviso;
  readonly canal: CanalAviso;
  readonly estado: EstadoAviso;
  readonly fechaReferencia: string;
  readonly motivo?: string;
}

Deno.serve(async (req) => {
  const preflight = respuestaPreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return respuestaError(405, "metodo_no_permitido", "Usa POST.");
  }

  const secretoEsperado = Deno.env.get("SECRETO_CRON");
  if (!secretoEsperado) {
    // Mejor no atender a nadie que atender a cualquiera.
    return respuestaError(
      500,
      "sin_configurar",
      "Falta SECRETO_CRON en el entorno de la función.",
    );
  }
  if (req.headers.get("x-secreto-cron") !== secretoEsperado) {
    return respuestaError(401, "no_autorizado", "Secreto incorrecto.");
  }

  const supabase = clienteAdministrativo();
  const hoy = fechaEnZona(new Date(), 0);
  const diaDeControl = DIAS[diaSemanaEnZona(new Date())];
  const urlApp = Deno.env.get("APP_BASE_URL") ?? "";

  const avisos: Aviso[] = [];

  // --- 1. Semanas que arrancan hoy ------------------------------------------

  // Las sesiones ya no tienen fecha planificada: el entrenador decide "cuatro
  // sesiones esta semana" y el cliente las hace cuando puede. Asi que no se
  // puede avisar de "manana toca Empuje A"; lo que se manda es el resumen de la
  // semana el dia en que empieza.
  //
  // Solo plannings activos: una semana archivada ya no se entrena.
  const { data: plannings, error: errorPlannings } = await supabase
    .from("plannings_semanales")
    .select(
      "id, fecha_inicio, sesiones_entrenamiento(id), clientes!inner(id, nombre, correo, estado)",
    )
    .eq("fecha_inicio", hoy)
    .eq("estado", "activo")
    .eq("clientes.estado", "activo");

  if (errorPlannings) {
    return respuestaError(
      500,
      "error_consulta",
      `No se pudieron leer los plannings: ${errorPlannings.message}`,
    );
  }

  for (const planning of (plannings ?? []) as unknown as FilaPlanning[]) {
    const cliente = planning.clientes;
    const cuantas = planning.sesiones_entrenamiento?.length ?? 0;
    // Una semana sin sesiones no da pie a ningun aviso.
    if (!cliente || cuantas === 0) continue;

    avisos.push(
      ...await avisar({
        supabase,
        cliente,
        tipo: "sesion",
        fechaReferencia: planning.fecha_inicio,
        correo: correoDeSemanaNueva({
          nombre: cliente.nombre,
          sesiones: cuantas,
          enlace: `${urlApp}/#/cliente`,
        }),
        push: {
          titulo: "Nueva semana de entrenamiento",
          cuerpo: cuantas === 1
            ? "Tienes 1 sesion esta semana."
            : `Tienes ${cuantas} sesiones esta semana.`,
          ruta: "/cliente",
        },
      }),
    );
  }

  // --- 2. Día de control -----------------------------------------------------

  const { data: clientesDeControl, error: errorClientes } = await supabase
    .from("clientes")
    .select("id, nombre, correo")
    .eq("estado", "activo")
    .eq("dia_control_preferido", diaDeControl);

  if (errorClientes) {
    return respuestaError(
      500,
      "error_consulta",
      `No se pudieron leer los clientes: ${errorClientes.message}`,
    );
  }

  for (const cliente of clientesDeControl ?? []) {
    avisos.push(
      ...await avisar({
        supabase,
        cliente,
        tipo: "control",
        fechaReferencia: hoy,
        correo: correoDeControlSemanal({
          nombre: cliente.nombre,
          enlace: `${urlApp}/#/cliente/control`,
        }),
        push: {
          titulo: "Hoy toca control semanal",
          cuerpo: "Anota tus medidas y rellena el check-in.",
          ruta: "/cliente/control",
        },
      }),
    );
  }

  return respuestaJson(200, {
    fechaDeHoy: hoy,
    diaDeControl,
    resumen: resumir(avisos),
    avisos,
  });
});

/**
 * Manda los dos canales a un cliente y devuelve lo anotado.
 *
 * El correo va siempre; el push depende de las preferencias. Si no se puede
 * mandar, se anota el motivo: "omitido" cuando es decisión del cliente,
 * "fallido" cuando el envío se intentó y salió mal.
 */
async function avisar({
  supabase,
  cliente,
  tipo,
  fechaReferencia,
  correo,
  push,
}: {
  supabase: ReturnType<typeof clienteAdministrativo>;
  cliente: ClienteAvisado;
  tipo: TipoAviso;
  fechaReferencia: string;
  correo: { asunto: string; html: string; texto: string };
  push: { titulo: string; cuerpo: string; ruta: string };
}): Promise<Aviso[]> {
  const anotados: Aviso[] = [];

  // --- Correo ---
  if (await yaAvisado(supabase, cliente.id, tipo, "correo", fechaReferencia)) {
    // Nada que hacer: el job ya avisó por este canal para esta fecha.
  } else {
    const resultado = await enviarCorreo({
      destinatario: cliente.correo,
      asunto: correo.asunto,
      html: correo.html,
      texto: correo.texto,
    });
    anotados.push(
      await anotar(supabase, {
        clienteId: cliente.id,
        tipo,
        canal: "correo",
        estado: resultado.enviado ? "enviado" : "fallido",
        fechaReferencia,
        motivo: resultado.motivo,
      }),
    );
  }

  // --- Push ---
  if (await yaAvisado(supabase, cliente.id, tipo, "push", fechaReferencia)) {
    return anotados;
  }

  const { data: preferencias } = await supabase
    .from("preferencias_notificacion")
    .select("push_activado")
    .eq("cliente_id", cliente.id)
    .maybeSingle();

  // Sin fila, el push está desactivado: el cliente nunca dio el permiso.
  if (!preferencias?.push_activado) {
    anotados.push(
      await anotar(supabase, {
        clienteId: cliente.id,
        tipo,
        canal: "push",
        estado: "omitido",
        fechaReferencia,
        motivo: "El cliente tiene las notificaciones push desactivadas.",
      }),
    );
    return anotados;
  }

  if (!pushConfigurado()) {
    anotados.push(
      await anotar(supabase, {
        clienteId: cliente.id,
        tipo,
        canal: "push",
        estado: "fallido",
        fechaReferencia,
        motivo: "Faltan las claves VAPID en el entorno de la función.",
      }),
    );
    return anotados;
  }

  const { data: suscripciones } = await supabase
    .from("suscripciones_push")
    .select("id, endpoint, clave_p256dh, clave_auth")
    .eq("cliente_id", cliente.id);

  if (!suscripciones || suscripciones.length === 0) {
    anotados.push(
      await anotar(supabase, {
        clienteId: cliente.id,
        tipo,
        canal: "push",
        estado: "omitido",
        fechaReferencia,
        motivo: "El cliente no tiene ningún dispositivo suscrito.",
      }),
    );
    return anotados;
  }

  // Un cliente puede tener varios dispositivos: basta con que uno reciba el
  // aviso para darlo por enviado.
  let algunoEnviado = false;
  const motivos: string[] = [];
  for (const fila of suscripciones) {
    const suscripcion: SuscripcionPush = {
      id: fila.id,
      endpoint: fila.endpoint,
      claveP256dh: fila.clave_p256dh,
      claveAuth: fila.clave_auth,
    };
    const resultado = await enviarPush(suscripcion, push);
    if (resultado.enviado) {
      algunoEnviado = true;
      continue;
    }
    if (resultado.motivo) motivos.push(resultado.motivo);
    if (resultado.suscripcionCaducada) {
      // El navegador ya no la reconoce: se tira para no reintentarla cada día.
      await supabase.from("suscripciones_push").delete().eq("id", fila.id);
    }
  }

  anotados.push(
    await anotar(supabase, {
      clienteId: cliente.id,
      tipo,
      canal: "push",
      estado: algunoEnviado ? "enviado" : "fallido",
      fechaReferencia,
      motivo: algunoEnviado ? undefined : motivos.join(" | ").slice(0, 400),
    }),
  );
  return anotados;
}

/** `true` si ya se avisó con éxito por ese canal para esa fecha. */
async function yaAvisado(
  supabase: ReturnType<typeof clienteAdministrativo>,
  clienteId: string,
  tipo: TipoAviso,
  canal: CanalAviso,
  fechaReferencia: string,
): Promise<boolean> {
  const { data } = await supabase
    .from("avisos_enviados")
    .select("estado")
    .eq("cliente_id", clienteId)
    .eq("tipo", tipo)
    .eq("canal", canal)
    .eq("fecha_referencia", fechaReferencia)
    .maybeSingle();
  return data?.estado === "enviado";
}

/**
 * Deja el aviso en la bitácora. El índice único por cliente, tipo, canal y fecha
 * hace el upsert: un segundo intento del mismo día corrige el estado anterior en
 * lugar de añadir una fila.
 */
async function anotar(
  supabase: ReturnType<typeof clienteAdministrativo>,
  aviso: Aviso,
): Promise<Aviso> {
  await supabase.from("avisos_enviados").upsert({
    cliente_id: aviso.clienteId,
    tipo: aviso.tipo,
    canal: aviso.canal,
    estado: aviso.estado,
    fecha_referencia: aviso.fechaReferencia,
    motivo: aviso.motivo ?? null,
  }, { onConflict: "cliente_id,tipo,canal,fecha_referencia" });
  return aviso;
}

function resumir(avisos: Aviso[]): Record<string, number> {
  const resumen: Record<string, number> = {
    enviados: 0,
    omitidos: 0,
    fallidos: 0,
  };
  for (const aviso of avisos) {
    if (aviso.estado === "enviado") resumen.enviados++;
    else if (aviso.estado === "omitido") resumen.omitidos++;
    else resumen.fallidos++;
  }
  return resumen;
}

/** Fecha `YYYY-MM-DD` en Europe/Madrid, desplazada `dias` días. */
function fechaEnZona(ahora: Date, dias: number): string {
  const desplazada = new Date(ahora.getTime() + dias * 24 * 60 * 60 * 1000);
  // `en-CA` da directamente el formato ISO, que es el que espera Postgres.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: ZONA,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(desplazada);
}

/** Día de la semana (0 = domingo) en Europe/Madrid. */
function diaSemanaEnZona(ahora: Date): number {
  const nombre = new Intl.DateTimeFormat("en-US", {
    timeZone: ZONA,
    weekday: "short",
  }).format(ahora);
  const indice = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].indexOf(
    nombre,
  );
  return indice < 0 ? 0 : indice;
}
