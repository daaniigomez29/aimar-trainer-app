import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/enrutador.dart';
import 'package:aimar_trainer_app/core/presentacion/tema.dart';

class AppAimarTrainer extends ConsumerWidget {
  const AppAimarTrainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrutador = ref.watch(enrutadorProvider);
    return MaterialApp.router(
      title: 'Aimar Trainer',
      theme: TemaApp.claro(),
      routerConfig: enrutador,
      debugShowCheckedModeBanner: false,
    );
  }
}
