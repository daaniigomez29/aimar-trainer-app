// Service worker del push web (CU-22).
//
// POR QUE UNO PROPIO Y NO EL DE FLUTTER: `flutter_service_worker.js` lo genera el
// build en cada compilacion, asi que no se le puede anadir codigo. Este se
// registra en el ambito `/push/`, distinto del `/` que usa el de Flutter, para que
// convivan: un ambito solo admite un service worker. Para recibir push y mostrar
// notificaciones el ambito da igual.

self.addEventListener("push", (evento) => {
  const porDefecto = {
    titulo: "Aimar Trainer",
    cuerpo: "Tienes un aviso nuevo.",
    ruta: "/",
  };

  let datos = porDefecto;
  try {
    // El payload lo cifra la Edge Function; si viniera vacio o con otra forma,
    // mejor una notificacion generica que ninguna.
    datos = { ...porDefecto, ...(evento.data ? evento.data.json() : {}) };
  } catch (_) {
    // Se queda con los valores por defecto.
  }

  evento.waitUntil(
    self.registration.showNotification(datos.titulo, {
      body: datos.cuerpo,
      icon: "icons/Icon-192.png",
      badge: "icons/Icon-192.png",
      // Dos avisos de lo mismo se reemplazan en vez de apilarse.
      tag: datos.ruta,
      data: { ruta: datos.ruta },
    }),
  );
});

self.addEventListener("notificationclick", (evento) => {
  evento.notification.close();

  const ruta = (evento.notification.data && evento.notification.data.ruta) || "/";
  // La app usa la estrategia de URL con almohadilla, que es la de Flutter web por
  // defecto: la ruta interna va despues de `#`.
  const destino = new URL(`/#${ruta}`, self.location.origin).href;

  evento.waitUntil(
    (async () => {
      const ventanas = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true,
      });
      // Si la app ya esta abierta se reutiliza esa pestana en lugar de abrir otra.
      for (const ventana of ventanas) {
        if (ventana.url.startsWith(self.location.origin)) {
          await ventana.focus();
          if ("navigate" in ventana) return ventana.navigate(destino);
          return;
        }
      }
      return self.clients.openWindow(destino);
    })(),
  );
});
