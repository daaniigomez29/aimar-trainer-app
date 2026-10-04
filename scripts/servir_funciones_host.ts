// Arranca las tres Edge Functions FUERA de Docker, con Deno del host.
//
// POR QUE: `supabase functions serve` no puede crear su contenedor con Docker
// 29.x ("failed to copy edge runtime main service into container"). Esto es solo
// un andamio de verificacion local; no forma parte del proyecto.
//
// Cada index.ts llama a `Deno.serve` al importarse, asi que se intercepta para
// quedarse con el manejador en vez de abrir tres puertos.

type Manejador = (req: Request) => Response | Promise<Response>;

const manejadores: Record<string, Manejador> = {};
let enCurso = "";
const serveOriginal = Deno.serve;

// deno-lint-ignore no-explicit-any
(Deno as any).serve = (a: unknown, b?: unknown) => {
  manejadores[enCurso] = (typeof a === "function" ? a : b) as Manejador;
  return {
    finished: Promise.resolve(),
    shutdown: () => Promise.resolve(),
    ref() {},
    unref() {},
    addr: { transport: "tcp", hostname: "127.0.0.1", port: 0 },
    // deno-lint-ignore no-explicit-any
  } as any;
};

const raiz = Deno.env.get("RAIZ_FUNCIONES")!;
for (
  const nombre of [
    "crear-cliente",
    "dar-de-baja-cliente",
    "enviar-recordatorios",
  ]
) {
  enCurso = nombre;
  await import(`${raiz}/${nombre}/index.ts`);
}

// deno-lint-ignore no-explicit-any
(Deno as any).serve = serveOriginal;

const puerto = Number(Deno.env.get("PUERTO_FUNCIONES") ?? "54331");
Deno.serve({ port: puerto }, (req) => {
  const ruta = new URL(req.url).pathname.match(/^\/functions\/v1\/([^/]+)/);
  const manejador = ruta ? manejadores[ruta[1]] : undefined;
  if (!manejador) return new Response("funcion desconocida", { status: 404 });
  return manejador(req);
});
