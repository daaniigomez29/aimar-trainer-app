// CU-17 / RF-17 · Dar de alta cliente.
//
// FASE 1: solo el esqueleto y la validación de rol. La creación real (usuario en
// Auth, perfil, ficha en `clientes` e invitación por Resend) llega en la fase 3,
// junto con la feature de gestión de clientes.
//
// Contrato completo en docs/architecture.md ("Contrato de las Edge Functions").

import {
  autorizarGestorDeClientes,
  respuestaError,
  respuestaJson,
  respuestaPreflight,
} from "../_shared/autorizacion.ts";

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

  // TODO(fase 3), con `clienteAdministrativo()`:
  //   1. auth.admin.inviteUserByEmail(correo) -> id del nuevo usuario
  //   2. insert into perfiles (id, rol = 'cliente')
  //   3. insert into clientes (...datos recibidos)
  //   4. correo de invitación vía Resend (RESEND_API_KEY, RESEND_FROM_EMAIL)
  //   5. 409 si ya existe un cliente activo con ese correo
  //      (índice clientes_correo_activo_unico)
  // Respuesta prevista: 201 { clienteId, estado: "invitado" }
  return respuestaJson(501, {
    error: "no_implementado",
    mensaje: "El alta de clientes se implementa en la fase 3.",
    rolDelLlamante: autorizacion.rol,
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
