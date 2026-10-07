// Especificador COMPLETO, con `npm:` y version, a proposito.
//
// NO vale el nombre a secas con un import map en `deno.json`: al desplegar,
// `supabase functions deploy --use-api` sube solo los `.ts` de la funcion y
// empaqueta en el servidor, donde ese fichero no existe. El bundler se queda sin
// forma de resolver "@supabase/supabase-js" y el despliegue falla con 400
// ("Relative import path not prefixed with / or ./ or ../"), mientras que en
// local y en `deno check` funciona porque ahi si se le pasa la configuracion.
import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.117.2";

/** Roles autorizados a dar de alta y de baja clientes (docs/architecture.md). */
export const ROLES_GESTORES = ["entrenador", "administrador"] as const;

export type RolUsuario = "administrador" | "entrenador" | "cliente";

export interface Autorizacion {
  /** Cliente que actúa con el JWT de quien llama (sujeto a RLS). */
  readonly supabaseDelLlamante: SupabaseClient;
  readonly idUsuario: string;
  readonly rol: RolUsuario;
}

/**
 * Comprueba el JWT de la petición y el rol en `perfiles`.
 *
 * La comprobación vive aquí y no solo en RLS porque crear un usuario en Auth
 * exige `service_role`: sin esta verificación, cualquiera con la URL del
 * endpoint podría crear o dar de baja cuentas.
 *
 * Devuelve la autorización, o una `Response` (401/403) ya lista para devolver.
 */
export async function autorizarGestorDeClientes(
  req: Request,
): Promise<Autorizacion | Response> {
  const cabeceraAuth = req.headers.get("Authorization");
  if (!cabeceraAuth) {
    return respuestaError(
      401,
      "no_autorizado",
      "Falta la cabecera Authorization.",
    );
  }

  const supabaseDelLlamante = createClient(
    Deno.env.get("SUPABASE_URL")!,
    clavePublicaDelProyecto(),
    { global: { headers: { Authorization: cabeceraAuth } } },
  );

  const { data: { user }, error: errorAuth } = await supabaseDelLlamante.auth
    .getUser();
  if (errorAuth || !user) {
    return respuestaError(401, "no_autorizado", "El token no es válido.");
  }

  const { data: perfil } = await supabaseDelLlamante
    .from("perfiles")
    .select("rol")
    .eq("id", user.id)
    .maybeSingle();

  const rol = perfil?.rol as RolUsuario | undefined;
  if (!rol || !ROLES_GESTORES.includes(rol as "entrenador" | "administrador")) {
    return respuestaError(
      403,
      "prohibido",
      "Solo el entrenador o el administrador pueden realizar esta operación.",
    );
  }

  return { supabaseDelLlamante, idUsuario: user.id, rol };
}

/**
 * Clave pública del proyecto para el cliente del llamante.
 *
 * OJO al renombrar: el runtime de Edge Functions NO inyecta
 * `SUPABASE_PUBLISHABLE_KEY` en singular. Inyecta dos variables distintas, con
 * dos claves de valor distinto, ambas válidas para identificar el proyecto:
 *
 *   - `SUPABASE_PUBLISHABLE_KEYS`: JSON `{"default":"sb_publishable_..."}`, el
 *     formato actual. Es la que se prefiere.
 *   - `SUPABASE_ANON_KEY`: la clave heredada, que es un JWT (`eyJ...`), NO la
 *     publicable. Solo se usa si la anterior no estuviera disponible.
 *
 * Los dos nombres los fija Supabase, no son elección de este proyecto:
 * cambiarlos por `SUPABASE_PUBLISHABLE_KEY` deja la clave en `undefined`.
 *
 * Solo identifica el proyecto: quien autentica la petición es el JWT del
 * usuario que viaja en `Authorization`.
 */
export function clavePublicaDelProyecto(): string {
  const publicables = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (publicables) {
    try {
      const porNombre = JSON.parse(publicables) as Record<string, string>;
      const clave = porNombre.default ?? Object.values(porNombre)[0];
      if (clave) return clave;
    } catch {
      // Formato inesperado: se usa la clave heredada.
    }
  }
  return Deno.env.get("SUPABASE_ANON_KEY")!;
}

/**
 * Cliente con `service_role`. Salta RLS, así que solo debe crearse DESPUÉS de
 * que `autorizarGestorDeClientes` haya devuelto una autorización válida.
 */
export function clienteAdministrativo(): SupabaseClient {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );
}

export function respuestaJson(estado: number, cuerpo: unknown): Response {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: { "Content-Type": "application/json" },
  });
}

export function respuestaError(
  estado: number,
  codigo: string,
  mensaje: string,
): Response {
  return respuestaJson(estado, { error: codigo, mensaje });
}

/** Orígenes a los que se responde, de `APP_BASE_URL` separados por comas.
 *
 * Admite varios porque la aplicación vive en más de un sitio: el dominio de
 * Vercel y el propio cuando lo haya. Vacío = `*`, que es lo que hace falta en
 * local, donde el puerto cambia.
 */
function origenesPermitidos(): string[] {
  return (Deno.env.get("APP_BASE_URL") ?? "")
    .split(",")
    .map((o) => o.trim().replace(/\/$/, ""))
    .filter((o) => o.length > 0);
}

/** La URL de la app, para los enlaces de los correos.
 *
 * `APP_BASE_URL` puede traer varios orígenes separados por comas (ver
 * [cabecerasCorsPara]); un enlace solo puede apuntar a uno, así que se usa el
 * primero. Sin ella, cadena vacía: quien la use decide qué hacer.
 */
export function urlBaseApp(): string {
  return origenesPermitidos()[0] ?? "";
}

/** Cabeceras CORS para **esta** petición.
 *
 * `Access-Control-Allow-Origin` solo admite un valor, nunca una lista: con
 * varios orígenes configurados hay que mirar el `Origin` que llega y devolver
 * ese. De ahí el `Vary: Origin`, o una caché intermedia serviría a un dominio la
 * respuesta del otro.
 */
export function cabecerasCorsPara(req: Request): Record<string, string> {
  const permitidos = origenesPermitidos();
  const origen = (req.headers.get("Origin") ?? "").replace(/\/$/, "");
  const devolver = permitidos.length === 0
    ? "*"
    : permitidos.includes(origen)
    ? origen
    // Un origen desconocido recibe el primero configurado, que no coincidirá
    // con el suyo: el navegador bloquea la respuesta, que es lo que se busca.
    : permitidos[0];

  return {
    "Access-Control-Allow-Origin": devolver,
    "Vary": "Origin",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Max-Age": "86400",
  };
}

/** Atiende la petición y le pone el CORS que le toca.
 *
 * POR QUE UN ENVOLTORIO: el origen permitido depende de cada petición, y las
 * respuestas se construyen en treinta sitios distintos. Resolverlo aquí deja un
 * único punto donde pensar en CORS, en vez de pasar el `Request` a cada helper.
 */
export async function servirConCors(
  req: Request,
  manejador: () => Promise<Response> | Response,
): Promise<Response> {
  const cors = cabecerasCorsPara(req);

  // El preflight lo manda el navegador sin credenciales y espera un 2xx.
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }

  const respuesta = await manejador();
  const cabeceras = new Headers(respuesta.headers);
  for (const [clave, valor] of Object.entries(cors)) {
    cabeceras.set(clave, valor);
  }
  return new Response(respuesta.body, {
    status: respuesta.status,
    statusText: respuesta.statusText,
    headers: cabeceras,
  });
}
