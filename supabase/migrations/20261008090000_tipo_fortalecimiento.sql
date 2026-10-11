-- Tercer tipo de ejercicio: Fortalecimiento, para el trabajo con clientes
-- lesionados. Se planifica **con series**, igual que Fuerza: en
-- `series_planificadas` las repeticiones son obligatorias pero el peso y el RIR
-- son nulables, que es justo lo que pide el trabajo con peso corporal o goma.
--
-- Va en una migracion propia a proposito: `alter type ... add value` no puede
-- convivir en la misma transaccion con sentencias que usen el valor nuevo, y la
-- migracion siguiente lo nombra dentro de `planifica_con_minutos`.

alter type tipo_ejercicio add value if not exists 'fortalecimiento';
