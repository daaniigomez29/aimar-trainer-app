import 'package:flutter/material.dart';

/// Pantalla de espera mientras se resuelve la sesion persistida.
class PantallaCargando extends StatelessWidget {
  const PantallaCargando({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
