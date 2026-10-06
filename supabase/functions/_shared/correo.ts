/**
 * Envío de correo vía Resend.
 *
 * El alta de un cliente NO debe fallar porque el correo no salga: la ficha ya
 * está creada y la invitación se puede reenviar. Por eso estas funciones nunca
 * lanzan; devuelven si se envió y, si no, por qué.
 */
export interface ResultadoEnvio {
  readonly enviado: boolean;
  /** Motivo por el que no se envió, para devolverlo al cliente de la API. */
  readonly motivo?: string;
  /** `true` si se entregó en el buzón de pruebas local, no por Resend. */
  readonly entregadoEnLocal?: boolean;
}

const URL_RESEND = "https://api.resend.com/emails";

/** `true` si Resend está configurado en este entorno. */
export function correoConfigurado(): boolean {
  return Boolean(
    Deno.env.get("RESEND_API_KEY") && Deno.env.get("RESEND_FROM_EMAIL"),
  );
}

export async function enviarCorreo({
  destinatario,
  asunto,
  html,
  texto,
}: {
  destinatario: string;
  asunto: string;
  html: string;
  texto: string;
}): Promise<ResultadoEnvio> {
  const clave = Deno.env.get("RESEND_API_KEY");
  const remitente = Deno.env.get("RESEND_FROM_EMAIL");

  // Sin Resend configurado, en local se entrega a Mailpit (el buzón de pruebas
  // que ya trae `supabase start`). Así el flujo de invitación se puede probar de
  // punta a punta sin dominio verificado.
  if (!clave || !remitente) {
    const urlDesarrollo = Deno.env.get("CORREO_DEV_URL");
    if (urlDesarrollo) {
      return await _entregarEnMailpit({
        url: urlDesarrollo,
        remitente: remitente ?? "invitaciones@aimar.local",
        destinatario,
        asunto,
        html,
        texto,
      });
    }
    return {
      enviado: false,
      motivo:
        "Resend no está configurado (faltan RESEND_API_KEY o RESEND_FROM_EMAIL) " +
        "y tampoco hay CORREO_DEV_URL para entregar en local.",
    };
  }

  try {
    const respuesta = await fetch(URL_RESEND, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${clave}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: remitente,
        to: [destinatario],
        subject: asunto,
        html,
        text: texto,
      }),
    });

    if (!respuesta.ok) {
      const detalle = await respuesta.text();
      return {
        enviado: false,
        motivo: `Resend respondió ${respuesta.status}: ${
          detalle.slice(0, 200)
        }`,
      };
    }
    return { enviado: true };
  } catch (error) {
    return {
      enviado: false,
      motivo: `No se pudo contactar con Resend: ${error}`,
    };
  }
}

/**
 * Entrega el correo en Mailpit usando su API de inyección.
 *
 * Solo para desarrollo: Mailpit no envía nada a internet, solo guarda el mensaje
 * para poder verlo en su interfaz web. `CORREO_DEV_URL` apunta a su API, que
 * desde el runtime de las Edge Functions es
 * `http://supabase_inbucket_<proyecto>:8025`, porque ambos contenedores comparten
 * la red de Docker.
 */
async function _entregarEnMailpit({
  url,
  remitente,
  destinatario,
  asunto,
  html,
  texto,
}: {
  url: string;
  remitente: string;
  destinatario: string;
  asunto: string;
  html: string;
  texto: string;
}): Promise<ResultadoEnvio> {
  try {
    const respuesta = await fetch(`${url.replace(/\/$/, "")}/api/v1/send`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        From: { Email: remitente },
        To: [{ Email: destinatario }],
        Subject: asunto,
        HTML: html,
        Text: texto,
      }),
    });
    if (!respuesta.ok) {
      const detalle = await respuesta.text();
      return {
        enviado: false,
        motivo: `Mailpit respondió ${respuesta.status}: ${
          detalle.slice(0, 200)
        }`,
      };
    }
    return { enviado: true, entregadoEnLocal: true };
  } catch (error) {
    return {
      enviado: false,
      motivo: `No se pudo contactar con Mailpit: ${error}`,
    };
  }
}

/** Cuerpo del correo de invitación (CU-17, paso 6). */
export function correoDeInvitacion({
  nombre,
  enlace,
}: {
  nombre: string;
  enlace: string;
}): { asunto: string; html: string; texto: string } {
  const asunto = "Tu acceso a Aimar Trainer";
  const texto = [
    `Hola ${nombre}:`,
    "",
    "Tu entrenador te ha dado de alta en Aimar Trainer. Para entrar por primera",
    "vez y elegir tu contraseña, abre este enlace:",
    "",
    enlace,
    "",
    "Si no esperabas este correo, puedes ignorarlo.",
  ].join("\n");

  const html = `<!doctype html>
<html lang="es">
  <body style="font-family: system-ui, sans-serif; line-height: 1.5; color: #1b1b1b;">
    <p>Hola ${escaparHtml(nombre)}:</p>
    <p>
      Tu entrenador te ha dado de alta en <strong>Aimar Trainer</strong>. Para
      entrar por primera vez y elegir tu contraseña, pulsa el botón:
    </p>
    <p>
      <a
        href="${escaparHtml(enlace)}"
        style="display: inline-block; padding: 12px 20px; background: #1b5e20; color: #ffffff; border-radius: 6px; text-decoration: none;"
      >Activar mi cuenta</a>
    </p>
    <p style="font-size: 13px; color: #555555;">
      Si el botón no funciona, copia este enlace en tu navegador:<br />
      ${escaparHtml(enlace)}
    </p>
    <p style="font-size: 13px; color: #555555;">
      Si no esperabas este correo, puedes ignorarlo.
    </p>
  </body>
</html>`;

  return { asunto, html, texto };
}

/** Aviso de que empieza una semana nueva de entrenamiento (CU-22).
 *
 * Sustituye al "manana toca X": las sesiones ya no tienen fecha planificada, se
 * numeran dentro de la semana y el cliente las hace cuando puede.
 */
export function correoDeSemanaNueva({
  nombre,
  sesiones,
  enlace,
}: {
  nombre: string;
  sesiones: number;
  enlace: string;
}): { asunto: string; html: string; texto: string } {
  const cuantas = sesiones === 1 ? "1 sesión" : `${sesiones} sesiones`;
  const asunto = "Tu nueva semana de entrenamiento";
  const texto = [
    `Hola ${nombre}:`,
    "",
    `Tu entrenador te ha preparado ${cuantas} para esta semana.`,
    "Hazlas en el orden que marcan, los días que mejor te vengan.",
    "",
    enlace,
  ].join("\n");

  const html = _plantilla({
    saludo: `Hola ${escaparHtml(nombre)}:`,
    cuerpo:
      `<p>Tu entrenador te ha preparado <strong>${cuantas}</strong> para esta ` +
      "semana. Hazlas en el orden que marcan, los días que mejor te vengan.</p>",
    textoBoton: "Ver mi semana",
    enlace,
  });

  return { asunto, html, texto };
}

/** Recordatorio del dia de control: medidas y check-in (CU-22). */
export function correoDeControlSemanal({
  nombre,
  enlace,
}: {
  nombre: string;
  enlace: string;
}): { asunto: string; html: string; texto: string } {
  const asunto = "Hoy toca control semanal";
  const texto = [
    `Hola ${nombre}:`,
    "",
    "Hoy es tu día de control: anota tus medidas y rellena el check-in de",
    "recuperación para que tu entrenador vea cómo ha ido la semana.",
    "",
    enlace,
  ].join("\n");

  const html = _plantilla({
    saludo: `Hola ${escaparHtml(nombre)}:`,
    cuerpo:
      "<p>Hoy es tu <strong>día de control</strong>: anota tus medidas y " +
      "rellena el check-in de recuperación para que tu entrenador vea cómo ha " +
      "ido la semana.</p>",
    textoBoton: "Abrir mi control",
    enlace,
  });

  return { asunto, html, texto };
}

/** Cuerpo HTML comun de los recordatorios, para no repetir los estilos. */
function _plantilla({
  saludo,
  cuerpo,
  textoBoton,
  enlace,
}: {
  saludo: string;
  cuerpo: string;
  textoBoton: string;
  enlace: string;
}): string {
  return `<!doctype html>
<html lang="es">
  <body style="font-family: system-ui, sans-serif; line-height: 1.5; color: #1b1b1b;">
    <p>${saludo}</p>
    ${cuerpo}
    <p>
      <a
        href="${escaparHtml(enlace)}"
        style="display: inline-block; padding: 12px 20px; background: #1b5e20; color: #ffffff; border-radius: 6px; text-decoration: none;"
      >${escaparHtml(textoBoton)}</a>
    </p>
    <p style="font-size: 13px; color: #555555;">
      Recibes este aviso porque tienes un planning activo en Aimar Trainer.
    </p>
  </body>
</html>`;
}

/** El nombre lo escribe el entrenador: se escapa antes de meterlo en el HTML. */
function escaparHtml(valor: string): string {
  return valor
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}
