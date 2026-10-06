// CU-18 / RF-18 · Dar de baja cliente (baja SIEMPRE lógica).
//
// Marca la ficha como `baja` con su `fecha_baja` y bloquea el acceso del usuario
// en Auth. El histórico se conserva íntegro: nunca se borra nada.
//
// Contrato en docs/architecture.md ("Contrato de las Edge Functions").

import {
  autorizarGestorDeClientes,
  clienteAdministrativo,
  respuestaError,
  respuestaJson,
  servirConCors,
} from "../_shared/autorizacion.ts";

interface PeticionDarDeBaja {
  clienteId: string;
}

const FORMATO_UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** 100 años: el bloqueo es indefinido en la práctica. */
const DURACION_BLOQUEO = "876000h";

Deno.serve((req) => servirConCors(req, () => manejar(req)));

async function manejar(req: Request): Promise<Response> {
  if (req.method !== "POST") {
    return respuestaError(405, "metodo_no_permitido", "Usa POST.");
  }

  const autorizacion = await autorizarGestorDeClientes(req);
  if (autorizacion instanceof Response) return autorizacion;

  let cuerpo: PeticionDarDeBaja;
  try {
    cuerpo = await req.json();
  } catch {
    return respuestaError(
      400,
      "datos_invalidos",
      "El cuerpo no es JSON válido.",
    );
  }

  if (!cuerpo.clienteId || !FORMATO_UUID.test(cuerpo.clienteId)) {
    return respuestaError(
      400,
      "datos_invalidos",
      "clienteId debe ser un uuid válido.",
    );
  }

  const admin = clienteAdministrativo();

  const { data: ficha, error: errorConsulta } = await admin
    .from("clientes")
    .select("id, estado")
    .eq("id", cuerpo.clienteId)
    .maybeSingle();

  if (errorConsulta) {
    return respuestaError(
      500,
      "error_interno",
      `No se pudo leer la ficha: ${errorConsulta.message}`,
    );
  }
  if (!ficha) {
    return respuestaError(404, "no_encontrado", "Ese cliente no existe.");
  }
  if (ficha.estado === "baja") {
    return respuestaError(
      409,
      "ya_de_baja",
      "Ese cliente ya estaba dado de baja.",
    );
  }

  // Baja lógica. El constraint `baja_coherente` exige que `fecha_baja` sea
  // posterior a `fecha_alta`, así que se usa la hora del servidor de base de
  // datos y no la del runtime de la función.
  const { error: errorBaja } = await admin
    .from("clientes")
    .update({ estado: "baja", fecha_baja: new Date().toISOString() })
    .eq("id", cuerpo.clienteId)
    .eq("estado", "activo");

  if (errorBaja) {
    return respuestaError(
      500,
      "error_interno",
      `No se pudo dar de baja la ficha: ${errorBaja.message}`,
    );
  }

  // Bloqueo en Auth: a partir de aquí el login devuelve `user_banned`, que la app
  // traduce a "esta cuenta no está disponible" (CU-01, excepción).
  const { error: errorBloqueo } = await admin.auth.admin.updateUserById(
    cuerpo.clienteId,
    { ban_duration: DURACION_BLOQUEO },
  );

  if (errorBloqueo) {
    // La ficha ya está de baja pero el cliente aún podría entrar: se revierte la
    // baja para no dejar un estado contradictorio, y se informa del fallo.
    await admin
      .from("clientes")
      .update({ estado: "activo", fecha_baja: null })
      .eq("id", cuerpo.clienteId);
    return respuestaError(
      500,
      "error_interno",
      `No se pudo bloquear el acceso, la baja se ha revertido: ` +
        errorBloqueo.message,
    );
  }

  return respuestaJson(200, { clienteId: cuerpo.clienteId, estado: "baja" });
}
