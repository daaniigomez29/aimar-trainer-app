import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/theme/tema_app.dart';

class AppAimarTrainer extends ConsumerWidget {
  const AppAimarTrainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrutador = ref.watch(enrutadorProvider);
    return MaterialApp.router(
      title: 'Aimar Trainer',
      // Un unico tema oscuro para los dos roles, por decision del diseno
      // (docs/ui-design.md, seccion 1): no se elige por preferencia del sistema.
      theme: TemaApp.oscuro(),
      themeMode: ThemeMode.dark,
      routerConfig: enrutador,
      debugShowCheckedModeBanner: false,
    );
  }
}
