// CU-18 / RF-18 · Dar de baja cliente (baja SIEMPRE lógica).
//
// FASE 1: solo el esqueleto y la validación de rol. La baja real (update de
// `clientes` y bloqueo en Auth) llega en la fase 3.
//
// Contrato completo en docs/architecture.md ("Contrato de las Edge Functions").

import {
  autorizarGestorDeClientes,
  respuestaError,
  respuestaJson,
  respuestaPreflight,
} from "../_shared/autorizacion.ts";

interface PeticionDarDeBaja {
  clienteId: string;
}

const FORMATO_UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req) => {
  const preflight = respuestaPreflight(req);
  if (preflight) return preflight;

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

  // TODO(fase 3), con `clienteAdministrativo()`:
  //   1. 404 si el cliente no existe; 409 si ya estaba de baja
  //   2. update clientes set estado = 'baja', fecha_baja = now() where id = ...
  //      (NUNCA delete: la baja es lógica y el histórico se conserva)
  //   3. auth.admin.updateUserById(clienteId, { ban_duration: "876000h" })
  // Respuesta prevista: 200 { clienteId, estado: "baja" }
  return respuestaJson(501, {
    error: "no_implementado",
    mensaje: "La baja de clientes se implementa en la fase 3.",
    rolDelLlamante: autorizacion.rol,
  });
});
