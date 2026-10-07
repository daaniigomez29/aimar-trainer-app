/**
 * Envío de notificaciones push web (CU-22).
 *
 * Web Push estándar con VAPID, sin proveedor de terceros: el navegador del
 * cliente nos da un `endpoint` y dos claves al suscribirse, y con la clave
 * privada VAPID se firma y se cifra el mensaje para ese endpoint. `web-push`
 * pone la criptografía (JWT ES256 para VAPID y aes128gcm para el payload).
 *
 * Igual que el correo, estas funciones **nunca lanzan**: un push que no sale no
 * puede tumbar el aviso de los demás clientes ni el correo, que es el respaldo.
 */
// Especificador completo, por el mismo motivo que en `autorizacion.ts`: el
// import map no viaja al empaquetador del servidor.
import webpush from "npm:web-push@3.6.7";

export interface SuscripcionPush {
  readonly id: string;
  readonly endpoint: string;
  readonly claveP256dh: string;
  readonly claveAuth: string;
}

export interface ResultadoPush {
  readonly enviado: boolean;
  readonly motivo?: string;
  /**
   * `true` si el servicio de push dice que esta suscripción ya no existe (404 o
   * 410). Hay que borrarla: si no, se reintenta cada día para siempre.
   */
  readonly suscripcionCaducada?: boolean;
}

/** `true` si hay claves VAPID configuradas en este entorno. */
export function pushConfigurado(): boolean {
  return Boolean(
    Deno.env.get("VAPID_PUBLIC_KEY") && Deno.env.get("VAPID_PRIVATE_KEY"),
  );
}

export interface ContenidoPush {
  readonly titulo: string;
  readonly cuerpo: string;
  /** Ruta de la app a la que lleva el click en la notificación. */
  readonly ruta: string;
}

export async function enviarPush(
  suscripcion: SuscripcionPush,
  contenido: ContenidoPush,
): Promise<ResultadoPush> {
  const publica = Deno.env.get("VAPID_PUBLIC_KEY");
  const privada = Deno.env.get("VAPID_PRIVATE_KEY");
  if (!publica || !privada) {
    return {
      enviado: false,
      motivo: "Faltan VAPID_PUBLIC_KEY o VAPID_PRIVATE_KEY.",
    };
  }

  // El `mailto:` es obligatorio en VAPID: es el contacto al que el servicio de
  // push escribiría si algo fuera mal con nuestros envíos.
  const contacto = Deno.env.get("VAPID_SUBJECT") ??
    "mailto:no-reply@aimar.local";

  try {
    await webpush.sendNotification(
      {
        endpoint: suscripcion.endpoint,
        keys: { p256dh: suscripcion.claveP256dh, auth: suscripcion.claveAuth },
      },
      JSON.stringify(contenido),
      {
        vapidDetails: {
          subject: contacto,
          publicKey: publica,
          privateKey: privada,
        },
        TTL: 60 * 60 * 12,
      },
    );
    return { enviado: true };
  } catch (error) {
    const estado = (error as { statusCode?: number }).statusCode;
    if (estado === 404 || estado === 410) {
      return {
        enviado: false,
        motivo: `La suscripción ya no es válida (${estado}).`,
        suscripcionCaducada: true,
      };
    }
    return {
      enviado: false,
      motivo: `El servicio de push falló: ${estado ?? ""} ${
        String(error).slice(0, 160)
      }`.trim(),
    };
  }
}
