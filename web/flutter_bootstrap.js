{{flutter_js}}
{{flutter_build_config}}

// POR QUE ESTA PLANTILLA (2026-10-19): los assets se piden bajo una ruta con la
// version del despliegue, `/v/<version>/assets/...`, y Vercel la reescribe a
// `/assets/...` (ver `vercel.json`).
//
// Flutter recorta la fuente de iconos en cada build y deja solo los que usa la
// app, pero el archivo se llama siempre `assets/fonts/MaterialIcons-Regular.otf`.
// Con `/assets/` cacheado un ano e inmutable, el navegador se quedaba con la
// fuente de su primera visita y los iconos nuevos salian en blanco. Con la
// version en la URL, cada despliegue son URLs nuevas que el navegador tiene que
// pedir, y el `immutable` pasa a ser verdad.
//
// `scripts/vercel_build.sh` sustituye el marcador tras compilar. Sin sustituir
// (`flutter run`, o un build a mano) no hay rewrite que lo atienda, asi que se
// cargan los assets de siempre. La comparacion se escribe partida para que la
// sustitucion no la toque.
const versionAssets = "__AIMAR_VERSION_ASSETS__";
const sinVersion = versionAssets === "__AIMAR_" + "VERSION_ASSETS__";

_flutter.loader.load({
  config: sinVersion ? {} : { assetBase: `/v/${versionAssets}/` },
});
