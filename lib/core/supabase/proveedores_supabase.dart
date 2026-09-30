import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/configuracion/configuracion_app.dart';

part 'proveedores_supabase.g.dart';

/// Configuracion de compilacion. Se sobreescribe en tests con un override.
@Riverpod(keepAlive: true)
ConfiguracionApp configuracionApp(Ref ref) => ConfiguracionApp.desdeEntorno();

/// Cliente de Supabase ya inicializado en `main()`.
///
/// Unico punto de acceso: ningun archivo fuera de un repositorio en `data/`
/// debe usar `Supabase.instance` directamente.
@Riverpod(keepAlive: true)
SupabaseClient clienteSupabase(Ref ref) => Supabase.instance.client;
