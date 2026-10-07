-- Realtime sobre los plannings, para que el cliente vea los cambios del
-- entrenador sin tener que recargar.
--
-- POR QUE: el cliente tenia la lista cacheada en la app. Si el entrenador
-- borraba un planning, el seguia viendolo hasta cambiar de pestana o pulsar el
-- boton de recargar. Eso es trabajo que no le toca hacer a el.
--
-- Solo esta tabla: lo que aparece y desaparece de la vista del cliente es el
-- planning. Para los cambios de dentro (sesiones, bloques, ejercicios) la app
-- vuelve a pedir los datos al recuperar el foco, que no necesita base de datos.

-- `replica identity full` NO es opcional aqui, aunque parezca que sobra.
--
-- Por defecto, el WAL de un DELETE solo lleva la clave primaria. Realtime
-- necesita la fila **antigua** completa para dos cosas: evaluar el filtro de la
-- suscripcion (`cliente_id=eq.<id>`) y comprobar la RLS del que escucha. Sin
-- esto, el borrado —que es justo el caso del fallo— no le llegaria a nadie.
alter table public.plannings_semanales replica identity full;

alter publication supabase_realtime add table public.plannings_semanales;
