// CU-17 / RF-17 · Dar de alta cliente.
//
// Crea el usuario en Auth, su fila en `perfiles` (rol `cliente`) y su ficha en
// `clientes`, y le envía la invitación por correo.
//
// SOBRE LA ATOMICIDAD: no hay transacción posible que cubra los tres pasos. Crear
// el usuario en Auth es una llamada HTTP a GoTrue, un servicio aparte, y cada
// petición a PostgREST va en su propia transacción. Así que se compensa a mano:
// si falla un paso, se deshacen los anteriores en orden inverso. Borrar el usuario
// de Auth aquí NO contradice la regla de "bajas siempre lógicas": no se está dando
// de baja a un cliente, se está deshaciendo un alta que no llegó a completarse.
//
// Contrato en docs/architecture.md ("Contrato de las Edge Functions").

import {
  autorizarGestorDeClientes,
  clienteAdministrativo,
  respuestaError,
  respuestaJson,
  respuestaPreflight,
} from "../_shared/autorizacion.ts";
import { correoDeInvitacion, enviarCorreo } from "../_shared/correo.ts";

interface PeticionCrearCliente {
  nombre: string;
  correo: string;
  fechaNacimiento: string | null;
  alturaCm: number | null;
  pesoInicialKg: number | null;
  objetivos: string | null;
  diaControlPreferido: string;
}

const DIAS_VALIDOS = [
  "lunes",
  "martes",
  "miercoles",
  "jueves",
  "viernes",
  "sabado",
  "domingo",
];

const FORMATO_CORREO = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const FORMATO_FECHA = /^\d{4}-\d{2}-\d{2}$/;

Deno.serve(async (req) => {
  const preflight = respuestaPreflight(req);
  if (preflight) return preflight;

  if (req.method !== "POST") {
    return respuestaError(405, "metodo_no_permitido", "Usa POST.");
  }

  // El 403 corta antes de tocar `service_role`: ni un POST directo con curl
  // puede crear cuentas sin un JWT de entrenador o administrador.
  const autorizacion = await autorizarGestorDeClientes(req);
  if (autorizacion instanceof Response) return autorizacion;

  let cuerpo: PeticionCrearCliente;
  try {
    cuerpo = await req.json();
  } catch {
    return respuestaError(
      400,
      "datos_invalidos",
      "El cuerpo no es JSON válido.",
    );
  }

  const errorValidacion = validar(cuerpo);
  if (errorValidacion) {
    return respuestaError(400, "datos_invalidos", errorValidacion);
  }

  const correo = cuerpo.correo.trim().toLowerCase();
  const nombre = cuerpo.nombre.trim();
  const admin = clienteAdministrativo();

  // 409 si ya hay un cliente ACTIVO con ese correo. El índice único parcial lo
  // garantiza igualmente, pero comprobarlo antes evita crear el usuario en Auth
  // para luego tener que borrarlo.
  const { data: yaExiste, error: errorConsulta } = await admin
    .from("clientes")
    .select("id")
    .eq("estado", "activo")
    .ilike("correo", correo)
    .maybeSingle();

  if (errorConsulta) {
    return respuestaError(
      500,
      "error_interno",
      `No se pudo comprobar el correo: ${errorConsulta.message}`,
    );
  }
  if (yaExiste) {
    return respuestaError(
      409,
      "correo_duplicado",
      "Ya hay un cliente activo con ese correo.",
    );
  }

  // Paso 1: crear el usuario en Auth y obtener el enlace de invitación.
  // `generateLink` con tipo `invite` crea el usuario y devuelve el enlace SIN
  // enviar ningún correo, que es justo lo que interesa: el correo lo manda Resend
  // con plantilla propia.
  const urlBase = Deno.env.get("APP_BASE_URL");
  const { data: datosEnlace, error: errorEnlace } = await admin.auth.admin
    .generateLink({
      type: "invite",
      email: correo,
      options: {
        // Marca para la app: un enlace de invitación hace que GoTrue emita
        // `signedIn`, igual que un login normal, así que sin esta bandera el
        // cliente entraría sin haber fijado contraseña y luego no podría volver
        // a entrar. La app la lee y lo lleva a elegir contraseña; se limpia al
        // guardarla.
        //
        // Va dentro de `options`, que es donde lo espera el tipo. Estuvo en la
        // raíz y funcionaba igual, porque la librería monta el cuerpo con
        // `{...resto, ...options}`, pero no compilaba.
        data: { debe_fijar_contrasena: true },
        ...(urlBase ? { redirectTo: urlBase } : {}),
      },
    });

  if (errorEnlace || !datosEnlace?.user) {
    const mensaje = errorEnlace?.message ?? "No se pudo crear el usuario.";
    // Un correo que ya existe en Auth (por ejemplo, de un cliente dado de baja)
    // no se puede reutilizar: Auth no admite dos usuarios con el mismo correo,
    // aunque el índice de `clientes` sí permita reutilizarlo entre bajas.
    const yaRegistrado = /already|exists|registered/i.test(mensaje);
    return respuestaError(
      yaRegistrado ? 409 : 500,
      yaRegistrado ? "correo_duplicado" : "error_interno",
      yaRegistrado
        ? "Ese correo ya tiene una cuenta en el sistema. Si pertenece a un " +
          "cliente dado de baja, usa otro correo o reactívalo."
        : `No se pudo crear la cuenta: ${mensaje}`,
    );
  }

  const clienteId = datosEnlace.user.id;
  const enlaceInvitacion = datosEnlace.properties?.action_link;

  /**
   * Deshace el alta a medias. El cliente nunca llegó a existir, así que esto no
   * contradice la regla de "bajas siempre lógicas".
   *
   * Basta con borrar el usuario de Auth: `perfiles.id` y `clientes.id` referencian
   * `auth.users(id)` con `on delete cascade`, así que sus filas se van con él. Por
   * eso `service_role` no necesita el privilegio `DELETE` sobre esas tablas.
   */
  async function compensar(): Promise<void> {
    await admin.auth.admin.deleteUser(clienteId);
  }

  // Paso 2: perfil con rol `cliente`.
  const { error: errorPerfil } = await admin
    .from("perfiles")
    .insert({ id: clienteId, rol: "cliente" });

  if (errorPerfil) {
    await compensar();
    return respuestaError(
      500,
      "error_interno",
      `No se pudo crear el perfil: ${errorPerfil.message}`,
    );
  }

  // Paso 3: ficha en `clientes`.
  const { error: errorFicha } = await admin.from("clientes").insert({
    id: clienteId,
    nombre,
    correo,
    fecha_nacimiento: cuerpo.fechaNacimiento ?? null,
    altura_cm: cuerpo.alturaCm ?? null,
    peso_inicial_kg: cuerpo.pesoInicialKg ?? null,
    objetivos: cuerpo.objetivos?.trim() || null,
    dia_control_preferido: cuerpo.diaControlPreferido,
  });

  if (errorFicha) {
    await compensar();
    // 23505 es la violación del índice único de correo entre activos: puede
    // ocurrir si dos altas con el mismo correo llegan a la vez.
    const duplicado = errorFicha.code === "23505";
    return respuestaError(
      duplicado ? 409 : 500,
      duplicado ? "correo_duplicado" : "error_interno",
      duplicado
        ? "Ya hay un cliente activo con ese correo."
        : `No se pudo crear la ficha: ${errorFicha.message}`,
    );
  }

  // Paso 4: invitación por correo. Si falla, el alta SE MANTIENE y se informa:
  // la ficha ya es válida y la invitación se puede reenviar.
  const plantilla = correoDeInvitacion({
    nombre,
    enlace: enlaceInvitacion ?? (urlBase ?? ""),
  });
  const envio = enlaceInvitacion
    ? await enviarCorreo({
      destinatario: correo,
      asunto: plantilla.asunto,
      html: plantilla.html,
      texto: plantilla.texto,
    })
    : {
      enviado: false,
      motivo: "Auth no devolvió el enlace de invitación.",
    };

  // `estado: "invitado"` es el del contrato y describe la invitación, no la
  // columna `estado` de la ficha, que es `activo` (el enum solo admite
  // activo/baja).
  return respuestaJson(201, {
    clienteId,
    estado: "invitado",
    invitacionEnviada: envio.enviado,
    ...(envio.entregadoEnLocal ? { entregadoEnBuzonLocal: true } : {}),
    ...(envio.enviado ? {} : { avisoInvitacion: envio.motivo }),
  });
});

function validar(cuerpo: PeticionCrearCliente): string | null {
  if (!cuerpo.nombre?.trim()) return "El nombre es obligatorio.";
  if (!cuerpo.correo?.trim()) return "El correo es obligatorio.";
  if (!FORMATO_CORREO.test(cuerpo.correo.trim())) {
    return "El correo no tiene un formato válido.";
  }
  if (!DIAS_VALIDOS.includes(cuerpo.diaControlPreferido)) {
    return `diaControlPreferido debe ser uno de: ${DIAS_VALIDOS.join(", ")}.`;
  }
  if (
    cuerpo.fechaNacimiento !== null &&
    cuerpo.fechaNacimiento !== undefined &&
    !FORMATO_FECHA.test(cuerpo.fechaNacimiento)
  ) {
    return "fechaNacimiento debe tener el formato YYYY-MM-DD.";
  }
  if (!esNumeroPositivoOpcional(cuerpo.alturaCm)) {
    return "alturaCm debe ser un número positivo.";
  }
  if (!esNumeroPositivoOpcional(cuerpo.pesoInicialKg)) {
    return "pesoInicialKg debe ser un número positivo.";
  }
  return null;
}

function esNumeroPositivoOpcional(valor: number | null | undefined): boolean {
  if (valor === null || valor === undefined) return true;
  return typeof valor === "number" && Number.isFinite(valor) && valor > 0;
}
